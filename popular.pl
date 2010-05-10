#!/usr/bin/perl -w

#This script scrapes grooveshark's popular song feed to create a widget with the 50 current top songs on their site and post the widget to Posterous.

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
$creds[0] =~ s/\n//g;
$creds[1] =~ s/\n//g;

getopts('p');

my $ua = LWP::UserAgent->new;
 $ua->timeout(10);
 $ua->env_proxy;
 $ua->credentials("posterous.com:80",'Posterous',$creds[0],$creds[1]);

my $url = URI->new( "http://api.grooveshark.com/feeds/1.0/popular/songs.rss" );
 
my $songinfo = XMLin($ua->get($url)->content);
my @songs;

foreach my $row (@{$songinfo->{channel}->{item}}){
  print $row->{title} . "\n" . $row->{link}."\n\n";
  if ($opt_p){ my $tinyurl = URI->new( "http://www.tinysong.com/b/$row->{title}" );
  $tinyurl->query_form( 'format' => 'json');
  my $songid = from_json($ua->get($tinyurl)->decoded_content);
  print $songid->{SongID}."\n";
  push(@songs, $songid->{SongID});}
}
if ($opt_p){
my $songids = join(',', @songs);
my $htmlresults = qq~ <object width="400" height="400"><param name="movie" value="http://listen.grooveshark.com/widget.swf" /><param name="flashvars" value="hostname=cowbell.grooveshark.com&amp;songIDs=$songids&amp;style=metal&amp;p=0" /><embed src="http://listen.grooveshark.com/widget.swf" type="application/x-shockwave-flash" wmode="window" width="250" height="40" flashvars="hostname=cowbell.grooveshark.com&amp;songIDs=$songids&amp;style=metal&amp;p=0"></embed>~;
#  $htmlresults =~ s/([^\\])(["`])/$1\\$2/g;

my $posturl = URI->new( "http://posterous.com/api/newpost");
  $posturl->query_form(  # And here the form data pairs:
   'site_id' => 1251953,
   'autopost' => 0,
   'title' => "Streaming Top Songs Playlist via Grooveshark.com.",
   'body' => $htmlresults,
   'tags' => "Popular,Streaming,#musicmonday,grooveshark,Playlist"
  );

my $data = XMLin($ua->get($posturl)->content);
 my $posterousurl = $data->{post}->{url};

#foreach my $n (@songinfo) {
#        print $n . "\n";}
#
print $posterousurl . "\n";}
