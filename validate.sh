#!/bin/bash
set +e

SHREDDER=$1
IN='./input_pipe'
OUT='./output_pipe'

close_pipes() {
    exec 5>&-
    exec 6>&-
    rm -f "$IN";
    rm -f "$OUT";
}
create_pipes() {
    mkfifo "$IN";
    mkfifo "$OUT";
}
open_pipes() {
    exec 5>$IN;
    exec 6<$OUT;
}

close_pipes
create_pipes

$SHREDDER $timeout < $IN >> $OUT &
pid=$! #gets shredders pid
open_pipes
echo '/bin/pwd' >&5
if ! read -u6 -t 2 RESP; then
    echo  "Timeout on response from shredder"
    exit 1;
fi
expected="shredder# $($'/bin/pwd')"
if [[ $RESP != $expected ]]; then
    echo "Response did not match"
    echo "expected :$expected"
    echo "actual   :$RESP"
    exit 1;
fi
disown $pid &> /dev/null && kill -9 $pid &> /dev/null
close_pipes
echo "Spacing is ok"
