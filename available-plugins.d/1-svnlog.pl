#!/usr/bin/perl -0

## Find and parse configuration
$0 =~ m|(.*)/([^\/\.]*)(\..*)?$|;
$execdir=$1;
$basename=$2;
$basename =~ /^[0-9A-F]+-/;
$logalias = $'; #'; # stupid comment to make emacs perl-mode happy
$conffile="$execdir/../conf.d/$basename.conf";
-r $conffile || die "couldn't read $conffile";
open(CONF, "<$conffile");
$conf=<CONF>;
close(CONF);
## this could be a good idea, but KISS (not tested)
#$conf =~ /^\s*\#[^\n]*\n//sg;
$conf =~ /(^|\n)\s*WORKDIR\s*=\s*([^\s\#]*)/ || die "No WORKDIR specified in $conffile";
$workdir=$2;

## Get svn log
chdir($workdir);
open(SVNLOG, "svn log -v -r'{$ARGV[0]}:{$ARGV[1]}'|");
$_=<SVNLOG>;
close(SVNLOG);

## parse svn log
for my $rev (split(/------------------------------------------------------------------------/)) {
    @rev = $rev =~ /r(\d+) \| (\w+) \| (20\d\d-\d\d-\d\d\s*\d\d:\d\d:\d\d) \+\d\d[03]0 \([^\)]*\) \| (\d+) lines?\n/;
    $more = $';  # '; # extra comments to make emacs perl-mode happy
    next unless $rev[1] eq $ENV{'LOGNAME'};

    $more =~ /\n\n/;
    $files = $`;
    $comment = $'; #';

    $comment =~ s/\n//g;
    $files =~ s/\n//g;

    print "$rev[2]\t<$rev[1]> !c $logalias r$rev[0] $comment $files\n";
}
