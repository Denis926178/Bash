#!/bin/bash

gcc -std=c99 -Wall -Wpedantic -Wextra -Wfloat-conversion -Wfloat-equal -Wvla -lm -c ./*.c
gcc ./*.o -o app.exe -lm
