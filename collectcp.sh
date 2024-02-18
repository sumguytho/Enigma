#!/bin/bash

prefix="$1"
if [ -n "$prefix" ]; then
    prefix="$prefix/"
fi
echo $prefix*.jar | sed "s/ /:/g"
