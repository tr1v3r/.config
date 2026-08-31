-- delete-messages.applescript
-- 把指定 id 的邮件移到各自账户废纸篓（Exchange: Deleted Items / Gmail: Trash）。
-- 自动适配账户（Exchange/Gmail）。可恢复，但 Gmail Trash 30 天后自动清空。
-- 用法:
--   osascript delete-messages.applescript 11111 22222  # 示例占位，替换为真实 id
--   或编辑下方 targetIds 占位列表后: osascript delete-messages.applescript
-- id 从 inbox-overview.applescript 输出获取。本文件不含任何真实 id / 账户名 / 邮箱。
-- 关键：聚合 inbox 对 Exchange 邮件 delete 会静默失败，必须落到 account mailbox + id。

on run argv
	set targetIds to {}
	repeat with a in argv
		try
			set end of targetIds to (a as integer)
		end try
	end repeat
	if (count of targetIds) is 0 then
		set targetIds to {0} -- 占位：手动替换为真实 id
	end if
	if (count of targetIds) is 1 and item 1 of targetIds is 0 then
		return "未指定 id：请通过命令行传入，或编辑脚本顶部的 targetIds。"
	end if

	tell application "Mail"
		-- 第一遍：聚合 inbox 只读收集 account/mailbox/id/subject
		set acctList to {}
		set mbList to {}
		set idList to {}
		set subjList to {}
		repeat with m in (messages of inbox)
			try
				set mid to id of m
				if targetIds contains mid then
					set mbName to (name of mailbox of m)
					if mbName is "All Mail" then set mbName to "INBOX"
					set end of idList to mid
					set end of mbList to mbName
					set end of acctList to (name of account of mailbox of m)
					set end of subjList to (subject of m)
				end if
			end try
		end repeat

		-- 第二遍：account mailbox + id 定位删除（每次按 id 重新查询，避免持有失效引用）
		set delCount to 0
		set report to ""
		repeat with i from 1 to (count of idList)
			set acctName to item i of acctList
			set mbName to item i of mbList
			set mid to item i of idList
			try
				set mb to mailbox mbName of account acctName
				set t to first message of mb whose id is mid
				delete t
				set delCount to delCount + 1
				set report to report & "✓ [" & acctName & "] id=" & mid & "  " & (item i of subjList) & linefeed
			on error errmsg
				set report to report & "✗ [" & acctName & " id=" & mid & "] " & errmsg & linefeed
			end try
		end repeat

		return "命中 " & (count of idList) & "/" & (count of targetIds) & "，删除 " & delCount & linefeed & report
	end tell
end run
