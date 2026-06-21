-- gpg-decrypt.yazi/main.lua
-- Decrypts the hovered GPG file back to plaintext and replaces the .gpg.
-- Reverse of gpg-encrypt (c e). Classification follows encrypt's naming:
--   <name>.tar.gz.gpg -> folder (decrypt + untar -> <name>/)
--   <name>.gpg        -> file    (decrypt -> <name>)
-- Trigger: c d (see keymap.toml). Decryption prompts for the private-key
-- passphrase via pinentry-mac; a y/n confirm precedes it.

local function notify(content, level)
    ya.notify({ title = "GPG decrypt", content = content, level = level or "info", timeout = 5 })
end

-- Read the hovered node from the UI thread.
local hovered = ya.sync(function()
    local h = cx.active.current.hovered
    if not h then
        return nil
    end
    return {
        url = tostring(h.url),
        name = tostring(h.url.name),
        parent = tostring(h.url.parent),
        is_dir = h.cha.is_dir,
    }
end)

-- Best-effort non-empty check via standard io (portable across Yazi versions).
local function file_nonempty(path)
    local f = io.open(path, "rb")
    if not f then
        return false
    end
    local ok, size = pcall(function()
        return f:seek("end")
    end)
    f:close()
    return ok and size and size > 0
end

-- Run a command to completion, capturing stderr for diagnostics.
-- Returns (success_bool, stderr_string).
local function run(cmd, args)
    local out, err = Command(cmd):arg(args):stderr(Command.PIPED):output()
    if not out then
        return false, tostring(err)
    end
    if not out.status.success then
        return false, out.stderr or ""
    end
    return true, ""
end

local function do_decrypt()
    ya.emit("escape", { visual = true })

    local item = hovered()
    if not item then
        notify("No file under cursor", "warn")
        return
    end

    -- Classify by the suffix the encrypt command produces.
    local kind, base
    if item.url:match("%.tar%.gz%.gpg$") then
        kind = "folder"
        base = item.url:gsub("%.tar%.gz%.gpg$", "")
    elseif item.url:match("%.gpg$") then
        kind = "file"
        base = item.url:gsub("%.gpg$", "")
    else
        notify(string.format("'%s' is not a GPG file (.gpg)", item.name), "warn")
        return
    end

    local answer, event = ya.input({
        title = string.format("Type y to decrypt & replace '%s' (Esc to cancel):", item.name),
        pos = { "top-center", y = 3, w = 60 },
    })
    if event ~= 1 or not answer:match("^%s*[yY]") then
        return
    end

    local output
    if kind == "folder" then
        -- Decrypt to a collision-safe temp archive, then extract into the parent.
        local tmp = tostring(fs.unique_name(Url(base .. ".dec.tmp.tar.gz")))
        local ok, e = run("gpg", { "--batch", "--yes", "--output", tmp, "--decrypt", item.url })
        if not ok then
            notify(string.format("gpg failed: %s", e), "error")
            os.remove(tmp)
            return
        end
        ok, e = run("tar", { "-xzf", tmp, "-C", item.parent })
        os.remove(tmp) -- always clean the temp
        if not ok then
            notify(string.format("tar extract failed: %s", e), "error")
            return
        end
        output = base -- the extracted folder path
    else
        -- File: decrypt to <name> without the .gpg suffix.
        output = base
        local ok, e = run("gpg", { "--batch", "--yes", "--output", output, "--decrypt", item.url })
        if not ok then
            notify(string.format("gpg failed: %s", e), "error")
            return
        end
        if not file_nonempty(output) then
            notify(string.format("Decryption produced no output for '%s'", item.name), "error")
            return
        end
    end

    -- Replace the original .gpg (always a file).
    local removed, rerr = os.remove(item.url)
    if not removed then
        notify(string.format("Decrypted OK but failed to remove .gpg: %s", rerr or "?"), "warn")
        return
    end

    notify(string.format("Decrypted '%s' -> %s", item.name, output), "info")
end

return {
    entry = function(_, job)
        -- Surface any runtime error as a notification instead of silently aborting.
        local ok, err = pcall(do_decrypt)
        if not ok then
            notify("GPG decrypt error: " .. tostring(err), "error")
        end
    end,
}
