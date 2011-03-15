#!/usr/bin/perl -w

BEGIN {
    my $base_module_dir = (-d '/home/ftherese/perl' ? '/home/ftherese/perl' : ( getpwuid($>) )[7] . '/perl/');
    unshift @INC, map { $base_module_dir . $_ } @INC;
}

require LWP::UserAgent;
use URI;
use JSON;
use CGI qw(param);
use CGI::Compress::Gzip qw~:standard~;
use HTTP::Request::Common;
use XML::Simple;

my $ua = LWP::UserAgent->new;
 $ua->timeout(100);
 $ua->env_proxy;
 $ua->default_header('HTTP_REFERER' => 'http://tinysong.posterous.com');

my $c = new CGI::Compress::Gzip;
 print $c->header();
 
my $request = param('w');
my $playlist = param('p');
my $similar = param('s');

my (@songids, $htmlresults, $songinfo, $string, @images, $artistid, @artists, $imagedata, $imagestr);

my $url = URI->new( "http://www.tinysong.com/s/$request" );

if (($playlist eq "playlist") || ($similar eq 'similar')){ # For Playlists only (any similar search is considered a playlist search)
 $artisturl = URI->new( "http://developer.echonest.com/api/v4/artist/search");
  $artisturl->query_form(  # And here the form data pairs:
   'api_key' => 'FHJKAB4MCVIWD0WDF',
#   'version' => 3,
   'name' => $request,
   'results' => 1,
   'bucket' => 'images',
   'format' => 'xml',
  );
 $artistdata = XMLin($ua->get($artisturl)->content);
 $imagedata = $artistdata->{artists}->{artist}->{images};
 $imagedata = [$imagedata] unless ref $imagedata eq 'HASH';
 foreach my $image (@{$imagedata}){
#  print '<b>'.$image->{url}.'</b>';
  push(@images,'<li><a href="'.$image->{url}.'" title="Click to see full image." target="_blank" ><img src="'.$image->{url}.'" /></a><div><img src="'.$image->{url}.'" /></div></li>');
 }
 $imagestr = '<div class="slideshow"><ul>' . (join('',@images)) . '</ul></div>';

 while (my ($key, $value) = each(%{$artistdata->{artists}->{artist}}) ){
  if ($key eq 'id') {
   $artistid = $value;
  }
  elsif ($key eq 'name') {
   $requestArtistName = $value;
  }
 }

 if ($similar eq "similar") { # Playlist of Similar ARTISTS

  my $getSimilarUrl = URI->new( "http://developer.echonest.com/api/v4/artist/similar");
   $getSimilarUrl->query_form(
    'api_key' => 'FHJKAB4MCVIWD0WDF',
    'id'      => $artistid,
    'results'    => '20',
    'format'  => 'xml',
#    'version' => 3,
#   'bucket'  => 'images',
   );

  my $getSimilarData = XMLin($ua->get($getSimilarUrl)->decoded_content);
  my @artists;

  while (my ($key, $value) = each (%{$getSimilarData->{artists}->{artist}})){
   push(@artists, $key);
   my $tinyurl = URI->new( "http://www.tinysong.com/b/" . $key);
    $tinyurl->query_form( 'format' => 'json');
   my $songid = from_json($ua->get($tinyurl)->decoded_content);
   push(@songids, $songid->{SongID});
  }
 }
 else { # Regular Playlist 
  $url->query_form( 'limit' => '32', 'format' => 'json'); 
 }
}
else { # Single Song
 $url->query_form( 'limit' => '1', 'format' => 'json');
}

if ($similar ne 'similar'){
 $songinfo = from_json($ua->get($url)->decoded_content);
# $songinfo = [$songinfo] unless ref $songinfo eq 'ARRAY';
 foreach my $line (@{$songinfo}) {
  push(@songids, $line->{SongID});
  push(@artists, $line->{ArtistName});
 }
 $string = join(',',@songids);
 @images = ();
 $artisturl = URI->new( "http://developer.echonest.com/api/v4/artist/search");
  $artisturl->query_form(  # And here the form data pairs:
   'api_key' => 'FHJKAB4MCVIWD0WDF',
#   'version' => 3,
   'name' => $artists[0],
   'results' => 1,
   'bucket' => 'images',
   'format' => 'xml',
  );
# print $artisturl;
 $artistdata = XMLin($ua->get($artisturl)->content);
 $imagedata = $artistdata->{artists}->{artist}->{images};
#  print ref $imagedata;
# print $imagedata;
 $imagedata = [$imagedata] unless ref $imagedata eq 'ARRAY';
# print '</br>' . ref $imagedata . $imagedata . '</br>';
 foreach my $image (@{$imagedata}){
#  print 'Hello World';
#  print '<b>'.$image->{url}.'</b>';
  push(@images,'<li><a href="'.$image->{url}.'" title="Click to see full image." target="_blank" ><img src="'.$image->{url}.'" /></a><div><img src="'.$image->{url}.'" /></div></li>');
 }
 $imagestr = '<div class="slideshow"><ul>' . (join('',@images)) . '</ul></div>';
}
else {
 $string = join(',',@songids);
}   
if (($playlist eq "playlist") || ($similar eq 'similar')) {

$htmlresults = qq~<input id="posterous" name="posterous" type="button" value="Post to tinysong.posterous.com" onclick='JavaScript:xmlhttpPost("/cgi-bin/album.pl", "posterousinfo"); return false;' ><br/>$imagestr<object width="400" height="400"><param name="movie" value="http://listen.grooveshark.com/widget.swf" /><param name="flashvars" value="hostname=cowbell.grooveshark.com&amp;songIDs=$string&amp;style=metal&amp;p=0" /><embed src="http://listen.grooveshark.com/widget.swf" type="application/x-shockwave-flash" wmode="window" width="400" height="400" flashvars="hostname=cowbell.grooveshark.com&amp;songIDs=$string&amp;style=metal&amp;p=0"></embed></object>~;

print $htmlresults;}

else {

$htmlresults = qq~<input id="posterous" name="posterous" type="button" value="Post to tinysong.posterous.com" onclick='JavaScript:xmlhttpPost("/cgi-bin/tiny.pl", "posterousinfo"); return false;' ><br/>$imagestr<object width="250" height="40"><param name="movie" value="http://listen.grooveshark.com/songWidget.swf" /><param name="flashvars" value="hostname=cowbell.grooveshark.com&amp;songIDs=$string&amp;style=metal&amp;p=0" /><embed src="http://listen.grooveshark.com/songWidget.swf" type="application/x-shockwave-flash" wmode="window" width="250" height="40" flashvars="hostname=cowbell.grooveshark.com&amp;songIDs=$string&amp;style=metal&amp;p=0"></embed></object>~;

print $htmlresults;
}