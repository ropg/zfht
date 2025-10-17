|         |                                |         |
|---------|--------------------------------|---------|
| zfht(8) | System Administration Commands | zfht(8) |

<div class="manual-text">

<div class="section Sh">

# <a href="#NAME" class="permalink">NAME</a>

zfht - Zone file change detection, automates nameserver mgmt, follows
\$INCLUDEs, runs user scripts

</div>

<div class="section Sh">

# <a href="#SYNOPSIS" class="permalink">SYNOPSIS</a>

**zfht** \[**-d**\] \[**-a**\] \[**-w**\] \[**-t**\] \[**-z**
*ZONESDIR*\] \[**-s** *ZONESSUBDIR*\] \[*files*...\]

</div>

<div class="section Sh">

# <a href="#DESCRIPTION" class="permalink">DESCRIPTION</a>

**zfht** (Zone File Helper Tool) helps you manage DNS zone files for use
with authoritative name servers such as **nsd** or **bind**.

**zfht** is ran from a directory holding zone files and optional subdirs
with included snippets and detects changes to zone files or any files
they recursively \$INCLUDE. **zfht** uses its companion tool
**zfht-update-serial** to automatically increase any affected SOA serial
numbers and can execute user-specified scripts to automate the
management of common DNS nameserver setups. Companion tool **zfht-sign**
completely automates the key generation and signing of records for
DNSSEC.

In **file mode**, if one or multiple files are given on the command
line, it considers these files modified, figures out all the files that
depend on them, as well as files they in turn depend on. If a user
script is provided, it will be ran for each modified zone file.

In **timestamp mode**, when no files are given, **zfht** uses a file
stored after a previous invocation to auto-detect which files were
modified since that file was created. Since that file contains a list of
zone files, it can also see which zone files have newly appeared and
disappeared since its previous invocation. **zfht** can run user scripts
for addition, removal or modification of zones. If there is no previous
state file yet, you can either run with **-a** to process everything as
newly appeared, or run with **-w** once to store the current state
without processing anything.

In either mode, you can specify -t to have **zfht** touch any zone files
affected by changes to included files, which allows some name server
software to automatically reload affected domains.

</div>

<div class="section Sh">

# <a href="#ZONESDIR_DIRECTORY" class="permalink">ZONESDIR DIRECTORY</a>

Unless you use -z or set the ZONESDIR environment variable, **zfht**
assumes it is invoked from a directory that is the parent to any zone
files or snippets, and the root of any \$INCLUDE directives in your zone
files. Unless you specify ZONESSUBDIR (see below), it assumes the **zone
files** for the domains your name server is authoritative for are the
only files directly in that directory itself. These files should either
have the names of the various DNS zones (domains) served, or the names
of the zones followed by *.zone*. One or multiple subdiretories can
contain **include files**, snippets to be included in these zone files.
These includes should use relative paths, starting at ZONESDIR.

</div>

<div class="section Sh">

# <a href="#ZONESSUBDIR_DIRECTORY" class="permalink">ZONESSUBDIR
DIRECTORY</a>

If you keep your zone files in a subdirectory of ZONESDIR, you can set
it with ZONESSUBDIR variable, or using -s. Specify a relative path,
starting from ZONESDIR. Only zone files for domains you are
authoritative for should be in this directory directly.

</div>

<div class="section Sh">

# <a href="#OPTIONS" class="permalink">OPTIONS</a>

<a href="#d" class="permalink"><strong>-d</strong></a>  
Dry run. Shows zfht's view on what files changed and the various
dependencies, as well as what would be done without executing any
commands or changing any files.

<a href="#a" class="permalink"><strong>-a</strong></a>  
Process all files (timestamp mode only).

<a href="#w" class="permalink"><strong>-w</strong></a>  
Write the current state file (*.zfht/lastrun*) and exit without
processing. Useful to initialize timestamp mode on first use.

<a href="#t" class="permalink"><strong>-t</strong></a>  
Touch zone files that depend on changed files to bump modification
times.

<a href="#z" class="permalink"><strong>-z</strong></a>  
Specify ZONESDIR (see above)

