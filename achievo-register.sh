#!/bin/bash

project="$1"
num_hours="$2"
comments="$3"

if [ -z "$comments" ] || [ "$project" == "--help" ]
then
    echo "usage: $0 project_handle num_hours comments"
    echo "optional environment variables: ACHIEVO_USER, ACHIEVO_PASS, ACHIEVO_DATE, ACHIEVO_URL, ACHIEVO_BILLPERCENT, ACHIEVO_TMPDIR"
    exit 1
fi

[ -z "$ACHIEVO_URL" ] && ACHIEVO_URL="https://secure.redpill-linpro.com/achievo"
[ -z "$ACHIEVO_BILLPERCENT" ] && ACHIEVO_BILLPERCENT="1"


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
curl --cookie-jar cookies.txt --data "auth_user=$ACHIEVO_USER&auth_pw=$ACHIEVO_PASS" --silent "${ACHIEVO_URL}/index.php" > $tmpdir/loginresult

## fetching the session token
sessionid=$(perl -nle 'last if /achievo=([0-9a-f]{32})/ && print $1' $tmpdir/loginresult)

## we need to find the users ID and misc
curl --cookie-jar cookies.txt --silent "${ACHIEVO_URL}/dispatch.php?achievo=$sessionid&atknodetype=timereg.hours&atkaction=admin&atklevel=-1&atkprevlevel=0" > $tmpdir/registration_form

userid=$(perl -nle 'last if /value="person.id='"'"'(\d+)'"'"'"/ && print $1' $tmpdir/registration_form)

## find the projects ID
projectid=$(perl -nle 'last if /<option value="project.id='"'"'(\d+)'"'"'"\s*>'$project'/ && print $1' $tmpdir/registration_form)



## TODO
if [ -z "$projectid" ]
then
    curl --cookie-jar cookies.txt --silent "${ACHIEVO_URL}/dispatch.php?atklevel=1&atkprevlevel=1&atkstackid=50d865ddc43a9&achievo=b7d170a5d05a7e259f40564fedf0d117&atkescape=&atknodetype=project.projectselector&atkaction=select&atksmartsearch=clear&atkstartat=0&atksearch%5Babbreviation%5D=${project}&atksearchmode%5Babbreviation%5D=substring&atksearch%5Bname%5D=&atksearchmode%5Bname%5D=substring&atksearch_AE_coordinator%5Bcoordinator%5D%5B%5D=&atksearchmode%5Bcoordinator%5D=exact" > $tmpdir/projectcode
    projectid=$(perl -nle 'last if /project.id%3D%27(\d+)%27'"'"'"\s*>'$project'/ && print $1' $tmpdir/projectcode)
fi

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

curl -F atklevel=1 -F atkprevlevel=0 -F atkaction=save -F atkprevaction=admin -F userid=person.id="'$userid'" -F activityid=activity.id="'9'" -F 'entrydate[year]'=$cur_year -F 'entrydate[month]'=$cur_month -F 'entrydate[day]'=$cur_day -F 'activitydate[year]'=$year -F 'activitydate[month]'=$month -F 'activitydate[day]'=$day -F projectid="project.id='$projectid'" -F phaseid="phase.id='66'" -F achievo=$sessionid -F "remark=$comments" -F workperiod=1 -F billpercent=${ACHIEVO_BILLPERCENT} "${ACHIEVO_URL}/dispatch.php?atknodetype=timereg.hours&atkaction=admin&atklevel=-1&atkprevlevel=0&achivo=$sessionid" -F time=$num_hours
#-F atkstackid=50c8e8855c359
# atkescape=(blank)


## cleanup
[ -z $ACHIEVO_TMPDIR ] && rm -rf $tmpdir
