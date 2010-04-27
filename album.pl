#!/usr/bin/perl -w

# See tiny.pl for a longer description.  This script reads search terms from the# command-line and creates a playlist widget, which is then automatically 
# posted to Posterous. There is one command line option '-l' which allows you 
# to specify the limit to the number of songs returned (the max according to 
# apidocs.tinysong.com is 32.)

require LWP::UserAgent;
use URI;
use Getopt::Std;
use XML::Simple;
use JSON;

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
 if ($opt_l) { $url->query_form( 'limit' => $opt_l, 'format' => 'json');}
 else { $url->query_form( 'format' => 'json');}
 
my @songids;
my $songinfo = from_json($ua->get($url)->decoded_content);

foreach my $line (@{$songinfo}) {
  push(@songids, $line->{SongID});}

my $string = join(',',@songids);

 my $htmlresults = qq~ <object width="400" height="400"><param name="movie" value="http://listen.grooveshark.com/widget.swf" /><param name="flashvars" value="hostname=cowbell.grooveshark.com&amp;songIDs=$string&amp;style=metal&amp;p=0" /><embed src="http://listen.grooveshark.com/widget.swf" type="application/x-shockwave-flash" wmode="window" width="400" height="400" flashvars="hostname=cowbell.grooveshark.com&amp;songIDs=$string&amp;style=metal&amp;p=0"></embed>~;

my $posturl = URI->new( "http://posterous.com/api/newpost");
  $posturl->query_form(  # And here the form data pairs:
   'site_id' => 1251953,
   'autopost' => 0,
   'title' => "Playlist results for '$request'",
   'body' => $htmlresults,
  );

my $data = XMLin($ua->get($posturl)->content);
while( my ($k, $v) = each %{$data}) {
  print "$k : $v\n";}

my $posterousurl = $data->{post}->{url};

print $posterousurl . "\n";
