#!/usr/bin/perl -w
########################################################################
#@HDR@	$Id$
#@HDR@		Copyright 2025 by
#@HDR@		Christopher Caldwell
#@HDR@		P.O. Box 401, Bailey Island, ME 04003
#@HDR@		All Rights Reserved
#@HDR@
#@HDR@	This software comprises unpublished confidential information
#@HDR@	of the copyright holder and may not be used, copied or made
#@HDR@	available to anyone, except in accordance with the license
#@HDR@	under which it is furnished.
########################################################################

use strict;

package cpi_player;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( player );
use lib ".";

use cpi_file qw( first_in_path echodo );

#__END__
1;

#########################################################################
#	Go find player and play the supplied files.			#
#	Tries far harder than it should.				#
#########################################################################
my $best_audio;
sub player
    {
    my $argp = ( ref($_[0]) eq "HASH" ? shift(@_) : {} );
    my @to_play_list = @_;
    my $best_audio;
    foreach my $to_play ( @to_play_list )
	{
	if( $to_play || 1 )	# if $to_play is audio
	    {
	    if( ! $best_audio )
		{
	        if( $argp->{player} )
		    { $best_audio = $argp->{player}; }
		else
		    { $best_audio = &first_in_path(
			"mpv -really-quiet -quiet",	#a media player
			"mplayer -really-quiet -quiet",	#Movie Player for Linux
			"paplay",	#Play back or record raw or encoded audio streams on a P...
			"play -q",	#Sound eXchange, the Swiss Army knife of audio manipulation
			"aviplay",	#QT-based movie player
			"esdplay",	#attempt to reroute audio device to esd
			"ffplay",	#FFplay media player
			"lqtplay",	#simple quicktime movie player for X11.
			"madplay",	#decode and play MPEG audio stream(s)
			"mpg123",	#play audio MPEG 1.0/2.0/2.5 stream (layers 1, 2 and 3)
			"ogg123",	#plays Ogg, and FLAC files
			"pia",		#play media files
			"pragha",	#A lightweight music player, forked of Consonance Music ...
			"vlc"		#the VLC media player
			);
		    }
		}

	    my @args = ($best_audio);
	    if( $best_audio =~ /mplayer|mpv/ )
		{
		push(@args, "-volume=".$argp->{amplitude} )
		    if( defined($argp->{amplitude} ) );
		push(@args,$to_play);
		}
	    elsif( $best_audio =~ /paplay/ )
	        {
		push(@args,"--volume=".int(65536*$argp->{amplitude}/100.0))
		    if( defined($argp->{amplitude} ) );
		push(@args,$to_play);
		}
	    elsif( $best_audio =~ /ffplay/ )
		{
		push( @args, "-volume",int(65536*$argp->{amplitude}/100.0) )
		    if( defined($argp->{amplitude} ) );
		push(@args,$to_play);
		}
	    elsif( $best_audio =~ /play/ )
	        {
		push(@args,$to_play);
		push(@args,"vol",$argp->{amplitude}/100.0)
		    if( defined($argp->{amplitude} ) );
		}
	    else
	        { push( @args, $to_play ); }
	    &echodo( join(" ",@args) );
	    }
	}
    }
1;
