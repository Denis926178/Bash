#!/bin/bash

file1="$1"
file2="$2"

if [ -f "$file1" ] && [ -f "$file2" ]; then
    grep -oE "*" "$file1" > file_new_1.txt
    grep -oE "*" "$file2" > file_new_2.txt
    
    printf "%s %s111\n" "$file1" "$file2"

    if diff "$file1" "$file2"; then
        exit 0
    else 
        exit 1
    fi
else
    exit 1
fi
