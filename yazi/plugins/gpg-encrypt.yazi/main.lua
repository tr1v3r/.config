-- gpg-encrypt.yazi/main.lua
-- Encrypt the hovered file/folder with GPG (asymmetric, to your own key),
-- then replace the original. Folder -> tar.gz, then .tar.gz.gpg.
-- Trigger: c e (see keymap.toml). Type "y" to confirm the destructive replace.

local RECIPIENT = "0xE4AF5FF89222F261" -- your personal key (tr1v3r); gpg picks the encryption subkey

local function notify(content, level)
    ya.notify({ title = "GPG encrypt", content = content, level = level or "info", timeout = 5 })
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

local function do_encrypt()
    ya.emit("escape", { visual = true })

    local item = hovered()
    if not item then
        notify("No file under cursor", "warn")
        return
    end

    -- NOTE: use `pos`, not `position` — `position` was deprecated in Yazi 26.x
    -- (ya.input now expects a `ui.Pos` via the `pos` field).
    local answer, event = ya.input({
        title = string.format("Type y to encrypt & replace '%s' (Esc to cancel):", item.name),
        pos = { "top-center", y = 3, w = 60 },
    })
    if event ~= 1 or not answer:match("^%s*[yY]") then
        return
    end

    local output
    if item.is_dir then
        -- Folder: tar to a collision-safe temp archive, then encrypt it.
        local tmp = tostring(fs.unique_name(Url(item.url .. ".enc.tmp.tar.gz")))
        local ok, e = run("tar", { "-czf", tmp, "-C", item.parent, item.name })
        if not ok then
            notify(string.format("tar failed: %s", e), "error")
            os.remove(tmp)
            return
        end
        output = item.url .. ".tar.gz.gpg"
        ok, e = run("gpg", {
            "--batch",
            "--yes",
            "--encrypt",
            "--recipient",
            RECIPIENT,
            "--output",
            output,
            tmp,
        })
        os.remove(tmp) -- always clean the temp
        if not ok then
            notify(string.format("gpg failed: %s", e), "error")
            return
        end
    else
        -- File: encrypt to <name>.gpg.
        output = item.url .. ".gpg"
        local ok, e = run("gpg", {
            "--batch",
            "--yes",
            "--encrypt",
            "--recipient",
            RECIPIENT,
            "--output",
            output,
            item.url,
        })
        if not ok then
            notify(string.format("gpg failed: %s", e), "error")
            return
        end
    end

    -- Verify a non-empty output before deleting the source.
    if not file_nonempty(output) then
        notify(string.format("Encryption produced no output for '%s'", item.name), "error")
        return
    end

    -- Replace the original.
    local removed, rerr
    if item.is_dir then
        removed, rerr = fs.remove("dir_all", Url(item.url))
    else
        removed, rerr = os.remove(item.url)
    end
    if not removed then
        notify(string.format("Encrypted OK but failed to remove original: %s", rerr or "?"), "warn")
        return
    end

    notify(string.format("Encrypted '%s' -> %s", item.name, output), "info")
end

return {
    entry = function(_, job)
        -- Surface any runtime error as a notification instead of silently aborting.
        local ok, err = pcall(do_encrypt)
        if not ok then
            notify("GPG encrypt error: " .. tostring(err), "error")
        end
    end,
}
