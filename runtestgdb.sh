#!/bin/sh 
set -x
set -e

arm-linux-gnueabi-gcc-4.4 jforth_test.s -o jforth_test -D_TEST_ -static  -g
qemu-arm -g 2222 ./jforth_test
