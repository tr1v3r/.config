#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Take a break
# @raycast.mode compact

# Optional parameters:
# @raycast.icon ☕
# @raycast.packageName Common

# Documentation:
# @raycast.description Lock Screen
# @raycast.author tr1v3r
# @raycast.authorURL https://raycast.com/tr1v3r

tell application "System Events" to keystroke "q" using {control down, command down}

log "Take a break!"
