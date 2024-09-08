#!/bin/bash

MUSIC_DIR="$HOME/Music"
TMUX_PATH="/home/linuxbrew/.linuxbrew/bin/tmux"

start_cmus() {
    if ! pgrep -x "cmus" > /dev/null; then
        if command -v "$TMUX_PATH" &> /dev/null; then
            "$TMUX_PATH" new-session -d -s cmus 'cmus'
            notify-send "cmus" "Started cmus in the background"
        else
            notify-send "Error" "tmux is not installed. Please install tmux or start cmus manually."
            exit 1
        fi
    fi
}

list_music_files() {
    find "$MUSIC_DIR" -type f \( -name "*.mp3" -o -name "*.flac" -o -name "*.wav" -o -name "*.ogg" -o -name "*.mp4" -o -name "*.webm" \) -printf "%P\n" | sort
}

play_music() {
    if cmus-remote -f "$MUSIC_DIR/$1"; then
        notify-send "Now playing" "$1"
    else
        notify-send "Error" "Unable to play the file. There might be an issue with cmus or the file itself."
    fi
}

main() {
    if [ ! -d "$MUSIC_DIR" ]; then
        notify-send "Error" "Music directory $MUSIC_DIR does not exist."
        exit 1
    fi

    start_cmus

    music_files=$(list_music_files)

    if [ -z "$music_files" ]; then
        notify-send "Error" "No music files found in $MUSIC_DIR."
        exit 1
    fi

    selected_file=$(echo "$music_files" | rofi -dmenu -i -p "Music")

    if [ -n "$selected_file" ]; then
        play_music "$selected_file"
    fi
}

main
