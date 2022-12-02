#!/bin/bash

file_stream_in="$1"
file_stream_out_expect="$2"
current_dir=$(dirname "$0")
add_args=''

if [ -n "$3" ]; then
    if [ -f "$3" ]; then
        add_args=()
        IFS=" " read -r -a add_args <<< "$(cat "$3")"
    fi
fi

if [ -n "$USE_VALGRIND" ]; then
    if valgrind --log-file=file.log --quiet "$current_dir/../../app.exe" "${add_args[@]}" < "$file_stream_in" > "result.txt"; then

        content_file=$(cat "file.log")

        if [ -z "$content_file" ]; then
            if  "$current_dir/./comparator.sh" "$file_stream_out_expect" "result.txt" > /dev/null; then
                exit 0
            else
                exit 1
            fi
        else
            if "$current_dir/./comparator.sh" "$file_stream_out_expect" "result.txt" > /dev/null; then
                exit 2
            else
                exit 3
            fi
        fi
    fi
else
    if "$current_dir/../../app.exe" "${add_args[@]}" > "$current_dir/result.txt"; then
        if "$current_dir/./comparator.sh" "$file_stream_out_expect" "$current_dir/result.txt" > /dev/null; then
            exit 0
        else
            exit 1
        fi
    fi
fi
