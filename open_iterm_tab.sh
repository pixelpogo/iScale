#!/bin/sh

osascript <<ENDSCRIPT
  tell application "iTerm"
    activate
    set myterm to (last terminal)
    tell myterm
      launch session "$1"
      tell the last session
        set foreground color to "yellow"
        set background color to "black"
        set transparency to "0.2"
        write text "$2"
        write text "$3"
        set name to "$1"
      end tell
    end tell
  end tell
ENDSCRIPT
