#!/bin/bash

verbose=
duration=2
exec 2>/dev/null
Log()
{
    if [ $verbose ]; then
        echo $1
    fi
}
Error()
{
    cat <<EOF

USAGE:
`basename $0` is a auto judging which run bundles of programs
(like students' homework) and compare their output to the standard
answer. It assumes that there is no interaction when the program
running, and the program will finish in time like 1 sec or 2.
$0 -p parent_dir -w relate_path -c template ARGS
    -p  the parent dir of user dir
    -w  path to the student script, begin fro the student's dir
    -c  the correct template.
    ARGS args pass to the students' script
EOF
    exit 1
}

while getopts :p:w:c: OPTION ; do
    case $OPTION in
        p)
            pdir=$OPTARG
            Log "-p $pdir";;
        w)
            rpath=$OPTARG
            Log "-w $rpath";;
        c)
            template=$OPTARG
            Log "-c $template";;
        *)
            Error
    esac
done

if [ -z $pdir ] || [ -z $rpath ] || [ -z $template ]; then
    Error
fi

shift $((OPTIND-1))
args=$@
Log "args: $args"


for user_dir in $(ls $pdir) ; do
    tmpfile=$(mktemp /tmp/$user_dir.XXXXXX)
    Log "tmpfile: $tmpfile"
    if [ -d "$pdir/$user_dir" ]; then
        path="$pdir/$user_dir/$rpath"
        Log "path: $path"
        # ($path $arg >$tmpfile)&
        # pid=$!
        # sleep $duration
        date
        timeout 2>/dev/null $duration $path $arg >$tmpfile
        date
        pid=$!
        Log "pid: $pid"
        case $? in
            127)echo "$user_dir NOTEXISTS NO";;
            126)echo "$user_dir EXISTS NO";;
            125)echo "This should not happend";;
            124)echo "$user_dir EXISTS TIMEOUT";;
            *)
                #Anyway, do this cleanup
                kill -9 -"$pid"

                diff -bB -q $tmpfile $template>/dev/null
                # Log "$(cat $tmpfile)"
                # Log "-------"
                # Log "$(cat $template)"
                if [ $? -eq 0 ]; then
                    echo "$user_dir EXISTS YES"
                else
                    echo "$user_dir EXISTS NO"
                fi
        esac
    fi
done