<a href="#s" class="permalink"><strong>-s</strong></a>  
Specify ZONESSUBDIR (see above)

</div>

<div class="section Sh">

# <a href="#TIMESTAMP_MODE" class="permalink">TIMESTAMP MODE</a>

If invoked without any filenames, **zfht** runs in timestamp mode. On
first use (when *.zfht/lastrun* does not yet exist), **zfht** does not
modify anything by default. It merely tells you to initialize with
**-w** or **-a**

<div class="Bd-indent">

- run with **-w** once to write *.zfht/lastrun* (stores the current set
  of zone files) and exit; or
- run with **-a** to process all files.

</div>

If instead the *lastrun* file is found, a number of internal lists are
compiled. (Use the dry run mode to have zfht output these lists.)

<a href="#CHANGED" class="permalink"><strong>CHANGED</strong></a>  
files that were changed becauee they were specified or because they were
modified after the creation of the lastrun file.

<a href="#INCLUDERS" class="permalink"><strong>INCLUDERS</strong></a>  
files that were not themselves changed, but that include one or more
modified files, even if the modified file is an include of an include.

<a href="#INCLUDED" class="permalink"><strong>INCLUDED</strong></a>  
files not previously listed that were included by files that were
modified, or by files that included them.

<a href="#ADDED_ZONEFILES"
class="permalink"><strong>ADDED_ZONEFILES</strong></a>  
zone files that appeared since the last run.

<a href="#AFFECTED_ZONEFILES"
class="permalink"><strong>AFFECTED_ZONEFILES</strong></a>  
zone files that were already there but either modified since *lastrun*
was last written or affected by a modification in one of the included
files, recursively.

<a href="#DELETED_ZONEFILES"
class="permalink"><strong>DELETED_ZONEFILES</strong></a>  
zone files that were there last time, but that are gone now.

**zfht** will then run **zfht-update-serial** **-q** *file* for all
affected files (**CHANGED**, **INCLUDERS** and **INCLUDED**). This finds
any files with SOA serial numbers (both in single and multi-line
formats) and increases these numbers. The **-q** option causes nothing
to be printed when no SOA serial number is found. The format is
YYYYMMDDSSm where SS is increased from 01. See the man page for
**zfht-update-serial** for further details.

If the **-t** option was specified, **zfht** will then touch all files
on the **INCLUDERS** list, so that any file that depends on a changed
file will now itself be recognized as changed. If, for example, you use
**nsd** as your name server, this is enough for **nsd-control**
**reload** to recognize changed zones and reload them.

If an executable file called *addzone* exists in the *.zfht*
subdirectory, it will be called for each zone that appeared since the
last invocation. The zone name and the file name will be the first and
second argument. (They are mostly the same in our case, but the zone
name will have *.zone* removed if you name your zone files like that.)
The same holds true for the user scripts *modzone* and *delzone*,
executed for zones that were modified and for those for whom the zone
file has disappeared.

Lastly, if no errors were returned by any of the external scripts, the
new list of zone files is written to the *lastrun* file. If **-w** was
used, only the state is written and no processing occurs.

</div>

<div class="section Sh">

# <a href="#FILE_MODE" class="permalink">FILE MODE</a>

**File mode** is much like timestamp mode, except you specify any
modified files on the command line. (All the files have to specified
relative to the zone file directory.) The same lists for **INCLUDERS**
and **INCLUDED** are then compiled, you can use **-t** to touch all
**INCLUDERS**, and the *modzone* script is called for modified zones.
But there's no tracking of added or deleted domains, and no reading or
writing of the *lastrun* timestamp file.

</div>

<div class="section Sh">

# <a href="#EXAMPLE_USING_-tell" class="permalink">EXAMPLE USING -tell</a>

Let's assume we're running an nsd nameserver on FreeBSD, for example in
a FreeBSD jail. Install the nsd package and make sure *zfht*,
*zfht-update-serial* and *zfht-sign* are somewhere in your PATH. (Also
copy the files from *man/man8/* to */usr/local/share/man/man8* if you
want the manual pages.) By default, your zone files are in
*/usr/local/etc/nsd/master*. Let's say we create a subdirectory
*includes* underneath that, and make some files for snippets that are
used in many domains.

