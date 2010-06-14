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
use HTTP::Request::Common;
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
 $ua->default_header('HTTP_REFERER' => 'http://tinysong.posterous.com');
 $ua->credentials("posterous.com:80",'Posterous',$creds[0],$creds[1]);

my $request = param("w");
my $similar = param("s");

my $c = new CGI::Compress::Gzip;
print $c->header();

my ($artistdata, $artisturl, @songids, $htmlresults, $songinfo, $string, $title, $tags, $artistid, $requestArtistName, @images, $bodytext);

if ($similar eq 'similar') {
 
 $artisturl = URI->new( "http://developer.echonest.com/api/search_artists");
  $artisturl->query_form(  # And here the form data pairs:
   'api_key' => 'FHJKAB4MCVIWD0WDF',
   'version' => 3,
   'query' => $request,
   'rows' => 1,
   'bucket' => 'images',
  );

$artistdata = XMLin($ua->get($artisturl)->content);

foreach my $image (@{$artistdata->{artists}->{artist}->{images}}){
 push(@images,'<a href="'.$image->{url}.'" ><img src="'.$image->{url}.'" /></a>');
}

while (my ($key, $value) = each(%{$artistdata->{artists}->{artist}}) ){
 if ($key eq 'id') {
  $artistid = $value; 
 }
 elsif ($key eq 'name') {
# print '<b>'."Input interpreted as: ".'</b><i>'.$value.'</i></br></br>';
  $requestArtistName = $value;
 }
}

 my $getSimilarUrl = URI->new( "http://developer.echonest.com/api/get_similar");
  $getSimilarUrl->query_form(
   'api_key' => 'FHJKAB4MCVIWD0WDF',
   'id'      => $artistid,
   'rows'    => '20',
   'version' => 3,
#  'bucket'  => 'audio',
  );

 my $getSimilarData = XMLin($ua->get($getSimilarUrl)->decoded_content);
 my @artists;

 while (my ($key, $value) = each (%{$getSimilarData->{similar}->{artist}})){
# print $key.'</br>';
  push(@artists, $key);
  my $tinyurl = URI->new( "http://www.tinysong.com/b/" . $key);
   $tinyurl->query_form( 'format' => 'json');
  my $songid = from_json($ua->get($tinyurl)->decoded_content);
# print $songid->{SongName}." by ".$songid->{ArtistName}.'</br>';
  push(@songids, $songid->{SongID});
 }
 $title = "$requestArtistName: Similar Artist Playlist via Grooveshark.com and Echonest.com.";
 my $artistTags = join(',',@artists);
 $tags =  "Similar to $requestArtistName,Streaming,grooveshark,Playlist,$artistTags";
 
 $bodytext = $tags;
 $bodytext =~ s/,/, /g;
}
else {
 my $url = URI->new( "http://www.tinysong.com/s/$request" );
 $url->query_form( 'limit' => '32', 'format' => 'json');

 $songinfo = from_json($ua->get($url)->decoded_content);

 my (@artistinfo, @titles, @albums);
 foreach my $line (@{$songinfo}) {
   push(@songids, $line->{SongID});
   push(@artistinfo, $line->{ArtistName});
   push(@titles, $line->{SongName});
   push(@albums, $line->{AlbumName});
 }
 $title = "Playlist results for '$request'";
 $tags = "Playlist," . (join(',',@titles)) . ",". (join(',',@artistinfo)) . "," . (join(',',@albums));
 my @body;
 for (my $i = 0; $i <= $#artistinfo; $i++){
  push(@body, '<p>'."\"$titles[$i]\", by " . '<i>' . $artistinfo[$i] . '</i>' . " from $albums[$i]." . '</p>');
 }
 $bodytext = join('', @body);
 $artisturl = URI->new( "http://developer.echonest.com/api/search_artists");
  $artisturl->query_form(  # And here the form data pairs:
   'api_key' => 'FHJKAB4MCVIWD0WDF',
   'version' => 3,
   'query' => $artistinfo[0],
   'rows' => 1,
   'bucket' => 'images',
  );

 $artistdata = XMLin($ua->get($artisturl)->content);

 foreach my $image (@{$artistdata->{artists}->{artist}->{images}}){
  push(@images,'<a href="'.$image->{url}.'" ><img src="'.$image->{url}.'" /></a>');
 }
}

$string = join(',', @songids);

$htmlresults = qq~ $images[0]<object width="400" height="400"><param name="movie" value="http://listen.grooveshark.com/widget.swf" /><param name="flashvars" value="hostname=cowbell.grooveshark.com&amp;songIDs=$string&amp;style=metal&amp;p=0" /><embed src="http://listen.grooveshark.com/widget.swf" type="application/x-shockwave-flash" wmode="window" width="400" height="400" flashvars="hostname=cowbell.grooveshark.com&amp;songIDs=$string&amp;style=metal&amp;p=0"></embed></object><p>$bodytext</p>~;

my $posturl = URI->new( "http://posterous.com/api/newpost");
  $posturl->query_form(  # And here the form data pairs:
   'site_id' => 1251953,
   'autopost' => 0,
   'title' => $title,
   'body' => $htmlresults,
   'tags' => $tags 
  );

my $data = XMLin($ua->get($posturl)->content);

my $posterousurl = $data->{post}->{url};

print '<br/>Listen to ' . $title .' <a href=' . "\"$posterousurl\" target=\"_parent\" >" . $posterousurl . '</a>';