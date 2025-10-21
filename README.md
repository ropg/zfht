# zfht - Zone File Helper Tool


**I found DNS server operation a bit too prone to small mistakes, so I wrote some things I needed for myself. They're probably useful for other people, so I polished them a bit further and here they are: `zfht` tracks `$INCLUDE` dependencies in DNS zone files and make sure all the zones affected by changes get their serial numbers increased and get reloaded. Now you can just create and delete a few files, and `zfht` will run user scripts for addition, modification and removal of domains. `zfht-sign` automaticaly generates keys and signs zone files for DNSSEC without you having to do arcane stuff by hand.**

## DNS server operation is needlessly cumbersome

### `$INCLUDE` includes complexity

I have my own cheap server running FreeBSD in a rack somewhere in Finland, and I run my own services for a small number of domains, which includes running my own authoritative DNS servers, for which I use NSD by NLnet Labs.

Even with a small number of domains, things get repetitive. And using included files, the obvious solution, can get confusing and labor-intensive.

Let's look at an example: I use `$INCLUDE` statements in my zone files for the standard stuff about my DNS servers, my mail server and web proxy. Here's the zone file for `gonggri.jp`, my own domain:

**`master/gonggri.jp`**
```
$INCLUDE "master/includes/dns"
$INCLUDE "master/includes/mail"
$INCLUDE "master/includes/webproxy"

_atproto.rop IN TXT "did=did:plc:nl75g3377bgp44ehuvmbdxqa"
```

