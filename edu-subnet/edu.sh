#!/bin/sh

mode="mask-length"

Error()
{
    if [ -n $1 ]; then
        echo "Error: $1"
    fi
    cat <<EOF
Usage: `basename $0` [-w] file
    -w  Enable adress wildcard mode. Output looks like
            162.105.0.0 0.0.255.255
            166.111.0.0 0.0.255.255
        Otherwise, Output looks like
            162.105.0.0 16
            166.111.0.0 16
    file  Path to the progressing file.
EOF
    exit 1
}

while getopt :w OPTION; do
    case "$OPTION" in
    w)mode="netmask"
    *)
        Error "Wrong option"
done

shift (($OPTIND-1))
if [ -n $1 ]; then
    Error "Not a file"
fi

if [ ! -f $1 ]; then
    Error "$1 not a file"
fi


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

    if [ mode -eq "mask-length" ]; then
        echo "$addr -> $ip $length"        
        continue
    fi
    
    ((masklength=24-$length))
    max=$(echo "$masklength/8"|bc)
    rest=$(echo "$masklength - $masklength/8*8"|bc)
    # echo "max: $max, rest: $rest"
    
    for i in `seq 1 $max`; do
        netmask=".255${netmask}"
    done
    # echo "netmask: $netmask"
    restmask=${rest2mask[$rest]}
    netmask="$restmask$netmask"
    ((maskneed=4-max-1))
    for i in `seq 1 $maskneed`; do
        netmask="0.$netmask"
    done

    echo "$addr -> $ip $netmask"


done



