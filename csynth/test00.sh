#!/bin/sh

echo 1..1

gcc -Wall -Wextra -o csynth/synth_test csynth/simple_synth.c csynth/main_test.c -lm &&\
    csynth/synth_test | diff -ur csynth/expected.out - 

RET=$?
rm -f csynth/synth_test

if [ "$RET" -eq 0 ]; then
    echo "ok 1"
else
    echo "not ok 1"
fi
exit $RET
