#!/usr/bin/bash

begin="$1"
end="$2"

error() {
    echo "$@" >&2
    exit 1
}

## source configuration
.  $(dirname $0)/../conf.d/$(basename $0 .sh).conf

if [[ -z "$IRSSILOG_TAIL" ]]
then
    error 'missing config variable $ISRSSILOG_TAIL'
fi

## when log time format is set to %H:%M ...
#$IRSSILOG_TAIL | perl -ne 'if (/Day changed (... ... \d\d 20\d\d)$/) { $day=`date -d "$1" +%F` ; chomp($day); $day="$day ";}; next if $day lt "'$begin'"; next if $day gt "'$end'"; /\<.?'$USER'\>(.*) \![cbBehHi]( |$)/ || next; s/\d\d:\d\d (<.?'$USER'>) (\d\d):?(\d\d)/$2:$3 $1/; s/^/$day/; print;'
## after /set log_timestamp %F %H:%M:%S 
$IRSSILOG_TAIL | perl -ne '/\s*(\d\d\d\d-\d\d-\d\d).*\<.?'$USER'\>(.*) \![cbBehHi]( |$)/ || next; $day=$1; next if $day lt "'$begin'"; next if $day ge "'$end'"; s/\d\d:\d\d:\d\d\s+(<.?'$USER'>)\s+(\d\d):?(\d\d)/$2:$3 $1/; print;'
