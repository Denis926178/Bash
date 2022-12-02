#!/bin/bash

gcc ./*.c -lm --coverage -o app.exe
./func_tests/scripts/func_tests.sh

gcov ./*.c
