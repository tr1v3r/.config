-- Sign, encrypt, decrypt, and verify files from Yazi.
--
-- Single selection:
--   file      -> <name>.gpg
--   directory -> <name>.tar.gz.gpg
--
-- Multiple selections from one directory:
--   items -> <chosen-name>.tar.gz.gpg
--
-- New archives carry a stable OpenPGP embedded filename so a regular file
-- ending in .tar.gz is not mistaken for an archive during decryption.

local ARCHIVE_MARKER = "yazi-gpg-archive-v1.tar.gz"
local DEFAULT_RECIPIENT = "899318F5A4423B72DF6A166FE4AF5FF89222F261"
local DEFAULT_SIGNER = "C633910E8F351365DEAAF300046263C39890F916"

local function notify(content, level, timeout)
	ya.notify({
		title = "GPG",
		content = content,
		level = level or "info",
		timeout = timeout or 6,
	})
end

local function normalize_fingerprint(value)
	return tostring(value or ""):gsub("%s+", ""):upper()
end

local get_config = ya.sync(function(state)
	return {
		recipient = state.recipient or DEFAULT_RECIPIENT,
		signer = state.signer or DEFAULT_SIGNER,
	}
end)

local selected_or_hovered = ya.sync(function()
	local tab = cx.active
	local targets = {}

	for _, url in pairs(tab.selected) do
		targets[#targets + 1] = {
			path = tostring(url),
			parent = tostring(url.parent),
			name = tostring(url.name),
			is_local = url.is_regular,
		}
	end

	if #targets == 0 and tab.current.hovered then
		local hovered = tab.current.hovered
		targets[1] = {
			path = tostring(hovered.url),
			parent = tostring(hovered.url.parent),
			name = tostring(hovered.url.name),
			is_local = hovered.url.is_regular,
		}
	end

	return targets
end)

local function compact_error(value)
	local text = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if #text > 700 then
		text = text:sub(1, 697) .. "..."
	end
	return text ~= "" and text or "unknown error"
end

local function run(command, args)
	local output, err = Command(command)
		:arg(args)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()

	if not output then
		return false, "", compact_error(err)
	end

	return output.status.success, output.stdout or "", compact_error(output.stderr)
end

local function join(parent, name)
	return tostring(Url(parent):join(name))
end

local function inspect_path(path)
	local cha, err = fs.cha(Url(path), false)
	return cha, err
end

local function path_exists(path)
	local cha = inspect_path(path)
	return cha ~= nil
end

local function nonempty_file(path)
	local cha = inspect_path(path)
	return cha ~= nil and not cha.is_dir and cha.len > 0
end

local function remove_path(path, is_dir)
	if is_dir then
		return fs.remove("dir_all", Url(path))
	end
	return fs.remove("file", Url(path))
end

local function cleanup_dir(path)
	if path and path_exists(path) then
		fs.remove("dir_all", Url(path))
	end
end

local function make_temp_dir(parent)
	local url, err = fs.unique("dir", Url(join(parent, ".yazi-gpg-tmp")))
	if not url then
		return nil, compact_error(err)
	end

	local path = tostring(url)
	local ok, _, chmod_err = run("chmod", { "700", path })
	if not ok then
		cleanup_dir(path)
		return nil, "chmod failed: " .. chmod_err
	end

	return path
end

local function move_noreplace(source, target)
	if path_exists(target) then
		return false, "target already exists: " .. target
	end

	local ok, _, err = run("mv", { "-n", source, target })
	if not ok then
		return false, err
	end

	if path_exists(source) then
		return false, "target appeared while moving: " .. target
	end
	if not path_exists(target) then
		return false, "move completed without creating target: " .. target
	end

	return true
end

local function valid_fingerprint(value)
	return value:match("^[0-9A-F]+$") ~= nil and #value == 40
end

local function validate_config(config)
	config.recipient = normalize_fingerprint(config.recipient)
	config.signer = normalize_fingerprint(config.signer)

	if not valid_fingerprint(config.recipient) then
		return false, "Invalid recipient fingerprint"
	end
	if not valid_fingerprint(config.signer) then
		return false, "Invalid signer fingerprint"
	end

	return true
