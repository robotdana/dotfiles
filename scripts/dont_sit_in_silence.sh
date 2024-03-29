#!/bin/bash

set -e

# whenever you find yourself sitting in silence after a zoom meeting or etc
# it will give a notification you can click to play whatever was last playing in spotify
# it _shouldn't_ pop up while in a meeting?

if ! which alerter; then
  brew install alerter
fi

function alert_if_no_audio {
  # from https://apple.stackexchange.com/questions/363416/how-to-check-if-any-audio-is-currently-playing-via-terminal
  if ! [[ "$(pmset -g | grep -F ' sleep')" == *"coreaudiod"* ]]; then
    # from: https://github.com/vjeantet/alerter
    case "$(alerter -title "Silence Detector" \
        -message "You are sitting in silence" \
        -sender com.spotify.client \
        -activate com.spotify.client \
        -actions Play \
        -group "sh.dana.dont_sit_in_silence")" in
        "@TIMEOUT"|"@CLOSED");;
        # from: https://stackoverflow.com/questions/8901556/controlling-spotify-with-applescript
        "@CONTENTCLICKED"|"@ACTIONCLICKED"|"Play") osascript -e "tell application \"Spotify\"
                                                play
                                              end tell" ;;
        **) echo "Unexpected Response" ;;
    esac


  fi
  sleep 10
  alert_if_no_audio
}

alert_if_no_audio
