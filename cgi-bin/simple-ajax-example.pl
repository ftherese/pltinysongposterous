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

my $ua = LWP::UserAgent->new;
 $ua->timeout(10);
 $ua->env_proxy;

my $c = new CGI::Compress::Gzip;
 print $c->header();
 
my $request = param('w');
my $playlist = param('p');
my $url = URI->new( "http://www.tinysong.com/s/$request" );
 if ($playlist eq "playlist") { $url->query_form( 'limit' => '32', 'format' => 'json'); }
 else { $url->query_form( 'limit' => '1', 'format' => 'json');}

#print qq~<b>Loading...</b><br/>~;

my @songids, $htmlresults;
 my $songinfo = from_json($ua->get($url)->decoded_content);
 foreach my $line (@{$songinfo}) {
  push(@songids, $line->{SongID});}
 my $string = join(',',@songids);
    
if ($playlist eq "playlist") {

$htmlresults = qq~<input id="posterous" name="posterous" type="button" value="Post to tinysong.posterous.com" onclick='JavaScript:xmlhttpPost("/cgi-bin/album.pl", "posterousinfo"); return false;' ><br/><object width="400" height="400"><param name="movie" value="http://listen.grooveshark.com/widget.swf" /><param name="flashvars" value="hostname=cowbell.grooveshark.com&amp;songIDs=$string&amp;style=metal&amp;p=0" /><embed src="http://listen.grooveshark.com/widget.swf" type="application/x-shockwave-flash" wmode="window" width="400" height="400" flashvars="hostname=cowbell.grooveshark.com&amp;songIDs=$string&amp;style=metal&amp;p=0"></embed></object>~;

print $htmlresults;}

else {

$htmlresults = qq~<input id="posterous" name="posterous" type="button" value="Post to tinysong.posterous.com" onclick='JavaScript:xmlhttpPost("/cgi-bin/tiny.pl", "posterousinfo"); return false;' ><br/><object width="250" height="40"><param name="movie" value="http://listen.grooveshark.com/songWidget.swf" /><param name="flashvars" value="hostname=cowbell.grooveshark.com&amp;songIDs=$string&amp;style=metal&amp;p=0" /><embed src="http://listen.grooveshark.com/songWidget.swf" type="application/x-shockwave-flash" wmode="window" width="250" height="40" flashvars="hostname=cowbell.grooveshark.com&amp;songIDs=$string&amp;style=metal&amp;p=0"></embed></object>~;

print $htmlresults;
}
