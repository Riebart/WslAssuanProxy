#!/bin/bash

assuanFile="$1"
assuanIpAddr="$2"

(
    tail -n+2 "$assuanFile"
    cat -
) | nc -n "$assuanIpAddr" `head -n1 "$assuanFile"`
