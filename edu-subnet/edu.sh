#!/bin/sh


mode="mask-length"

Error()
{
    if [ -n "$1" ]; then
        echo "Error: $1"
    fi
    cat <<EOF
# `basename $0` will format the input file(edu.txt),
# making 162.105/16, 166.111/16, look like the format
# in the usage.
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

while getopts :w OPTION ; do
    case "$OPTION" in
        w)mode="netmask"
            ;;
        *)Error "Wrong option"
            ;;
    esac
done

shift $((OPTIND-1))

if [ -z $1 ]; then
    Error "Need a file"
fi

if [ ! -f $1 ]; then
    Error "$1 not a file"
fi

# this is a table to tranform
# 11.........1 to decimail value
# \---n bit--/
# it is useful for generating netmask
rest2mask_0="0"
rest2mask_1="1"
rest2mask_2="3"
rest2mask_3="7"
rest2mask_4="15"
rest2mask_5="31"
rest2mask_6="63"
rest2mask_7="127"

filename=$1
#reformat the input file. Make it more easy to handle
iplist=$(cat $1 |tr ', ' "\n" | grep -F "/")

for addr in $iplist; do
    ndot=$(echo $addr |grep -F -o '.' |wc -l)
    ip=$(echo $addr|cut -d/ -f1)
    length=$(echo $addr|cut -d/ -f2)
    need=`expr 3 - $ndot`
    for i in `seq 1 $need`; do
        ip="$ip.0"
    done

    if [ $mode = "mask-length" ]; then
        echo "$ip $length"
        continue
    fi

    # If we reach here, it means -w is enable
    # to get the wildcard, need to generate a mask
    # base on how many bit is left for the subnet.
    # for example, if $length = 17, it means
    # in ipv4 address the 32-17=15 bit is left for
    # subnet. In this case, the mask will be
    # 011111111 11111111 -> 0.0.127.255
    #  \--- 15 bits ---/
    # you can calc it. But I choose a tricky way,
    # First of all, the number `.255` in the mask
    # can be get from diving 15 by 8, which is 1.
    # So we have an `.255`, after that, there is
    # seven bits of `1` left, I transform it by
    # an quickly table check.

    masklength=`expr 32 - $length`
    # echo "masklength = $masklength"
    max=$(echo "$masklength/8"|bc)
    rest=$(echo "$masklength%8"|bc)
    # echo "max: $max, rest: $rest"
    netmask=""
    for i in `seq 1 $max`; do
        netmask=".255${netmask}"
    done
    # echo "netmask: $netmask"
    eval "restmask=\${rest2mask_$rest}"
    # echo $restmask
    netmask="$restmask$netmask"
    maskneed=`expr 4 - $max - 1`
    for i in `seq 1 $maskneed`; do
        netmask="0.$netmask"
    done

    echo "$ip $netmask"


done



