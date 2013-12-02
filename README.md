NOTE: ask me about registration-log.py eventually.  This is published as-is as
for now, but missing parts and bits (personal configuration, plugins, etc) and
missing documentation.

This is primary made for employees of Redpill-Linpro.  This may be
useful for others using achievo as well, I'd be happy to know if the
script works out of the box or not for other achievo instances.

For support and ideas, contact tobias@redpill-linpro.com, or /msg
tobias at irc.redpill-linpro.com

Quickguide optimized for fellow colleagues
==========================================

* Clone the repository

    git clone https://github.com/tobixen/achievo-register.git

* Set up $HOME/.achievorc like this:

    ACHIEVO_USER=$LOGNAME  
    ACHIEVO_PASS="dead stapled horse eating battery"  
    [ -z "$ACHIEVO_URL" ] && ACHIEVO_URL="https://${ACHIEVO_USER}:dead%20stapled%20horse%20eating%20battery@secure.redpill-linpro.com/achievo"  

* Run the script like this:

    achievo-register/achievo-register.sh drf-div 00:15 "research and setup of achievo-register.sh"

Install & use
=============

Currently the achievo register script is a simple stupid bash script
that takes three positional mandatory arguments - the project code,
the number of hours and the remarks.  Since option passing in bash is
painful, environment variables are used for passing options and
configuration:

* ACHIEVO_USER - defaults to $LOGNAME, which is usually sane, but it's nice to set this environment variable to avoid the warning from the script.
* ACHIEVO_PASS - by default the script will read it from stdin.
* ACHIEVO_URL - mandatory configuration variable.
* ACHIEVO_DATE - date the work was performed (defaults to "today")
* ACHIEVO_BILLPERCENTID - defaults to 1 for "normal (100%) billable".  For Redpill Linpro, 3 is alternatively the most useful value (non-billable).
* ACHIEVO_PHASEID - integer for the phase ID.  Need not be set for projects with only one phase.
* ACHIEVO_TMPDIR - mostly for debugging purposes - if set, the script will store temporary files in this directory, and will delete the directory after usage.  With ACHIEVO_TMPDIR set to some directory, the given directory will be used, and no cleanup will be performed.
* ACHIEVO_ACTIVITYID - yet another integer ID.  The default value is 9, but this default is slightly Redpill-Linpro-specific.


KNOWN BUGS
==========

* Charset problems - avoid using non-ascii letters as it gets converted to WTF-8.
* very sloppy support for phase ID - it has to be specified as a numeric ID.  Automatic selection of phase ID works for projects with only one phase ID.
* very sloppy support for billable percentage - for Redpill Linpro, set ACHIEVO_BILLPERCENTID=3 for "0% billable" and leave the default (1) for "100% billable".
* Not very well tested - always follow up by checking the Web UI that the registration has gone correctly through

General thoughts
================

Our Achievo is annoyingly slow.  I've tried to look a bit on it - it
does queries like "what projects have you been working on during the
last two months?" on a big table with all the time registrations just
to populate the select-box with available projects.  This could
probably be fixed by caching on the application side ... but PHP
coding is not my cup of tea, someone else eventually has to look into
that.

Even if achievo would have been fast, it's a significant overhead to
register hours - depending on how fine-grained and exact one wants the
registrations to be.

The "Timesheet" view in the webui is handy for reviewing and editing
all time registrations for a full day.  I think it would be a useful
workflow to have the timesheet prefilled with information gathered
from other tools and then manually look through and edit.

General wishes
==============

1) Utility to throw in registrations (like work done and billable
hours) into achievo via the command line (to avoid spending time
browsing through menues)

2) Integrations between achievo and other tools (i.e. RT) to avoid
manually copying data from one tool to another.

3) New ways to keep track of how much time I've spent on different
projects.

This simple-ugly bash script solves #1 above.  I will eventually make
another simple-ugly wrapper bash script to solve #3 above.  This
script doesn't really solve #2 above - though, I'm planning to
introduce some wrapper scripts to help me with this as well.

Design ideas
============

This is an ugly bash script ... I did consider some options:

1) Use achoo.  I attempted to go this way, but achoo wasn't the
command line tool I hoped it to be - achoo is a text user interface.
Since my purpose is to get away from the user interface and menus,
achoo doesn't help me.

2) Build on achoo.  I looked a bit into it, but it doesn't seem
trivial to tap into the ruby framework.  At least not for me,
considering my limited ruby knowledge.

3) Tap directly into the database.  That seems like the easiest route
for me - but then again, it's safest to do the registrations through
the application to make sure all the business logics, data integrity
checks, permission checks etc passes.

4) Edit the PHP to make some easy-to-use API - but then again, I don't
feel like diving into the PHP code.

5) Stupid-ugly bash-script using curl, wget or similar to push through
registrations through a bare minimum of HTTP requests.  This was
eventually chosen - KISS, curl+bash+perl is installed on nearly any
linux-box, and the achievo web-UI is considered to be quite static.
Since option handling is messy in bash, I'm passing options through
environment variables ... stupid-ugly :-)

6) As #5, but use perl or python.  I was seriously considering to make
a switch when I was half-way through implementing #5 - but then again,
there is a risk that I'd have to make dependencies using extra
libraries.  Also, python is my favorite ... but with python now it's
slightly non-trivial to make sure the script works on all distros due
to the python2/python3 incompatibility (no guarantee that python3 is
installed, no guarantee that #!/usr/bin/python will invoke python2,
and no guarantee that the symlink /usr/bin/python2 exists ...)
... plus that I have some bad memories using library methods on https,
certificates, basic-auth etc in python2.

