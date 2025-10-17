|              |                                |              |
|--------------|--------------------------------|--------------|
| zfht-sign(8) | System Administration Commands | zfht-sign(8) |

<div class="manual-text">

<div class="section Sh">

# <a href="#NAME" class="permalink">NAME</a>

zfht-sign - Automate key generation and zone file signing for DNSSEC

</div>

<div class="section Sh">

# <a href="#SYNOPSIS" class="permalink">SYNOPSIS</a>

**zfht-sign \[-q\] *zone* *zone_file***

</div>

<div class="section Sh">

# <a href="#DESCRIPTION" class="permalink">DESCRIPTION</a>

**zfht-sign** lets you generate keys and DNSSEC sign zone files without
you having to learn arcane stuff and messing around. It tries to do what
I believe is the right thing: it signs zone files using the
ECDSAP256SHA256 algorithm, automatically generates KSK (Key Signing Key)
and ZSK (Zone Signing Key) if they don't exist and creates a signed
version of the zone.

</div>

<div class="section Sh">

# <a href="#DEPENDENCIES" class="permalink">DEPENDENCIES</a>

**zfht-sign** depends on **dnssec-keygen** and **dnssec-signzone**,
which come with the **bind nameserver**. They are part of the bind tools
and need to be installed and in the PATH on the system. Depending on
your flavor of unix, the package might be called **bind9utils**,
**bind-tools**, **bind-utils**, or the tools might be part of the main
**bind** package. (Note that I would recommend using the **nsd**
nameserver made by NLnet Labs over using bind, we just use bind's tools
for dnssec.)

</div>

<div class="section Sh">

# <a href="#THE_ZONESDIR_DIRECTORY" class="permalink">THE ZONESDIR
DIRECTORY</a>

**zfht-sign** defines a directory it calls *ZONESDIR* that has a *keys*
and a *signed* subdirectory for key and signed zone files respectively.
If these do not exist, they will be created. If nothing is specified it
assumes it is started from the directory it is supposed to use. You can
use the -z option or set the ZONESDIR environment variable to ensure it
finds/creates keys and writes files where you want them.

</div>

<div class="section Sh">

# <a href="#SIGNING_A_ZONE" class="permalink">SIGNING A ZONE</a>

If you invoke **zfht-sign** with a zone (domain) name and and a zone
file as arguments, it will see in the *keys* directory if it can find a
Zone Signing Key and a Key Signing Key for this zone. If keys are not
found, they will be generated. After that's done, the zone file will be
parsed, all the records will be signed, and a new signed zone file will
be created in the *signed* sub-directory.

</div>

<div class="section Sh">

# <a href="#OPTIONS" class="permalink">OPTIONS</a>

<a href="#q" class="permalink"><strong>-q</strong></a>  
Quiet mode. Suppress output from the dnssec-keygen and dnssec-signzone
commands.

</div>

<div class="section Sh">

# <a href="#ARGUMENTS" class="permalink">ARGUMENTS</a>

<a href="#zone" class="permalink"><em>zone</em></a>  
The zone name (e.g., example.com)

<a href="#zone_file" class="permalink"><em>zone_file</em></a>  
Path to the unsigned zone file, either absolute or relative from
ZONESDIR.

</div>

<div class="section Sh">

# <a href="#OUTPUT_FILES" class="permalink">OUTPUT FILES</a>

<a href="#signed/_zone_"
class="permalink"><em>signed/&lt;zone&gt;</em></a>  
The signed zone file

<a href="#keys/ksk/_zone_.ds"
class="permalink"><em>keys/ksk/&lt;zone&gt;.ds</em></a>  
DS record for delegation, provide to your domain registrar.

<a href="#keys/ksk/_zone_.private"
class="permalink"><em>keys/ksk/&lt;zone&gt;.private</em></a>  
KSK private key

<a href="#keys/ksk/_zone_.key"
class="permalink"><em>keys/ksk/&lt;zone&gt;.key</em></a>  
KSK public key

<a href="#keys/zsk/_zone_.private"
class="permalink"><em>keys/zsk/&lt;zone&gt;.private</em></a>  
ZSK private key

<a href="#keys/zsk/_zone_.key"
class="permalink"><em>keys/zsk/&lt;zone&gt;.key</em></a>  
ZSK public key

</div>

<div class="section Sh">

# <a href="#EXAMPLES" class="permalink">EXAMPLES</a>

Sign a zone wthout showing tool output:

<div class="Bd-indent">

**zfht-sign -q example.com master/example.com**

</div>

Typical output:

<div class="Bd-indent">

**Generating KSK key for example.com**  
**Generating ZSK key for example.com**  
**Signed zone example.com**

</div>

</div>

<div class="section Sh">

# <a href="#TEMPORARY_FILES" class="permalink">TEMPORARY FILES</a>

*/tmp/temp\_\<zone\>\_\<\$\$\>*  
Temporary zone file (automatically cleaned up)

*/tmp/keys\_\<\$\$\>*  
Temporary key generation directory (automatically cleaned up)

</div>

<div class="section Sh">

# <a href="#SEE_ALSO" class="permalink">SEE ALSO</a>

**zfht**(8), **zfht-update-serial**(8), **dnssec-keygen**(8),
**dnssec-signzone**(8)

</div>

<div class="section Sh">

# <a href="#AUTHOR" class="permalink">AUTHOR</a>

Rop Gonggrijp, 2025

</div>

</div>

|              |                       |
|--------------|-----------------------|
| October 2025 | Zone File Helper Tool |
