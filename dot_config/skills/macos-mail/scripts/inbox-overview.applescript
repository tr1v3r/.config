-- inbox-overview.applescript
-- 列出所有账户 inbox 规模 + 聚合 inbox 每封邮件的元数据。只读，无副作用。
-- 用法:  osascript inbox-overview.applescript
-- 不含任何账户名/邮箱/真实 id —— 账户与 mailbox 均在运行时动态枚举。

tell application "Mail"
	set out to ""

	-- 1) 每个账户的 inbox 规模（自动识别 inbox mailbox 名：Inbox / INBOX / 含 nbox）
	repeat with acct in (accounts)
		try
			set inboxName to ""
			repeat with mb in (mailboxes of acct)
				try
					set mn to (name of mb)
					if mn is "Inbox" or mn is "INBOX" or mn contains "nbox" then
						set inboxName to mn
						exit repeat
					end if
				end try
			end repeat
			if inboxName is not "" then
				set mbCount to count of (messages of mailbox inboxName of acct)
				set mbUnread to 0
				repeat with m in (messages of mailbox inboxName of acct)
					try
						if (read status of m) is false then set mbUnread to mbUnread + 1
					end try
				end repeat
				set out to out & "[" & (name of acct) & "] inbox='" & inboxName & "'  共 " & mbCount & "，未读 " & mbUnread & linefeed
			end if
		end try
	end repeat

	-- 2) 聚合 inbox 明细
	set total to count of (messages of inbox)
	set out to out & linefeed & "聚合 inbox 共 " & total & " 封：" & linefeed
	set i to 0
	repeat with m in (messages of inbox)
		set i to i + 1
		try
			set subj to subject of m
			set sndr to sender of m
			set acct to name of account of mailbox of m
			set mid to id of m
			set rs to read status of m
			set d to date received of m
			set ds to (short date string of d) & " " & (time string of d)
			set readMark to ""
			if rs is false then set readMark to " [未读]"
			set out to out & i & ". [" & acct & "]" & readMark & " " & ds & linefeed
			set out to out & "     主题: " & subj & linefeed
			set out to out & "     发件: " & sndr & "   (id=" & mid & ")" & linefeed
		end try
	end repeat
	return out
end tell
