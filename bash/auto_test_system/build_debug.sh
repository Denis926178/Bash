#!/bin/bash

gcc -std=c99 -Wall -Werror -Wvla -Wpedantic -Wextra -Wfloat-conversion -Wfloat-equal -lm -g3 -c ./*.c
gcc ./*.o -o app.exe -lm
