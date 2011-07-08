#!/bin/sh

osascript <<ENDSCRIPT
  tell application "iTerm"
    activate
    set myterm to (last terminal)
    tell myterm
      launch session "$1"
      tell the last session
        write text "$2"
        write text "$3"
        set name to "$1"
      end tell
    end tell
  end tell
ENDSCRIPT