Essentially, this says: all mail for this domain and direct subdomains goes to the mail server, and all other traffic gets handled by the web proxy. The only record specific to this domain is one I used to prove to Bluesky that I control the domain so I can have the [**@rop.gonggri.jp**](https://rop.gonggri.jp) handle. The included files then contain records common to most of the domains I host:

**`master/includes/dns`**
```
@   IN  SOA ns4.rop.nl. hostmaster.rop.nl. 2025101305 3600 900 1209600 3600
    IN  NS  ns4.rop.nl.
    IN  NS  ns3.rop.nl.
```

**`master/includes/mail`**
```
@   IN  MX  0 mail.rop.nl.
    IN  CAA 0 issue "letsencrypt.org"
    IN  TXT "v=spf1 mx ~all"
*   IN  MX  0 mail.rop.nl.
    IN  CAA 0 issue "letsencrypt.org"
    IN  TXT "v=spf1 mx ~all"

key1._domainkey IN TXT "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADEz ... etc
```

**`master/includes/webproxy`**
```
@   IN  CAA     0 issue "letsencrypt.org"
    IN  A       65.109.148.215
*   IN  CAA     0 issue "letsencrypt.org"
    IN  A       65.109.148.215
```

Some other domains I host have e-mail go to Gmail, or handle their own web traffic. Now when I modify one of the zone files, I have to remember to increase the serial number and reload that zone on the DNS server. When I add a domain, I have to add it to the server, and to the secondary server. And when I modify a dependency, I have to check which files it is included from and reload all those domains, and not forget to increase the serial number. In other words, even for a small setup, it's way too easy to forget stuff and find out the next morning that something is broken. No wonder `$INCLUDE` is underappreciated and everyone is repeating everything 100 times in their zone files.

### DNSSEC is just not easy enough to set up

DNSSEC allows your computer to know that the answer from a DNS server actually came from a computer authorized to tell you the IP number for that specific domain name. But odds are that other than PayPal and your bank, no services you connect to regularly use it. Your domain registrar probably supports you providing them with a public key hash so you can use the corresponding secret key to sign your DNS responses. Wouldn't it be nice to enable DNSSEC for your domains too?

Sure, you can figure out the command line options for generating Key Signing Keys and Zone Signing Keys, using the proper algorithms to not have way-too-long keys and signatures for these small DNS UDP packets. But it's arcane and you can spend an entire evening figuring things out. The default naming of the key files makes it, IMHO, needlessly hard to automate things or understand what is where. It's almost as if the current tools were designed to make sure almost nobody uses DNSSEC.

## Introducing `zfht`, the Zone File Helper Tool

### Installation

```
git clone https://github.com/ropg/zfht && cd zfht && sudo make install
```

`zfht`, `zfht-update-serial` and `zfht-sign` will be installed to `$PREFIX/sbin`, and their man pages to `$PREFIX/share/man/man8`, where `PREFIX` defaults to `/usr/local`. To install to `/usr/sbin` and `/usr/share/man/man8`, use `make install PREFIX=/usr`

#### Installing bind tools for DNSSEC using `zfht-sign`

If you want to use `zfht-sign` to serve your DNS records with DNSSEC signatures, you'll need to install two tools: `dnssec-keygen` and `dnssec-signzone`. They come with the nameserver `bind`. In most distributions, they are part of a supplementary tools package. On FreeBSD, the package is called `bind-tools`, on Ubuntu it's called `bind9utils`. They might also come bundled as `bind-utils` or they might ship with the main `bind` package for your distro.

*(Note that while `zfht-sign` uses `bind`'s tools for generating keys, I actually very much recommend using [`NSD`](https://nlnetlabs.nl/projects/nsd/about/), made by NLnet labs, as your actual nameserver.)*

### Specifying where your files are

By default, `zfht` assumes that the zone files it operates on are in the current directory, and any included files are specified as relative paths to files in one or more directories underneath that. However, you can set two environment variables to specify where things are in your setup.

#### `ZONESDIR`

Root of included files' relative paths for when `zfht` tracks dependencies. `zfht-sign` will create sub-directories `keys` and `signed` here.

#### `ZONESSUBDIR`

Sub-directory of `ZONESDIR`, specified as relative path. This is where your zone files live, and any included files live in one or more sub-directories underneath it. Defaults to the zone files being in `ZONESDIR` itself.

#### Da Rulez:

* Only zone files in `ZONESSUBDIR`, must be named as the name (domain) of the zone, optionally followed by `.zone`
* Included files in dir(s) underneath `ZONESSUBDIR`, relative paths only, starting at `ZONESDIR` (not `ZONESSUBDIR`)
* No spaces in zone filenames or filenames of included files. `zfht` will exit with an error message if any filenames in or under `ZONESSUBDIR` contain spaces.

### Usage

#### `zfht-update-serial [-q] <zone_file>`

Simplest of the tools, meant to be used by `zfht`, but you can also use it stand-alone. Increases the SOA serial number in a file you specify. Serial numbers use the de-facto standard format `YYYYMMDDSS`, meaning today's zero-padded date, followed by a two-digit increasing number. If it finds today's date already there, it will increase `SS`, otherwise it will use today's date followed by `01`. Handles single line and multi-line SOA record formats. The `-q` option makes it exit silently when no SOA record is found in a file.

#### `zfht-sign [-q] [-z <zonesdir>] <zone> <zone_file>`

`zfht-sign` creates zone files that contain all the DNS records for the zone, as well as all the DNSSEC signature records. The resulting file can be served just like the unsigned file would, and even if you do not a have DNSSEC delegation set up with  your registrar, everything will work as normal. To do this it uses the private key of a ZSK (Zone Signing Key) pair, the public key of which is itself signed with the private part of a KSK (Key Signing Key). The public part of that is hashed and published as a DS record by your registrar so verifyers can see that DNS records for your zone indeed came from you.

The best part is you won't have to know anything about this. You just provide a zone name and a file (absolute path or relative from `ZONESDIR`), and it will generate any keys it needs. Here's an example:

`zfht-sign example.com master/example.com` would create the following directories and files under `ZONESDIR`:

`keys/zsk/example.com.key`
`keys/zsk/example.com.private`
`keys/ksk/example.com.key`
`keys/ksk/example.com.private`
`keys/ksk/example.com.ds`
`signed/example.com`

All you need to do is tell your nameserver to use the resulting file in `signed` instead of the one in `master` to be serving the signatures along with your other DNS records. To get the benefits of DNSSEC, you then take the line from `keys/ksk/example.com.ds` and enter that in the system your domain registrar has probably set up for this.

The `-q` option is meant for use in scripts and mutes all output from `dnssec-keygen` and `dnssec-signzone`, only showing error messages or single-line success message from `zfht-sign` itself.

#### `zfht [-d] [-a] [-t] [-w] [-z <zonesdir>] [-s <zonessubdir>] [files...]`

`zfht` without any files specified will use its own timestamp, written on the last invocation, to figure out which files have changed and tracks up- and downstream dependencies from there. Changes any SOA serial numbers in files affected by changes and runs user scripts for added, removed and modified zones if provided. 

`-d` : dry run, doesn't change anything, just shows what it would have done
`-a` : assume all files in ZONESSUBDIR have changed
`-t` : touch any zone files that depend on changed file(s), recursively
`-w` : just write the timestamp file and exit. Used for initializing `zfht`

*(See the examples below and much should become clear to you. This README does not cover every last aspect of using `zfht`. Install and use `man zfht` for more information.)*

### Examples

For the examples we'll assume a FreeBSD system and the use of the NSD nameserver, but you probably get the gist and can adapt the examples to your use case. The nameserver in these examples is in its own FreeBSD jail, and we do everything in that jail as root, so there's no need for chroot operation of NSD. We follow the defaults, so the nameserver files are all in `/usr/local/etc/nsd` and the zone files are in `master` under that. The zone files are named as the zone (without .zone extension) and any included files that make life easier (see introduction at beginning of ths README) are in `master/includes`, or any other directory under `master`.

#### Simplest use of `zfht`

For any use of zfht, first we would set (and add to `~/.profile`)

```sh
export ZONESDIR=/usr/local/etc/nsd
export ZONESSUBDIR=master
```

For teh simple usage, let's create an alias:
`alias reload='zfht -t && nsd-control reload'`

Next, to initialize, you run `zfht -w` once to write a file `master/.zfht/lastrun`. The modification time of that file marks the time the last time `zfht` was ran.

You can now edit your zone files and any included files to your heart's content, no need to update any serial numbers. When you run `reload`, this is what happens:

* `zfht` scans your `master` directory and creates three lists internally.
  * The first, called `CHANGED`, unsurprisingly holds all the files in and under `master` that were changed since the previous time `zfht` was invoked.
  * The next, called `INCLUDERS`, holds files that were not themselves changed but that include a changed file or a file that includes one, recursively.
  * The last list is called `INCLUDED` and it holds any files not on the two previous lists, but that were themselves included, recursively, by files on the first two lists.
* `zfht` then uses `zfht-update-serial` to increase any SOA serial numbers it finds in any of the files on any of these lists.
* `zfht` then touches (because we specified the `-t` option) any zone files in `master` that were not themselves changed, but that depend on another file that did.
* `zhft` writes to the `master/.zfht/lastrun` timestamp file.
* `nsd-control reload` without any zone specified looks for zones whose zone file has been modified since the last time that zone was reloaded. Since that now also includes files that depend on modified files, and any serial numbers involved have been increased, you're good to go.

*(At any time, instead of running `reload`, you can run `zfht -d` for a dry run. it will show you the three lists of files and everything it would have done if you hadn't specified `-d`)*

#### Fully automated DNS-heaven

Wouldn't it be nice to serve DNSSEC records for all zones automatically? And since NSD can load new zones dynamically with `nsd-control addzone`, how about if adding or removing a zone was as simple as adding or deleting a file? Here's how you would set that up:

* Let's assume our primary nameserver jail has IP `1.2.3.4` and your secondary nameserver is another FreeBSD jail with NSD somewhere else, at IP-address `5.6.7.8`. (I prefer to use IP-numbers for any communication between DNS servers, so nothing depends on DNS to bootstrap or fix DNS.)

* You can use identical config files on primary and secondary. Use the file below, adding any specific bits you might need. Where it says `<INSERT YOUR SECRET HERE>`, insert the output of `head -c 32 /dev/urandom | base64`

**`/usr/local/etc/nsd.conf`**
```
server:
    zonesdir: /usr/local/etc/nsd
    logfile: "/var/log/nsd.log"

key:
    name: "transferkey"
    algorithm: hmac-sha256
    secret: "<INSERT YOUR SECRET HERE>"

remote-control:
    control-enable: yes
    control-interface: "/var/run/nsd/nsd.ctl"

pattern:
    name: "master"
    zonefile: "signed/%s"
    notify: 5.6.7.8 transferkey
    provide-xfr: 5.6.7.8 transferkey

pattern:
    name: "slave"
    allow-notify: 1.2.3.4 transferkey
    request-xfr: AXFR 1.2.3.4 transferkey
```

* Note that I don't really like using the network port for `nsd-control`. You have to create single-purpose keys, distribute them, there's an extra IP port exposed, meh. Everything works fine locally and without all this complexity if you set a named pipe as `control-interface`. For doing things on the secondary server, we'll use old trusted `ssh`. So on your primary nameserver, generate an ssh keypair for root with `ssh-keygen`, put the public key in `authorized_keys` on the secondary jail, `PermitRootLogin yes` in secondary's `sshd_config` and restart sshd there. Test and add secondary to `known_hosts` on primary by logging into secondary from primary with `ssh root@5.6.7.8`.

  * (Naturally it will all work perfectly well using the network-capabilities of `nsd-control`. In that case just modify the scripts below accordingly.)

* Back to our primary server. Create a directory `.zfht` under `master` and put the following three files in it:

**`addzone`**
```
#!/bin/sh

zfht-sign -q $1 master/$1 || exit 1
echo "Adding zone $1"
nsd-control addzone $1 master >/dev/null
ssh root@5.6.7.8 nsd-control addzone $1 slave >/dev/null
```

**`modzone`**
```
#!/bin/sh

zfht-sign -q $1 master/$1 || exit 1
printf "nsd-control reload $1: "
nsd-control reload $1
```

**`delzone`**
```
#!/bin/sh

echo "Deleting zone $1"
nsd-control delzone $1 >/dev/null
rm signed/$1 keys/zsk/$1.key keys/zsk/$1.private
rm keys/ksk/$1.key keys/ksk/$1.private keys/ksk/$1.ds
ssh root@5.6.7.8 nsd-control delzone $1 >/dev/null
```

* Make these files executable with `chmod a+x *zone`

* Run `nsd-control reconfig` on primary and secondary

* Run `zfht -a` on primary. Any existing zone files in `master` will now have corresponding DNSSEC signed files in `signed` and the server will serve these. Any missing zones will be added on the secondary and zone transfers initiated.

* **And presto, you're in DNS-heaven!** After any change in the master directory, simply run `zfht` to update all the appropriate SOA serial numbers and run the right scripts. Adding a domain is now just adding a minimal file with some `$INCLUDE`s.

* The DS record for your registrar is in `keys/ksk/<zone>.ds`. First use [this](https://dnssec-debugger.verisignlabs.com/) tool to verify everything is set up correctly on your end. It should show all green checkmarks except for `No DS records found'. Then set up the DS record at your registrar and ... **Poof! You are serving proper DNSSEC!** (Use tool to test again.)

* To re-sign all zones, do `zfht -a`. To rotate all the Zone Signing Keys, simply do: `rm keys/zsk/* && zfht -a` (You can put these in cron to do them regularly.)

* To rotate a zone's KSK (do people really do that?), delete the zone's key files from `keys/ksk` and run `zfht master/<zone>`.

    * **CAVEAT**: Note that that breaks DNSSEC until you update the DS record at your registrar. One could sign the ZSK with old and new key to prevent this brief outage, but `zfht` does not provide for that yet.
