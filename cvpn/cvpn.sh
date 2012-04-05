#!/usr/bin/env bash

filelist=`find $1`

dopwd() {
    local filelist=`ls`
    for afile in $filelist ; do
        local newfile=`echo $afile | tr [:upper:] [:lower:]`
        if [ $afile != $newfile ]; then
            mv $afile $newfile
        fi

        if [ -f $newfile ]; then
            if [ ! -z `echo $newfile | grep "^.*\gz$"` ]; then
                local noext=`echo $newfile|sed 's/\(.*\)\.gz$/\1/'`
                mv $newfile $noext.zip
            fi
        fi

        if [ -d $newfile ]; then
            cd $newfile
            dopwd
            cd ..
        fi
    done
}

dir=`pwd`
cd $1
dopwd
cd $dir
