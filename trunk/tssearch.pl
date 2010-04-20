#!/usr/bin/perl -w

# See tiny.pl for a longer description.  This script reads search terms from the# command-line and  returns the top results from tinysong.com.
# There is one command line option '-l' which allows you 
# to specify the limit to the number of songs returned (the max according to 
# apidocs.tinysong.com is 32.)

require LWP::UserAgent;
require HTML::Parser;
use URI;
use Getopt::Std;

getopts('l:');

my $ua = LWP::UserAgent->new;
 $ua->timeout(10);
 $ua->env_proxy;

my $request;
 foreach my $n (@ARGV) {$request .= $n . " ";}
 $request =~ s/ $//;
 print $request . "\n";
 my $url = URI->new( "http://www.tinysong.com/s/$request" );
 if ($opt_l) { $url->query_form( 'limit' => $opt_l);}
 
my $string ='';
my @songinfo = split(/\n/, $ua->get($url)->decoded_content);

#For some reason, the tinysong api returns the last two results without a new li
#ne separator.  This is certainly a bug, and will probably be fixed eventually. 
#In the meantime, these next three lines take care of the problem.

##BEGIN WORKAROUND

 my @lastTwoElementsFix = split(/;http/, pop(@songinfo));
 $lastTwoElementsFix[1] = "http" . $lastTwoElementsFix[1];
 push(@songinfo, @lastTwoElementsFix);

##END WORKAROUND

my $counter = 1;
foreach my $line (@songinfo) {
 my @temp=split(/; /, $line);
 $temp[6] =~ s/;//;
 print "$counter. '$temp[2]' by $temp[4] from the album '$temp[6]'\n\t$temp[0].\n";
 $counter++;
 $line=\@temp;}
