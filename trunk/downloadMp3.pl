#!/usr/bin/perl -w

#This script uses the echonest.com developper's api to look up download URLs for .mp3 files that correspond to a given artist.  Uses wget.

require LWP::UserAgent;
use URI;
use Getopt::Std;
use XML::Simple;
use HTTP::Request::Common;
use JSON;

getopts('pl:');
my $request = shift;
while (@ARGV) {$request .= " " . shift;}

my $ua = LWP::UserAgent->new;
 $ua->default_header('HTTP_REFERER' => 'http://tinysong.posterous.com');
 $ua->timeout(20);
 $ua->env_proxy;

if (not (defined $opt_l)){$opt_l = 20;}

my $artisturl = URI->new( "http://developer.echonest.com/api/search_artists");
  $artisturl->query_form(  # And here the form data pairs:
   'api_key' => 'FHJKAB4MCVIWD0WDF',
   'version' => 3,
   'query' => $request,
   'rows' => 1,
   'bucket' => 'audio',
  );

my $artistdata = XMLin($ua->get($artisturl)->content);
 
my $artistid = $artistdata->{artists}->{artist}->{id};

my $rows = $artistdata->{artists}->{artist}->{audio}->{found};

#This grabs the first 15 rows of audio information (starting with row 0).

while (my ($key, $value) = each (%{$artistdata->{artists}->{artist}->{audio}->{doc}})){
 while (my ($k, $v) = each (%{$value})){
  if ($k eq 'url'){
   push (@audio,$v);
  }
 }
}

#This grabs all the following sets of 15 rows until the row count is reached.

for (my $i=15; $i<=$rows; $i+=15){
 my $audiourl = URI->new('http://developer.echonest.com/api/get_audio'); 
 $audiourl->query_form(
  'api_key' => 'FHJKAB4MCVIWD0WDF',
  'version' => 3,
  'id' => $artistid,
  'start' => $i,
 );
 my $audiodata = XMLin($ua->get($audiourl)->content);
 print Dumper($audiodata);
 while (my ($key, $value) = each (%{$audiodata->{results}->{doc}})){
  while (my ($k, $v) = each (%{$value})){
   if ($k eq 'url'){
    push (@audio,$v);
   }
  }
 }
}

#This first prints the URL then attempts to download it via wget.  It includes the -c and -t flags to avoid endlessly trying to download files, and allows you to continue where you left off if there is an error.

for (my $i=0;$i<=$#audio;$i++){
 print "$i. $audio[$i]\n";
 `wget -t 5 -c "$audio[$i]"`;
}

exit;