end

local function has_public_key(fingerprint)
	local ok, stdout = run("gpg", {
		"--batch",
		"--with-colons",
		"--list-keys",
		fingerprint,
	})
	return ok and stdout:find("pub:", 1, true) ~= nil
end

local function has_secret_key(fingerprint)
	local ok, stdout = run("gpg", {
		"--batch",
		"--with-colons",
		"--list-secret-keys",
		fingerprint,
	})
	return ok and (stdout:find("sec:", 1, true) ~= nil or stdout:find("ssb:", 1, true) ~= nil)
end

local function validate_encrypt_keys(config)
	if not has_public_key(config.recipient) then
		return false, "Encryption public key is unavailable:\n" .. config.recipient
	end
	if not has_secret_key(config.signer) then
		return false, "Signing private key or smart-card stub is unavailable:\n" .. config.signer
	end
	return true
end

local function prepare_targets(raw_targets)
	if #raw_targets == 0 then
		return nil, "No file under cursor"
	end

	local targets, seen = {}, {}
	for _, item in ipairs(raw_targets) do
		if not item.is_local then
			return nil, "Remote and virtual URLs are not supported: " .. item.path
		end
		if not seen[item.path] then
			local cha, err = inspect_path(item.path)
			if not cha then
				return nil, string.format("Cannot inspect '%s': %s", item.name, compact_error(err))
			end
			if cha.is_block or cha.is_char or cha.is_fifo or cha.is_sock then
				return nil, "Unsupported special file: " .. item.path
			end

			item.is_dir = cha.is_dir
			item.is_link = cha.is_link
			targets[#targets + 1] = item
			seen[item.path] = true
		end
	end

	table.sort(targets, function(a, b)
		return a.path < b.path
	end)

	return targets
end

local function exact_confirmation(title)
	local answer, event = ya.input({
		title = title,
		pos = { "top-center", y = 3, w = 70 },
	})
	return event == 1 and answer:match("^%s*[yY]%s*$") ~= nil
end

local function valid_archive_name(value)
	return value ~= "" and value ~= "." and value ~= ".." and not value:find("/", 1, true) and not value:find("%z")
end

local function archive_output_name(parent)
	local parent_name = tostring(Url(parent).name or "selection")
	if parent_name == "" or parent_name == "/" then
		parent_name = "selection"
	end
	local default_name = parent_name .. ".tar.gz.gpg"

	local value, event = ya.input({
		title = "Encrypted bundle name (default: " .. default_name .. "):",
		pos = { "top-center", y = 3, w = 72 },
	})
	if event ~= 1 then
		return nil
	end

	value = value:match("^%s*(.-)%s*$")
	if value == "" then
		value = default_name
	elseif not value:lower():match("%.tar%.gz%.gpg$") then
		value = value .. ".tar.gz.gpg"
	end

	if not valid_archive_name(value) then
		return nil, "Invalid archive name"
	end
	return value
end

local function create_archive(output, parent, targets)
	local args = { "-czf", output, "-C", parent, "--" }
	for _, item in ipairs(targets) do
		args[#args + 1] = item.name
	end

	local ok, _, err = run("tar", args)
	if not ok then
		return false, "tar failed: " .. err
	end
	if not nonempty_file(output) then
		return false, "tar succeeded without creating a non-empty archive"
	end
	return true
end

local function sign_encrypt(input, output, embedded_name, config)
	local ok, status, err = run("gpg", {
		"--batch",
		"--no-tty",
		"--no-auto-key-locate",
		"--trust-model",
		"always",
		"--status-fd",
		"1",
		"--local-user",
		config.signer,
		"--recipient",
		config.recipient,
		"--set-filename",
		embedded_name,
		"--output",
		output,
		"--sign",
		"--encrypt",
		"--",
		input,
	})

	if not ok then
		return false, "gpg failed: " .. err
	end
	if not status:find("[GNUPG:] SIG_CREATED", 1, true) then
		return false, "gpg did not report a created signature"
	end
	if not nonempty_file(output) then
		return false, "gpg succeeded without creating non-empty ciphertext"
	end
	return true
end

local function finish_source_removal(targets)
	local failed = {}
	for _, item in ipairs(targets) do
		local ok, err = remove_path(item.path, item.is_dir and not item.is_link)
		if not ok then
			failed[#failed + 1] = string.format("%s (%s)", item.name, compact_error(err))
		end
	end
	return failed
end

local function encrypt(config)
	local targets, target_err = prepare_targets(selected_or_hovered())
	if not targets then
		notify(target_err, "error")
		return
	end

	local ok, key_err = validate_encrypt_keys(config)
	if not ok then
		notify(key_err, "error", 8)
		return
	end

	local parent, output_name, archive_mode
	if #targets > 1 then
		parent = targets[1].parent
		for _, item in ipairs(targets) do
			if item.parent ~= parent then
				notify("Multiple selections must have the same parent directory", "warn")
				return
			end
		end

		output_name, target_err = archive_output_name(parent)
		if not output_name then
			if target_err then
				notify(target_err, "warn")
			end
			return
		end
		archive_mode = true
	else
		local item = targets[1]
		parent = item.parent
		archive_mode = item.is_dir and not item.is_link
		output_name = archive_mode and (item.name .. ".tar.gz.gpg") or (item.name .. ".gpg")
	end

	local final_output = join(parent, output_name)
	if path_exists(final_output) then
		notify("Target already exists:\n" .. final_output, "warn")
		return
	end
	for _, item in ipairs(targets) do
		if item.path == final_output then
			notify("Encrypted output conflicts with a selected source", "warn")
			return
		end
	end

	local confirmation = #targets > 1
		and string.format("Type y to sign, encrypt & replace %d items as '%s':", #targets, output_name)
		or string.format("Type y to sign, encrypt & replace '%s':", targets[1].name)
	if not exact_confirmation(confirmation) then
		return
	end

	local temp_dir, temp_err = make_temp_dir(parent)
	if not temp_dir then
		notify("Failed to create private temp directory: " .. temp_err, "error")
		return
	end

	local success, operation_err = pcall(function()
		local input = targets[1].path
		if archive_mode then
			input = join(temp_dir, ARCHIVE_MARKER)
			local archived, archive_err = create_archive(input, parent, targets)
			if not archived then
				error(archive_err)
			end
		end

		local temp_cipher = join(temp_dir, output_name)
		local encrypted, encrypt_err = sign_encrypt(
			input,
			temp_cipher,
			archive_mode and ARCHIVE_MARKER or targets[1].name,
			config
		)
		if not encrypted then
			error(encrypt_err)
		end

		local moved, move_err = move_noreplace(temp_cipher, final_output)
		if not moved then
			error(move_err)
		end
	end)

	if not success then
		cleanup_dir(temp_dir)
		notify("Encryption stopped; originals were kept.\n" .. compact_error(operation_err), "error", 9)
		return
	end

	local removal_failures = finish_source_removal(targets)
	cleanup_dir(temp_dir)
	ya.emit("escape", { select = true })

	if #removal_failures > 0 then
		notify(
			string.format(
				"Ciphertext created, but %d original(s) could not be removed:\n%s",
				#removal_failures,
				table.concat(removal_failures, "\n")
			),
			"warn",
			10
		)
	else
		notify(string.format("Signed and encrypted %d item(s) -> %s", #targets, final_output), "info", 8)
	end
end

local function status_has(status, token)
	return status:find("[GNUPG:] " .. token, 1, true) ~= nil
end

local function status_has_signature(status)
	for _, token in ipairs({
		"GOODSIG",
		"VALIDSIG",
		"BADSIG",
		"ERRSIG",
		"EXPSIG",
		"EXPKEYSIG",
		"REVKEYSIG",
	}) do
		if status_has(status, token) then
			return true
		end
	end
	return false
end

local function embedded_filename(status)
	for line in status:gmatch("[^\r\n]+") do
		local value = line:match("^%[GNUPG:%] PLAINTEXT %S+ %S+ (.+)$")
		if value then
			return value
		end
	end
	return nil
end

local function decrypt_once(input, output, config, assert_signer)
	local args = {
		"--batch",
		"--no-tty",
		"--no-auto-key-retrieve",
		"--status-fd",
		"1",
	}
	if assert_signer then
		args[#args + 1] = "--assert-signer"
		args[#args + 1] = config.signer
	end
	args[#args + 1] = "--output"
	args[#args + 1] = output
	args[#args + 1] = "--decrypt"
	args[#args + 1] = "--"
	args[#args + 1] = input

	return run("gpg", args)
end

local function decrypt_payload(input, output, config)
	local ok, status, err = decrypt_once(input, output, config, true)
	if
		ok
		and status_has(status, "DECRYPTION_OKAY")
		and status_has(status, "VALIDSIG")
		and path_exists(output)
	then
		return true, status, false
	end

	local unsigned_legacy = status_has(status, "DECRYPTION_OKAY") and not status_has_signature(status)
	if not unsigned_legacy then
		if path_exists(output) then
			fs.remove("file", Url(output))
		end
		local message = status_has(status, "DECRYPTION_OKAY") and "Signature verification failed: "
			or "Decryption failed: "
		return false, nil, false, message .. err
	end

	if path_exists(output) then
		fs.remove("file", Url(output))
	end
	local answer, event = ya.input({
		title = "Unsigned legacy GPG file. Type legacy to decrypt:",
		pos = { "top-center", y = 3, w = 68 },
	})
	if event ~= 1 or answer:match("^%s*(.-)%s*$"):lower() ~= "legacy" then
		return false, nil, true, "Legacy decryption cancelled"
	end

	ok, status, err = decrypt_once(input, output, config, false)
	if not ok or not status_has(status, "DECRYPTION_OKAY") or not path_exists(output) then
		if path_exists(output) then
			fs.remove("file", Url(output))
		end
		return false, nil, true, "Legacy decryption failed: " .. err
	end
	return true, status, true
end

local function safe_archive_entries(archive)
	local ok, stdout, err = run("tar", { "-tzf", archive })
	if not ok then
		return nil, "Cannot list archive: " .. err
	end

	local roots, count = {}, 0
	for line in stdout:gmatch("[^\r\n]+") do
		local name = line:gsub("^%./", "")
		if
			name == ""
			or name == "."
			or name:sub(1, 1) == "/"
			or name == ".."
			or name:match("^%.%./")
			or name:match("/%.%./")
			or name:match("/%.%.$")
		then
			return nil, "Unsafe archive path: " .. line
		end

		local root = name:match("^([^/]+)")
		if root and not roots[root] then
			roots[root] = true
			count = count + 1
		end
	end

	if count == 0 then
		return nil, "Archive is empty"
	end
	return roots
end

local function restore_archive(payload, encrypted_path, parent)
	local roots, list_err = safe_archive_entries(payload)
	if not roots then
		return false, list_err
	end
	for root in pairs(roots) do
		if path_exists(join(parent, root)) then
			return false, "Restore target already exists: " .. join(parent, root)
		end
	end

	local extract_dir, err = fs.unique("dir", Url(join(parent, ".yazi-gpg-restore")))
	if not extract_dir then
		return false, "Cannot create restore directory: " .. compact_error(err)
	end
	extract_dir = tostring(extract_dir)
	local chmod_ok, _, chmod_err = run("chmod", { "700", extract_dir })
	if not chmod_ok then
		cleanup_dir(extract_dir)
		return false, "Cannot protect restore directory: " .. chmod_err
	end

	local ok, _, extract_err = run("tar", { "-xzf", payload, "-C", extract_dir })
	if not ok then
		cleanup_dir(extract_dir)
		return false, "tar extraction failed: " .. extract_err
	end

	local files, read_err = fs.read_dir(Url(extract_dir), { resolve = false })
	if not files or #files == 0 then
		cleanup_dir(extract_dir)
		return false, "Extracted archive has no top-level items: " .. compact_error(read_err)
	end

	for _, file in ipairs(files) do
		local target = join(parent, file.name)
		local moved, move_err = move_noreplace(tostring(file.url), target)
		if not moved then
			cleanup_dir(extract_dir)
			return false, "Failed to restore '" .. file.name .. "': " .. move_err
		end
	end
	cleanup_dir(extract_dir)

	local removed, remove_err = fs.remove("file", Url(encrypted_path))
	if not removed then
		return true, "Restored successfully, but ciphertext was kept: " .. compact_error(remove_err)
	end
	return true
end

local function restore_file(payload, encrypted_path)
	local output = encrypted_path:gsub("%.gpg$", "")
	if output == encrypted_path then
		return false, "Encrypted file must end in .gpg"
	end
	if path_exists(output) then
		return false, "Restore target already exists: " .. output
	end

	local moved, move_err = move_noreplace(payload, output)
	if not moved then
		return false, move_err
	end

	local removed, remove_err = fs.remove("file", Url(encrypted_path))
	if not removed then
		return true, "Restored successfully, but ciphertext was kept: " .. compact_error(remove_err)
	end
	return true
end

local function decrypt(config)
	local targets, target_err = prepare_targets(selected_or_hovered())
	if not targets then
		notify(target_err, "error")
		return
	end
	if #targets ~= 1 then
		notify("Decrypt one encrypted file at a time", "warn")
		return
	end

	local item = targets[1]
	if item.is_dir or not item.path:lower():match("%.gpg$") then
		notify("Select a .gpg file to decrypt", "warn")
		return
	end

	if not exact_confirmation("Type y to decrypt, verify & replace '" .. item.name .. "':") then
		return
	end

	local temp_dir, temp_err = make_temp_dir(item.parent)
	if not temp_dir then
		notify("Failed to create private temp directory: " .. temp_err, "error")
		return
	end
	local payload = join(temp_dir, "payload")

	local decrypted, status, legacy, decrypt_err = decrypt_payload(item.path, payload, config)
	if not decrypted then
		cleanup_dir(temp_dir)
		notify(decrypt_err, legacy and "warn" or "error", 9)
		return
	end

	local marker = embedded_filename(status)
	local archive_mode = marker == ARCHIVE_MARKER or (legacy and item.path:lower():match("%.tar%.gz%.gpg$"))
	local restored, restore_err
	if archive_mode then
		restored, restore_err = restore_archive(payload, item.path, item.parent)
	else
		restored, restore_err = restore_file(payload, item.path)
	end

	cleanup_dir(temp_dir)
	ya.emit("escape", { select = true })

	if not restored then
		notify("Decryption stopped; ciphertext was kept.\n" .. compact_error(restore_err), "error", 9)
	elseif restore_err then
		notify(restore_err, "warn", 9)
	else
		notify(legacy and "Legacy file decrypted (unsigned)" or "Decrypted with a valid signature", "info", 8)
	end
end

local function entry(_, job)
	local config = get_config()
	local config_ok, config_err = validate_config(config)
	if not config_ok then
		notify(config_err, "error")
		return
	end

	local action = job.args and job.args[1] or ""
	local ok, err
	if action == "encrypt" then
		ok, err = pcall(encrypt, config)
	elseif action == "decrypt" then
		ok, err = pcall(decrypt, config)
	else
		notify("Unknown action: " .. tostring(action), "error")
		return
	end

	if not ok then
		notify("Unexpected plugin error: " .. compact_error(err), "error", 10)
	end
end

local function setup(state, options)
	options = options or {}
	state.recipient = normalize_fingerprint(options.recipient or DEFAULT_RECIPIENT)
	state.signer = normalize_fingerprint(options.signer or DEFAULT_SIGNER)
end

return {
	entry = entry,
	setup = setup,
}
