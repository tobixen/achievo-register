#!/usr/bin/python3

__version__ = '0.01'

from optparse import OptionParser
import os, time, subprocess

## Runlevel definition:
## 1: fetch data from source
## 2: initial transformations - should be indempotent - should be done before manual editing
## 3: post-editing transformations - should be done after all c's are removed.  does b->h-converting and keyword->achievo ID converting etc.  Should be indempotent.
## 4: convert to achievo commands.

def run(runlevel, fromdate, todate, logfile, plugins_dir):
    if runlevel == '1':
        with open(logfile, 'w') as logfh:
            for fn in os.listdir(plugins_dir):
                if fn.startswith(runlevel+'-'):
                    subprocess.check_call(["%s/%s" % (plugins_dir, fn), fromdate, todate], stdout=logfh)
        subprocess.check_call(["/usr/bin/git", "add", logfile])
        subprocess.check_call(["/usr/bin/git", "commit", "-m", "autocommit: file sourced from plugins"])
    else:
        for fn in os.listdir(plugins_dir):
            if fn.startswith(runlevel+'-'):
                os.rename(logfile, logfile+'.bak')
                with open(logfile, 'w') as logfh:
                    with open(logfile+'.bak', 'r') as oldlogfh:
                        subprocess.check_call(["%s/%s" % (plugins_dir, fn)], stdout=logfh, stdin=oldlogfh)
        if not 'nothing to commit, working directory clean' in str(subprocess.check_output(["/usr/bin/git", "status", logfile])):
            subprocess.check_call(["/usr/bin/git", "add", logfile])
            subprocess.check_call(["/usr/bin/git", "commit", "-m", "autocommit: file modified by plugins, runlevel %s" % runlevel])

if __name__ == '__main__':
    parser = OptionParser(version=__version__)
    parser.add_option('--plugins-dir', dest='plugins_dir', help='Directory to look for plugins.  (default: ${HOME}/achievo-register/enabled-plugins.d/')
    parser.add_option('-f', '--logfile', dest='logfile', help='Work hours log file (default:  ${logdir}/worklog.${from_date})', metavar='FILE')
    parser.add_option('-d', '--logdir', dest='logdir', help='Work hours log dir', default=("%s/worklogs/" % os.environ['HOME']))
    parser.add_option('-b', '--from-date', dest='from_date', help='starting date (timestamp) for work log (default: yesterday)')
    parser.add_option('-e', '--to-date', dest='to_date', help='stop date (timestamp) for work log (default: end of yesterday)')
    parser.add_option('-l', '--runlevels', dest='runlevels', help='which runlevels - 1=read data from sources, 2-4=do various transformations.  default=runlevel on previous run plus one')
    parser.add_option('-i', '--interactive', dest='interactive', action='store_true', help='interactive run - means all runlevels, and usage of $EDITOR')
    #parser.add_option('--b-to-h', '--convert-to-hours' ...)
    #parser.add_option('--find-project-codes', ...)


    (options, args) = parser.parse_args()

    ## sane defaults
    logdir = options.logdir
    os.chdir(logdir)
    todate = options.to_date or time.strftime('%F')
    if not options.from_date:
        try:
            with open("%s/watermark" % logdir, 'r') as wmf:
                fromdate = wmf.readline().strip()
        except:
            fromdate = time.strftime('%F', time.localtime(time.time()-3600*24))
    else:
        fromdate = options.from_date
    logfile = options.logfile or ("%s/worklog.%s" % (logdir, fromdate))
    plugins_dir = options.plugins_dir or ("%s/achievo-register/enabled-plugins.d/" % os.environ['HOME'])
    runlevels = options.runlevels
    
    while True:
        if not runlevels and not os.access(logfile, os.R_OK):
            runlevels = '1,2'
            print("assuming run levels 1 and 2 since file doesn't exist")
        elif not runlevels:
            greplowercase = subprocess.getstatusoutput('/usr/bin/grep -E '+"'"+'> \![bhc] '+"' "+logfile)
            if greplowercase[0] == 0:
                runlevels = '3'
                print("assuming run level 3 since file does exist, but contains one or more lower case commands")
                if greplowercase[1].count("\n")<5:
                    print(greplowercase[1])
            elif not runlevels:
                grepregister = subprocess.getstatusoutput('/usr/bin/grep achievo-register.sh '+logfile)
                if grepregister[0] != 0:
                    runlevels = '4'
                    print("assuming run level 4")
                else:
                    with open(logfile, 'r') as logfile:
                        for line in logfile:
                            line = line.strip()
                            (ret, output) = subprocess.getstatusoutput(line)
                            if ret:
                                print("ERROR: this command failed:\n%s\n%s" % (line, "output: %s"%output if output else ""))
                    print("HOURS REGISTERED! :-)")
                    if not options.from_date:
                        with open("%s/watermark" % logdir, 'w') as wmf:
                            wmf.write(todate)
                    break
            runlevels = runlevels.split(',')

        for runlevel in runlevels:
            run(runlevel, fromdate, todate, logfile, plugins_dir)

        if options.interactive:
            subprocess.call([os.getenv('EDITOR', os.getenv('VISUAL', 'vi')), logfile])
            if not 'nothing to commit, working directory clean' in str(subprocess.check_output(["/usr/bin/git", "status", logfile])):
                subprocess.check_call(["/usr/bin/git", "add", logfile])
                subprocess.check_call(["/usr/bin/git", "commit", "-m", "autocommit: file edited, after runlevel %s" % runlevel])
        else:
            break
        if runlevels == '4':
            break
        runlevels = None
