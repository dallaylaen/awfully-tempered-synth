#!/bin/sh

EXPECTED="csynth/expected.out"
BIN=csynth/synth_test

cmd () {
    gcc -Wall -Wextra -o "$BIN" \
        csynth/simple_synth.c csynth/main_test.c -lm && "$BIN"
    RET=$?
    rm -f "$BIN"
    return $RET
}

if [ "x$1" = "x--reset" ]; then
    echo "RESETTING THE TEST"
    cmd >"$EXPECTED.new"
    RET=$?
    if [ "$RET" = 0 ]; then
        mv -f "$EXPECTED.new" "$EXPECTED"
    else
        echo "FAILED!!"
    fi

    exit $RET
fi 

echo 1..1

cmd | diff -ur csynth/expected.out - 

RET=$?

if [ "$RET" -eq 0 ]; then
    echo "ok 1"
else
    echo "not ok 1"
fi
exit $RET
