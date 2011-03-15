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
use HTML::Entities;
#use HTML::TableExtract;
use HTTP::Request::Common;
use XML::Simple;

my $request = param("w");
my $similar = param("s");
my $c = new CGI::Compress::Gzip;
print $c->header();

my ($content, $artisturl, $artistdata, $artistid, $requestArtistName);
my $ua = LWP::UserAgent->new;
 $ua->default_header('HTTP_REFERER' => 'http://tinysong.posterous.com');  
 $ua->timeout(20);

if ($similar eq "similar"){
 $artisturl = URI->new( "http://developer.echonest.com/api/v4/artist/search");
  $artisturl->query_form(  # And here the form data pairs:
   'api_key' => 'FHJKAB4MCVIWD0WDF',
#   'version' => 3,
   'name' => $request,
   'results' => 1,
   'format' => 'xml',
  );
 $artistdata = XMLin($ua->get($artisturl)->content);

 while (my ($key, $value) = each(%{$artistdata->{artists}->{artist}}) ){
  if ($key eq 'id'){
   $artistid = $value;
  }
  elsif ($key eq 'name'){
   print '<b>'."Input interpreted as: ".'</b><i>'.$value.'</i></br></br>';
   $requestArtistName = $value;
  }
 }

 my $getSimilarUrl = URI->new( "http://developer.echonest.com/api/v4/artist/similar");
  $getSimilarUrl->query_form(
   'api_key' => 'FHJKAB4MCVIWD0WDF',
   'name'      => $request,
   'format'  => 'xml',
#  'rows'    => '12',
#  'version' => 3,
#  'bucket'  => 'audio',
  );

 my $getSimilarData = XMLin($ua->get($getSimilarUrl)->decoded_content);

 while (my ($key, $value) = each (%{$getSimilarData->{artists}->{artist}})){
  print "$key".'</br>';
 }
}
else {
 my $url = URI->new( "http://www.tinysong.com/s/$request" );
 $url->query_form( 'limit' => '32', 'format' => 'json');
 $response = $ua->get($url);
 $content = $response->decoded_content;
 my $json = from_json($content);

#print Dumper($json);

 foreach my $song (@{$json}){
  print '<a href='. "\"$song->{Url}\"" . ' target="_blank" >' . encode_entities($song->{SongName}) . '</a><br/>' . encode_entities($song->{ArtistName})." - ". encode_entities($song->{AlbumName}) . '</br>';}
}