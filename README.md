This is primary made for employees of Redpill-Linpro.  
This may be useful for others using achievo as well, though it may
need some tweaking.

For support and ideas, contact tobias@redpill-linpro.com, or /msg
tobias at irc.redpill-linpro.com

KNOWN BUGS
==========

* Many default values are specific for the setup at Redpill Linpro, and some may even be specific to my department.
* The default URL seems to be protected by basic auth when accessing from outside the office/VPN.  Configuring a ACHIEVO_URL with username/password may help.
* Charset problems - avoid using non-ascii letters or it may appear as WTF-8.
* very sloppy support for phase ID - it has to be specified as a numeric ID.  Automatic selection of phase ID works for projects with only one phase ID.
* very sloppy support for billable percentage - for Redpill Linpro, set ACHIEVO_BILLPERCENTID=3 for "0% billable" and leave the default (1) for "100% billable".
* Not very well tested - always follow up by checking the Web UI that the registration has gone correctly through

General thought
===============

Our Achievo is annoyingly slow.  I've tried to look a bit on it - it
does queries like "what projects have you been working on during the
last two months?" on a big table with all the time registrations just
to populate the select-box with available projects.  This could
probably be fixed by caching on the application side ... maybe
upgrading to the latest available version from upstream would help
... but that's not my cup of tea, someone else eventually has to look
into that.

Even if achoo would have been fast, it's a significant overhead to
register hours - depending on how fine-grained and exact one wants the
registrations to be.

The "Timesheet" view in the webui is handy for reviewing and editing
all time registrations for a full day.  I think it would be a useful
workflow to have the timesheet prefilled with information gathered
from other tools and then manually look through and edit.

Wanted
======

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

