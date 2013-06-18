#!/bin/sh 
set -x
set -e

arm-linux-gnueabi-gcc-4.4 jforth_test.s -o jforth_test -DBOARD_VIRTUAL -D_TEST_ -static  -g
qemu-arm ./jforth_test
