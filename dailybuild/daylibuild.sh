#!/bin/sh 

require_vars="svnrepo logfile checkedver duration sendto"


error() {
    echo "$1" | tee -a "$logfile"
}

report_error() {
    echo "$1" | tee -a "$logfile"
    next_uncheck_ver=$(expr "$checkedver" + 1)
    body=$(svn log -v -r"$next_uncheck_ver":r"$currrev" "$svnrepo")
    echo "$body" |tee -a "$logfile"
    for i in `echo $sendto|sed 's/ /\n/g'`; do
        echo "Sending report to $i" |tee -a "$logfile"
        echo "$body" | mail -s "daylibuild failed on r$currrev" "$i" | tee -a "$logfile"
    done
    sed -i "s/checkedver=\"[0-9]\+\"/checkedver=\"$currrev\"/" ./config
}

test_config_file() {
    for var in `echo $require_vars|sed 's/ /\n/g'`; do
        if [ -z "$(eval echo \$"$var")" ]; then
            echo "Missing config variable: $var"
            exit 1
        fi
    done
}

while [ 1 ]; do
    source ./config
    test_config_file
    svn info "$svnrepo"
    if [ "$?" -ne "0" ]; then
        error "Fail to get svn info"
    fi
    currrev=$(svn info "$svnrepo" | awk '{if (NR == 5) print $2}')
    echo "Current version: r$currrev" |tee -a "$logfile"
    if [ "$currrev" != "$checkedver" ]; then
        rm -rf temp-checkout
        svn export "$svnrepo" temp-checkout | tee -a "$logfile"
        (compile "temp-checkout")
        if [ "$?" -ne "0" ]; then
            report_error "Fail to compile"
            sleep "$duration"
            continue
        fi

        (runtest "temp-checkout")
        if [ "$?" -ne "0" ]; then
            report_error "Fail in test"
            sleep "$duration"
            continue
        fi
        sed -i "s/checkedver=\"[0-9]\+\"/checkedver=\"$currrev\"/" ./config
    fi
    sleep "$duration"

done;
