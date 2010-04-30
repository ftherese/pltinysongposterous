#!/usr/bin/perl -w

# Uses the Tinysong and Posterous APIs to embed a player for a song search. 
# Requires a creds.txt file which contains exactly two lines, with the username # on the first line, and the password on the second in plaintext.
# by modifying the posterous query settings, you can post to your own 
# whatever.posterous.com blog.

# This search takes a string from the command line which may contain any 
# information pertaining to song title, artist name, or album title.  Tinysong 
# automatically finds the most popular song that corresponds to the search and 
# returns, among other details, the SongID that will be used in the creation of # the widget.  The widget is then posted to Posterous in the 'body' form 
# element.  I don't really know why, but there has to be a space between the 
# "body=" and the "<object width=" otherwise posterous says the content is 
# invalid... oh well.  Finally, Posterous returns some XML to describe the 
# success or failure of the post.  There are other variables available (see 
# the Posterous API for details on the returned XML) but I simply grab the 
# short url and print it.  By default, this script does not set to autopost 
# on Posterous to your other connected sites - you can easily enable that by 
# changing autopost to '1'.  Enjoy! 


require LWP::UserAgent;
use URI;
use XML::Simple;
use JSON;

my @creds;
open (CREDS, "creds.txt") || die "fill in your creds.txt.";
while (my $line = <CREDS>){
 push(@creds, $line);}
close(CREDS);
$creds[0] =~ s/\n//g;
$creds[1] =~ s/\n//g;

my $ua = LWP::UserAgent->new;
 $ua->timeout(10);
 $ua->env_proxy;
 $ua->credentials("posterous.com:80",'Posterous',$creds[0],$creds[1]);

my $request = shift;
 while (@ARGV) {$request .= " " . shift;}
 my $url = URI->new( "http://www.tinysong.com/b/$request" );
 $url->query_form('format' => 'json');
 
my $songinfo = from_json($ua->get($url)->decoded_content);

my $htmlresults = qq~ <object width="250" height="40"><param name="movie" value="http://listen.grooveshark.com/songWidget.swf" /><param name="flashvars" value="hostname=cowbell.grooveshark.com&amp;songID=$songinfo->{SongID}&amp;style=metal&amp;p=0" /><embed src="http://listen.grooveshark.com/songWidget.swf" type="application/x-shockwave-flash" wmode="window" width="250" height="40" flashvars="hostname=cowbell.grooveshark.com&amp;songID=$songinfo->{SongID}&amp;style=metal&amp;p=0"></embed>~;

#  $htmlresults =~ s/([^\\])(["`])/$1\\$2/g;

my $posturl = URI->new( "http://posterous.com/api/newpost");
  $posturl->query_form(  # And here the form data pairs:
   'site_id' => 1251953,
   'autopost' => 0,
   'title' => "$songinfo->{SongName} - $songinfo->{ArtistName}",
   'body' => $htmlresults,
   'tags' => "$songinfo->{SongName},$songinfo->{ArtistName},$songinfo->{AlbumName}"
  );

my $data = XMLin($ua->get($posturl)->content);
my $posterousurl = $data->{post}->{url};

while( my ($k, $v) = each %{$songinfo} ) {
        print "$k : $v.\n";}

print $posterousurl . "\n";
