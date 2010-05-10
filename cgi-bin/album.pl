#!/usr/bin/perl -w

# See tiny.pl for a longer description.  This script reads search terms from the# command-line and creates a playlist widget, which is then automatically 
# posted to Posterous. There is one command line option '-l' which allows you 
# to specify the limit to the number of songs returned (the max according to 
# apidocs.tinysong.com is 32.)

BEGIN {
    my $base_module_dir = (-d '/home/ftherese/perl' ? '/home/ftherese/perl' : ( getpwuid($>) )[7] . '/perl/');
    unshift @INC, map { $base_module_dir . $_ } @INC;
}

require LWP::UserAgent;
use URI;
use XML::Simple;
use JSON;
use CGI qw(param);
use CGI::Compress::Gzip qw~:standard~;

my @creds;
open (CREDS, "creds.txt") || die "fill in your creds.txt.";
while (my $line = <CREDS>){
 push(@creds, $line);}
close(CREDS);
$creds[0] =~ s/\n//;
$creds[1] =~ s/\n//;

# getopts('l:');

my $ua = LWP::UserAgent->new;
 $ua->timeout(10);
 $ua->env_proxy;
 $ua->credentials("posterous.com:80",'Posterous',$creds[0],$creds[1]);

my $request =  param("w");
my $c = new CGI::Compress::Gzip;
print $c->header();
 my $url = URI->new( "http://www.tinysong.com/s/$request" );
 $url->query_form( 'limit' => '32', 'format' => 'json');
 
my @songids;
my $songinfo = from_json($ua->get($url)->decoded_content);

foreach my $line (@{$songinfo}) {
  push(@songids, $line->{SongID});}

my $string = join(',',@songids);

my $htmlresults = qq~ <object width="400" height="400"><param name="movie" value="http://listen.grooveshark.com/widget.swf" /><param name="flashvars" value="hostname=cowbell.grooveshark.com&amp;songIDs=$string&amp;style=metal&amp;p=0" /><embed src="http://listen.grooveshark.com/widget.swf" type="application/x-shockwave-flash" wmode="window" width="400" height="400" flashvars="hostname=cowbell.grooveshark.com&amp;songIDs=$string&amp;style=metal&amp;p=0"></embed></object>~;

my $tags = $request;
$tags =~ s/ /,/g;
my $posturl = URI->new( "http://posterous.com/api/newpost");
  $posturl->query_form(  # And here the form data pairs:
   'site_id' => 1251953,
   'autopost' => 0,
   'title' => "Playlist results for '$request'",
   'body' => $htmlresults,
   'tags' => "Playlist," . $request 
  );

my $data = XMLin($ua->get($posturl)->content);

my $posterousurl = $data->{post}->{url};

print '<br/>Listen to ' . "Playlist results for '$request' at " .'<a href=' . "\"$posterousurl\" target=\"_parent\" >" . $posterousurl . '</a>';
