#!/bin/bash

project="$1"
num_hours="$2"
comments="$3"

[ -f "$HOME/.achievorc" ] && . "$HOME/.achievorc"

## Defaults
[ -z "$ACHIEVO_BILLPERCENTID" ] && ACHIEVO_BILLPERCENTID="1"
[ -z "$ACHIEVO_ACTIVITYID" ] && ACHIEVO_ACTIVITYID="9"

if [ -z "$comments" ] || [ "$project" == "--help" ]
then
    echo "usage: $0 project_handle num_hours comments"
    echo "optional environment variables: ACHIEVO_USER, ACHIEVO_PASS, ACHIEVO_DATE, ACHIEVO_URL, ACHIEVO_BILLPERCENTID, ACHIEVO_TMPDIR, ACHIEVO_PHASEID"
    echo "script will source $HOME/.achievorc on startup, so ACHIVO_PASS and ACHIEVO_USER may be thrown in there"
    exit 1
fi

## attempt to fix charset issues
comments="$(echo "$comments" |  iconv -f utf8 -t iso-8859-1)"
project="$(echo "$project" | iconv -f utf8 -t iso-8859-1)"

## At least the top two default values needs to be tweaked for external usage
if [ -z "$ACHIEVO_URL" ]
then
    echo "Please set up a .achievorc with ACHIEVO_URL and ACHIEVO_PASS.  Read the README."
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
curl --cookie-jar cookies.txt --data "auth_user=$ACHIEVO_USER&auth_pw=$ACHIEVO_PASS" --silent "${ACHIEVO_URL}/index.php" > $tmpdir/loginresult

## fetching the session token
sessionid=$(perl -nle 'last if /achievo=([0-9a-f]{32})/ && print $1' $tmpdir/loginresult)

## we need to find the users ID and misc
curl --cookie-jar cookies.txt --silent "${ACHIEVO_URL}/dispatch.php?achievo=$sessionid&atknodetype=timereg.hours&atkaction=admin&atklevel=-1&atkprevlevel=0" > $tmpdir/registration_form

userid=$(perl -nle 'last if /value="person.id='"'"'(\d+)'"'"'"/ && print $1' $tmpdir/registration_form)

## find the projects ID
projectid=$(perl -nle 'last if /<option value="project.id='"'"'(\d+)'"'"'"\s*>'$project'/ && print $1' $tmpdir/registration_form)



if [ -z "$projectid" ]
then
    atkstackid=$(perl -nle 'last if /atkstackid=([0-9a-f]*)/ && print $1' $tmpdir/registration_form)
    curl --cookie-jar cookies.txt --silent "${ACHIEVO_URL}/dispatch.php?atknodetype=project.projectselector&atkaction=select&atktarget=dispatch.php%3Fatklevel%3D0%26viewuser%3D${userid}%26projectid%3D%5Batkprimkey%5D%26hoursid%3D&viewuser=${userid}&atklevel=1&atkprevlevel=0&atkstackid=${atkstackid}&achievo=${sessionid}" > $tmpdir/selectproject ## I don't need this ... but achievo does ... achievo is rather stateful :-(
    curl --cookie-jar cookies.txt --silent "${ACHIEVO_URL}/dispatch.php?atklevel=1&atkprevlevel=1&atkstackid=${atkstackid}&achievo=${sessionid}&atkescape=&atknodetype=project.projectselector&atkaction=select&atksmartsearch=clear&atkstartat=0&atksearch%5Babbreviation%5D=${project}&atksearchmode%5Babbreviation%5D=substring&atksearch%5Bname%5D=&atksearchmode%5Bname%5D=substring&atksearch_AE_coordinator%5Bcoordinator%5D%5B%5D=&atksearchmode%5Bcoordinator%5D=exact" > $tmpdir/projectcode
    projectid=$(perl -nle 'last if /project.id%3D%27(\d+)%27/ && print $1' $tmpdir/projectcode)
fi

if [ -z "$projectid" ]
then
    echo "something has gone wrong - can't find project $project"
    exit 1
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

if [ -z $ACHIEVO_PHASEID ]
then
    curl --silent -d userid=person.id%3D"'$userid'" -d activityid=activity.id%3D"'$ACHIEVO_ACTIVITYID'" -d 'entrydate%5Byear%5D'=$cur_year -d 'entrydate%5Bmonth%5D'=$cur_month -d 'entrydate%5Bday%5D'=$cur_day -d 'activitydate%5Byear%5D'=$year -d 'activitydate%5Bmonth%5D'=$month  -d time=$num_hours -d 'activitydate%5Bday%5D'=$day -d projectid="project.id%3D'$projectid'" -d achievo=$sessionid -d "remark=$comments" -d workperiod="workperiod.id%3D1" -d billpercent="billpercent.id%3D'${ACHIEVO_BILLPERCENTID}'" "${ACHIEVO_URL}/dispatch.php?atknodetype=timereg.hours&atkaction=add&atkfieldprefix=&atkpartial=attribute.phaseid.refresh&atklevel=-3&atkprevlevel=0&achivo=$sessionid" > $tmpdir/phaseid
    ACHIEVO_PHASEID=$(perl -nle 'last if /phase.id='"'"'(\d+)'"'"'/ && print $1' $tmpdir/phaseid)
fi

curl -F atklevel=1 -F atkprevlevel=0 -F atkaction=save -F atkprevaction=admin -F userid=person.id="'$userid'" -F activityid=activity.id="'$ACHIEVO_ACTIVITYID'" -F 'entrydate[year]'=$cur_year -F 'entrydate[month]'=$cur_month -F 'entrydate[day]'=$cur_day -F 'activitydate[year]'=$year -F 'activitydate[month]'=$month -F 'activitydate[day]'=$day -F projectid="project.id='$projectid'" -F phaseid="phase.id='$ACHIEVO_PHASEID'" -F achievo=$sessionid -F "remark=$comments" -F workperiod=1 -F billpercent="billpercent.id='${ACHIEVO_BILLPERCENTID}'" "${ACHIEVO_URL}/dispatch.php?atknodetype=timereg.hours&atkaction=admin&atklevel=-1&atkprevlevel=0&achivo=$sessionid" -F time=$num_hours


## cleanup
[ -z $ACHIEVO_TMPDIR ] && rm -rf $tmpdir
