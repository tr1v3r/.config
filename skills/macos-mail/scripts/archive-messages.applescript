-- archive-messages.applescript
-- 把指定 id 的邮件 move 到目标文件夹（归档，非删除；邮件仍在账户内可找回）。
-- 自动按每封邮件所在账户，查找【该账户】下同名文件夹；Exchange 自定义文件夹用对象引用，
-- 绕开 "Can't get mailbox"。源 mailbox 自动适配账户（Exchange "Inbox" / Gmail "INBOX"）。
--
-- 用法 A（命令行，单文件夹，推荐）：所有 id 归到同一文件夹
--   osascript archive-messages.applescript "Bank Statements" 11111 22222
--   osascript archive-messages.applescript Notifications 11111 22222 33333
--   （文件夹名含空格用引号包住）
--
-- 用法 B（无参数）：编辑下方 mapping 占位表，一次把多封归到不同文件夹
--   osascript archive-messages.applescript
--
-- id 从 inbox-overview.applescript 输出获取。本文件不含任何账户名 / 邮箱 / 真实 id。

on run argv
	set idList to {}
	set folderList to {}

	if (count of argv) ≥ 2 then
		-- 用法 A：argv[1]=文件夹名，其余=id
		set folderName to item 1 of argv
		repeat with a in (rest of argv)
			try
				set end of idList to (a as integer)
				set end of folderList to folderName
			end try
		end repeat
	else
		-- 用法 B：占位映射表 {id, 文件夹}，按需编辑（下方为示例占位）
		set mapping to {{11111, "FolderA"}, {22222, "FolderB"}}
		repeat with mp in mapping
			set end of idList to item 1 of mp
			set end of folderList to item 2 of mp
		end repeat
		if (count of idList) > 0 and item 1 of idList is 11111 then
			return "用法 B 当前是占位表。编辑脚本内 mapping 替换为真实 {id, 文件夹}，或改用命令行：osascript archive-messages.applescript <文件夹> <id...>"
		end if
	end if

	if (count of idList) is 0 then
		return "未指定：用法 A 传 <文件夹> <id...>，或编辑脚本内 mapping。"
	end if

	tell application "Mail"
		-- 第一遍：聚合 inbox 只读收集每封 account / 源 mailbox / 目标文件夹
		-- （Gmail 的 mailbox of m 返回 "All Mail"，源 mailbox 改用 "INBOX"）
		set foundIds to {}
		set acctList to {}
		set srcMbList to {}
		set foundFolders to {}
		repeat with m in (messages of inbox)
			try
				set mid to id of m
				if idList contains mid then
					set mbName to (name of mailbox of m)
					if mbName is "All Mail" then set mbName to "INBOX"
					set end of foundIds to mid
					set end of acctList to (name of account of mailbox of m)
					set end of srcMbList to mbName
					-- 匹配该 id 对应的目标文件夹
					set f to ""
					repeat with j from 1 to (count of idList)
						if item j of idList is mid then
							set f to item j of folderList
							exit repeat
						end if
					end repeat
					set end of foundFolders to f
				end if
			end try
		end repeat

		-- 第二遍：在邮件所在账户找同名文件夹对象引用 → move
		set moved to 0
		set report to ""
		repeat with i from 1 to (count of foundIds)
			set mid to item i of foundIds
			set acctName to item i of acctList
			set srcMb to item i of srcMbList
			set folderName to item i of foundFolders
			try
				set dst to missing value
				repeat with mb in (mailboxes of account acctName)
					try
						if (name of mb) is folderName then
							set dst to mb
							exit repeat
						end if
					end try
				end repeat
				if dst is missing value then
					set report to report & "✗ [id=" & mid & "] " & acctName & " 下找不到文件夹 '" & folderName & "'" & linefeed
				else
					set src to mailbox srcMb of account acctName
					set t to first message of src whose id is mid
					move t to dst
					set moved to moved + 1
					set report to report & "✓ [id=" & mid & "] " & acctName & " → " & folderName & linefeed
				end if
			on error errmsg
				set report to report & "✗ [id=" & mid & "] " & errmsg & linefeed
			end try
		end repeat

		return "命中 " & (count of foundIds) & "/" & (count of idList) & "，归档 " & moved & linefeed & report
	end tell
end run
