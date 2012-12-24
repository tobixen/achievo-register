#!/bin/bash

project="$1"
num_hours="$2"
comments="$3"

if [ -z "$comments" ] || [ "$project" == "--help" ]
then
    echo "usage: $0 project_handle num_hours comments"
    echo "optional environment variables: ACHIEVO_USER, ACHIEVO_PASS, ACHIEVO_DATE"
    exit 1
fi

if [ -z "$ACHIEVO_TMPDIR" ]
then
    tmpdir=$(mktemp -d)
else
    tmpdir=$ACHIEVO_TMPDIR
fi
chmod og-rx $tmpdir
cd $tmpdir

if [ -z "$ACHIEVO_USER" ]
then
    ACHIEVO_USER="$LOGNAME"
    echo "assuming achievo user id $ACHIEVO_USER - this may be overridden with the \$ACHIEVO_USER environment variable"
fi

if [ -z "$ACHIEVO_PASS" ]
then
    echo "enter your achievo password (may also be passed in the ACHIEVO_PASS environment variable):"
    read ACHIEVO_PASS
fi

## logging in
curl --cookie-jar cookies.txt --data "auth_user=$ACHIEVO_USER&auth_pw=$ACHIEVO_PASS" --silent "https://secure.redpill-linpro.com/achievo/index.php" > $tmpdir/loginresult

## fetching the session token
sessionid=$(perl -nle 'last if /achievo=([0-9a-f]{32})/ && print $1' $tmpdir/loginresult)

## we need to find the users ID and misc
curl --cookie-jar cookies.txt --silent "https://secure.redpill-linpro.com/achievo/dispatch.php?achievo=$sessionid&atknodetype=timereg.hours&atkaction=admin&atklevel=-1&atkprevlevel=0" > $tmpdir/registration_form

userid=$(perl -nle 'last if /value="person.id='"'"'(\d+)'"'"'"/ && print $1' $tmpdir/registration_form)

## find the projects ID
### TODO

cur_year=$(date +%Y)
cur_month=$(date +%m)
cur_day=$(date +%d)

if [ -z "$ACHIEVO_DATE" ]
then
    year=$cur_year
    month=$cur_month
    day=$cur_day
else
    year=$(date -d "$ACHIEVO_DATE" +%Y)
    month=$(date -d "$ACHIEVO_DATE" +%m)
    day=$(date -d "$ACHIEVO_DATE" +%d)
fi

curl -F atklevel=1 -F atkprevlevel=0 -F atkaction=save -F atkprevaction=admin -F userid=person.id="'$userid'" -F activityid=activity.id="'9'" -F 'entrydate[year]'=$cur_year -F 'entrydate[month]'=$cur_month -F 'entrydate[day]'=$cur_day -F 'activitydate[year]'=$year -F 'activitydate[month]'=$month -F 'activitydate[day]'=$day -F projectid="project.id='$project'" -F phaseid="phase.id='66'" -F achievo=$sessionid -F "remark=$comments" -F workperiod=1 -F billpercent=1 "https://secure.redpill-linpro.com/achievo/dispatch.php?atknodetype=timereg.hours&atkaction=admin&atklevel=-1&atkprevlevel=0&achivo=$sessionid" -F time=$num_hours
#-F atkstackid=50c8e8855c359
# atkescape=(blank)


## cleanup
[ -z $ACHIEVO_TMPDIR ] && rm -rf $tmpdir
