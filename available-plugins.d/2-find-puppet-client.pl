#!/usr/bin/perl -p

next unless m| (/(?:[^ ]*/)?clients/c_([^/]*)/)|;
$clientdir=$1;
$client=$2;
s/$clientdir//g;
s/( \!. )/$1$client /;
