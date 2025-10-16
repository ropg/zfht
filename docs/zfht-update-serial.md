|                       |                                |                       |
|-----------------------|--------------------------------|-----------------------|
| zfht-update-serial(8) | System Administration Commands | zfht-update-serial(8) |

<div class="manual-text">

zfht-update-serial - Update SOA serial number in DNS zone files

<div class="section Sh">

# <a href="#SYNOPSIS" class="permalink">SYNOPSIS</a>

**zfht-update-serial** \[**-q**\] *zone_file*

</div>

<div class="section Sh">

# <a href="#DESCRIPTION" class="permalink">DESCRIPTION</a>

**zfht-update-serial** automatically updates the SOA serial number in
DNS zone files. Supports both single-line and multi-line SOA record
formats. New serial number is in format YYYYMMDDNN where NN is 01 unless
a previous serial with today's date was found, in which case the current
serial number is incremented by one.

**zfht-update-serial** comes bundled with **zfht** to manage changes and
dependencies in zone files and **zfht-sign** to completely automate
DNSSEC key generation and zone signing.

</div>

<div class="section Sh">

# <a href="#OPTIONS" class="permalink">OPTIONS</a>

<a href="#q" class="permalink"><strong>-q</strong></a>  
Quiet mode. Suppress error messages and exit without error when no SOA
record is found.

</div>

<div class="section Sh">

# <a href="#SOA_FORMAT_SUPPORT" class="permalink">SOA FORMAT SUPPORT</a>

The script handles SOA record on a single line:

<div class="Bd-indent">

    example.com. 900 IN SOA ns1.example.com. admin.example.com. 2025010101 7200 3600 86400 300

</div>

But also spread out over multiple lines like this:

<div class="Bd-indent">

    example.com. 900 IN SOA ns1.example.com. admin.example.com. (


        2025010101    ; serial


        7200          ; refresh


        3600          ; retry


        86400         ; expire


        300           ; minimum
    )

</div>

</div>

<div class="section Sh">

# <a href="#EXAMPLE" class="permalink">EXAMPLE</a>

<div class="Bd-indent">

    zfht-update-serial -q example.com
    Updated serial from 2025100601 to 2025100602 in example.com

</div>

</div>

<div class="section Sh">

# <a href="#FILES" class="permalink">FILES</a>

zfht-update-serial modifies the zone file in place using sed.

</div>

<div class="section Sh">

# <a href="#SEE_ALSO" class="permalink">SEE ALSO</a>

**zfht**(8), **zfht-sign**(8)

</div>

<div class="section Sh">

# <a href="#AUTHOR" class="permalink">AUTHOR</a>

Rop Gonggrijp, 2025

</div>

</div>

|              |                       |
|--------------|-----------------------|
| October 2025 | Zone File Helper Tool |
