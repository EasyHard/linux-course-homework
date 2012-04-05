#!/usr/bin/env bash

POSTDATA=$(</dev/stdin)

# $POSTDATA is empty, no post data submitted
if [ -z $POSTDATA ]; then
    cat <<HERE
Content-type: text/html

<html><head><title>Email Spider</title></head>
<body>
<form action="./spider.cgi" method="post">
Enter a Weblink: <input type="text" name="link"></input><br>
<input type="submit" name="subbtn" value="Submit">
<form>
</body>
</html>
HERE
    exit
fi

echo "Content-type: text/plain"
echo

#get weblink from POSTDATA
weblink=`echo $POSTDATA | grep -o -E "link=[^&]*" | cut -c6-`
echo $weblink
exit
HOST_LABEL="([0-9a-zA-Z]|[0-9a-zA-Z][-0-9a-zA-Z]{0,61}[0-9a-zA-Z])"
IP_ADDR="(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])"
HOST="((($HOST_LABEL\.)+$HOST_LABEL)|(\[$IP_ADDR\]))"
LP_Chars="[-0-9a-zA-Z_.!#$%&'*+/=?^_\`{|}~]"
LOCAL="$LP_Chars+"

webpage=`wget -q -O- $weblink`
if [ $? != "0" ]; then
    echo "Fail to get web page from $weblink"
    exit
fi
LIST=`echo $webpage | grep -o -E "$LOCAL@$HOST" |sort|uniq`
for email in $LIST ; do
    # echo $email
    username=`echo $email|cut -d@ -f1`
    domain=`echo $email|cut -d@ -f2`
    echo "$email $username"
done
