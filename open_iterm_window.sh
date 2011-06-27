#!/bin/sh

osascript <<ENDSCRIPT
  tell application "iTerm"
    activate
    set myterm to (make new terminal)
  end tell
ENDSCRIPT