<a href="#master/includes/dns"
class="permalink"><strong>master/includes/dns</strong></a>  

<div class="Bd-indent">

    @       IN  SOA ns0.example.nl. hostmaster.example.nl. 2025100801 3600 900 1209600 3600


            IN  NS  ns0.example.nl.


            IN  NS  ns1.example.nl.

</div>

<a href="#master/includes/mail"
class="permalink"><strong>master/includes/mail</strong></a>  

<div class="Bd-indent">

    @       IN  MX  0 mail.example.nl.


            IN  TXT "v=spf1 mx ~all"
    *       IN  MX  0 mail.example.nl.


            IN  TXT "v=spf1 mx ~all"
    key1._domainkey IN TXT "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEB <etc etc>

</div>

<a href="#master/includes/webproxy"
class="permalink"><strong>master/includes/webproxy</strong></a>  

<div class="Bd-indent">

    @       IN  A       95.216.43.110
    *       IN  A       95.216.43.110

</div>

Now for any domains that the nameserver serves and for which you just
want to send/receive all the mail on the mail server and all the web
traffic on the proxy, the zone files are all the same and they simply
read:

<a href="#master/somedomain.com"
class="permalink"><strong>master/somedomain.com</strong></a>  

<div class="Bd-indent">

    $INCLUDE "master/includes/dns"
    $INCLUDE "master/includes/mail"
    $INCLUDE "master/includes/webproxy"

</div>

zfht just keeps the zones you serve consistent and correct. It's easiest
if you tell it where the zone files are.

<a href="#add" class="permalink">add to <strong>~/.profile</strong>:</a>  

<div class="Bd-indent">

    export ZONESDIR=/usr/local/etc/nsd
    export ZONESSUBDIR=master

</div>

If you never add or delete domains or hardcode each one in your
*nsd.conf*, all you need to do is run **zfht -t** followed by
**nsd-control reload** after each time you make a change. With the -t
option, **zfht** will simply touch any file that depends on a file that
was changed since the last time it was invoked, so nsd-control can
reload all the zones with changes.

</div>

<div class="section Sh">

# <a href="#LOADING_ZONES_DYNAMICALLY_USING_NSD" class="permalink">LOADING
ZONES DYNAMICALLY USING NSD</a>

Now assuming we generate an ssh key and put it's pubkey in
authorized_keys on the ns1 secondary server(/jail), we can put the
following in three scripts in a newly created .zfht subdirectory and
make them executable.

<a href="#master/.zfht/addzone"
class="permalink"><strong>master/.zfht/addzone</strong></a>  

<div class="Bd-indent">

    #!/bin/sh
    nsd-control addzone $1 master
    ssh root@ns1.example.nl nsd-control addzone $1

</div>

<a href="#master/.zfht/modzone"
class="permalink"><strong>master/.zfht/modzone</strong></a>  

<div class="Bd-indent">

    #!/bin/sh
    nsd-control reload $1

</div>

<a href="#master/.zfht/delzone"
class="permalink"><strong>master/.zfht/delzone</strong></a>  

<div class="Bd-indent">

    #!/bin/sh
    nsd-control delzone $1
    ssh root@ns1.example.nl nsd-control delzone $1

</div>

Now if we invoke **zfht -a**, all zones will be added to the nameverver
and to the secondary. After any changes, simply run **zfht** without
arguments. Now adding a new domain is as simply as putting the file in
*master*. Deleting a domain it is as simple as deleting the file.

</div>

<div class="section Sh">

# <a href="#SEE_ALSO" class="permalink">SEE ALSO</a>

**zfhd-update-serial**(8), **zfhd-sign**(8)

</div>

<div class="section Sh">

# <a href="#AUTHOR" class="permalink">AUTHOR</a>

Rop Gonggrijp, 2025

</div>

</div>

|              |                       |
|--------------|-----------------------|
| October 2025 | Zone File Helper Tool |
