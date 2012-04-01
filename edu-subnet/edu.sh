#!/bin/sh

rest2mask[0]="0"
rest2mask[1]="128"
rest2mask[2]="192"
rest2mask[3]="224"
rest2mask[4]="240"
rest2mask[5]="248"
rest2mask[6]="252"
rest2mask[7]="254"

filename=$1
iplist=$(cat $1 |tr ', ' "\n" | grep -F "/")

for addr in $iplist; do
    ndot=$(echo $addr |grep -F -o '.' |wc -l)
    ip=$(echo $addr|cut -d/ -f1)
    length=$(echo $addr|cut -d/ -f2)
    ((need=3-$ndot))
    for i in `seq 1 $need`; do
        ip="$ip.0"
    done

    max=$(echo "$length/8"|bc)
    rest=$(echo "$length - $length/8*8"|bc)
    # echo "max: $max, rest: $rest"
    netmask=""
    for i in `seq 1 $max`; do
        netmask="${netmask}255."
    done
    # echo "netmask: $netmask"
    restmask=${rest2mask[$rest]}
    netmask="$netmask$restmask"
    ((maskneed=4-max-1))
    for i in `seq 1 $maskneed`; do
        netmask="$netmask.0"
    done

    echo "$addr -> $ip $length | $netmask"


done



