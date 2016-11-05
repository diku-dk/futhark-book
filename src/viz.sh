#/bin/bash

sed -e 's/], /\
/g' | sed -e 's/i32//g' | sed -e 's/, //g' | sed -e 's/\[//g' | sed -e 's/]//g' <&0
