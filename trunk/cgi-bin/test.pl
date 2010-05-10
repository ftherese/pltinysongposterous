#!/usr/bin/perl

BEGIN {
    my $base_module_dir = (-d '/home/ftherese/perl' ? '/home/ftherese/perl' : ( getpwuid($>) )[7] . '/perl/');
    unshift @INC, map { $base_module_dir . $_ } @INC;
}

use CGI qw(param);
use CGI::Compress::Gzip qw~:standard~;
use LWP::UserAgent;
use JSON;
#use Data::Dumper;
use URI;

my $request = param("w");
my $c = new CGI::Compress::Gzip;
print $c->header();

my $ua = LWP::UserAgent->new;
my $url = URI->new( "http://www.tinysong.com/s/$request" );
$url->query_form( 'limit' => '32', 'format' => 'json');

my $response = $ua->get($url);
my $content = $response->content;
my $json = from_json($content);

#print Dumper($json);

foreach my $song (@{$json}){
 print '<a href='. "\"$song->{Url}\"" . ' target="_blank" >' . $song->{SongName} . '</a><br/>' . "$song->{ArtistName} - $song->{AlbumName}" . '</br>';}
