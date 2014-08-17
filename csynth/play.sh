#!/bin/sh

DIR=`dirname $0`
BIN="$DIR/raw_player"

$BIN -s 256 -r 44100 -v 0.25 |\
    play -t raw -r 44100 -e signed -b 32 -c 1 - 
