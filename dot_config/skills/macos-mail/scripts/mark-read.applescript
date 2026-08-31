-- mark-read.applescript
-- 把指定 id 的邮件标记已读。自动适配账户（Exchange/Gmail）。就地改属性，可逆。
-- 用法:
--   osascript mark-read.applescript 11111 22222        # 示例占位，替换为真实 id
--   或编辑下方 targetIds 占位列表后: osascript mark-read.applescript
-- id 从 inbox-overview.applescript 输出获取。本文件不含任何真实 id / 账户名 / 邮箱。

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
		-- 第一遍：聚合 inbox 只读收集 account/mailbox（Gmail 若返回 "All Mail" 改用 INBOX）
		set acctList to {}
		set mbList to {}
		set idList to {}
		repeat with m in (messages of inbox)
			try
				set mid to id of m
				if targetIds contains mid then
					set mbName to (name of mailbox of m)
					if mbName is "All Mail" then set mbName to "INBOX"
					set end of idList to mid
					set end of mbList to mbName
					set end of acctList to (name of account of mailbox of m)
				end if
			end try
		end repeat

		-- 第二遍：account mailbox + id 定位，设 read status
		set done to 0
		set already to 0
		repeat with i from 1 to (count of idList)
			try
				set mb to mailbox (item i of mbList) of account (item i of acctList)
				set t to first message of mb whose id is (item i of idList)
				if (read status of t) is false then
					set read status of t to true
					set done to done + 1
				else
					set already to already + 1
				end if
			end try
		end repeat

		return "命中 " & (count of idList) & "/" & (count of targetIds) & "，新标记 " & done & "，原本已读 " & already
	end tell
end run
