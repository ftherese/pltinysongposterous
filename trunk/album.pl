#!/usr/bin/perl -w

# See tiny.pl for a longer description.  This script reads search terms from the# command-line and creates a playlist widget, which is then automatically 
# posted to Posterous. There is one command line option '-l' which allows you 
# to specify the limit to the number of songs returned (the max according to 
# apidocs.tinysong.com is 32.)

require LWP::UserAgent;
require HTML::Parser;
use URI;
use Getopt::Std;
use XML::Simple;

my @creds;
open (CREDS, "creds.txt") || die "fill in your creds.txt.";
while (my $line = <CREDS>){
 push(@creds, $line);}
close(CREDS);
$creds[0] =~ s/\n//;
$creds[1] =~ s/\n//;

getopts('l:');

my $ua = LWP::UserAgent->new;
 $ua->timeout(10);
 $ua->env_proxy;
 $ua->credentials("posterous.com:80",'Posterous',$creds[0],$creds[1]);

my $request;
 foreach my $n (@ARGV) {$request .= $n . " ";}
 $request =~ s/ $//;
 print $request;
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

 foreach my $line (@songinfo) {
  my @temp=split(/; /, $line);
  $string .= $temp[1] . ",";
  $line=\@temp;}
 $string =~ s/,$//;
 print $string;

 my $htmlresults = qq~ <object width="400" height="400"><param name="movie" value="http://listen.grooveshark.com/widget.swf" /><param name="flashvars" value="hostname=cowbell.grooveshark.com&amp;songIDs=$string&amp;style=metal&amp;p=0" /><embed src="http://listen.grooveshark.com/widget.swf" type="application/x-shockwave-flash" wmode="window" width="400" height="400" flashvars="hostname=cowbell.grooveshark.com&amp;songIDs=$string&amp;style=metal&amp;p=0"></embed>~;

my $posturl = URI->new( "http://posterous.com/api/newpost");
  $posturl->query_form(  # And here the form data pairs:
   'site_id' => 1251953,
   'autopost' => 1,
   'title' => "Playlist results for '$request'",
   'body' => $htmlresults,
  );

my $data = XMLin($ua->get($posturl)->content);
print $data;
 my $posterousurl = $data->{post}->{url};

print $posterousurl . "\n";
