#!/usr/bin/perl -w
#
#indx#	cpi_media.pm - Software to play/display arbitrary file types on local equipment
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2025-2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
#@HDR@
#@HDR@	Permission is hereby granted, free of charge, to any person
#@HDR@	obtaining a copy of this software and associated documentation
#@HDR@	files (the "Software"), to deal in the Software without
#@HDR@	restriction, including without limitation the rights to use,
#@HDR@	copy, modify, merge, publish, distribute, sublicense, and/or
#@HDR@	sell copies of the Software, and to permit persons to whom
#@HDR@	the Software is furnished to do so, subject to the following
#@HDR@	conditions:
#@HDR@	
#@HDR@	The above copyright notice and this permission notice shall be
#@HDR@	included in all copies or substantial portions of the Software.
#@HDR@	
#@HDR@	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
#@HDR@	KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
#@HDR@	WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
#@HDR@	AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#@HDR@	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#@HDR@	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#@HDR@	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#@HDR@	OTHER DEALINGS IN THE SOFTWARE.
#
#hist#	2026-02-09 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	cpi_media.pm - Software to play/display arbitrary file types on local equipment
#doc#	This is the crux of show.pl
########################################################################

use strict;

package cpi_media;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( player media_info fix_dimensions );
use lib ".";

use cpi_file qw( first_in_path echodo read_lines tempfile autopsy );
use cpi_filename qw( just_ext_of );
use cpi_mime qw( read_mime_types );
use cpi_make_from qw( convert_file );
use Data::Dumper;

#__END__
1;

#########################################################################
#	Return dimensions of the file.					#
#########################################################################
sub media_info
    {
    my( $filename ) = @_;
    my $ext = &just_ext_of( $filename ) || "?";
    &read_mime_types();
    my $mime_type = $cpi_vars::EXT_TO_MIME_TYPE{$ext} || "?";
    my $ret =
	{
	extension	=> $ext,
	mime_type	=> $mime_type,
	type		=> $cpi_vars::MIME_TYPE_TO_BASE_TYPE{$mime_type},
	size		=> -s $filename
	};
    if( $filename =~ /^(http|https):/ )
        {}
    elsif( $ret->{type} eq "image" )
	{
	if( ($ext eq "jpg" || $ext eq "jpeg") && &first_in_path("exiv2") )
	    {
	    foreach my $line ( &read_lines("exiv2 -q '$filename' |") )
		{
		if( $line =~ /^Image size\s+:\s+(\d+) x (\d+)\s*$/i )
		    {
		    $ret->{width} = $1;
		    $ret->{height} = $2;
		    last;
		    }
		}
	    }
	else
	    {
	    my $pnmfile = $filename;
	    &convert_file( $pnmfile=&tempfile(".pnm"), $filename )
		if( $ext ne "pnm" );
	    foreach my $line ( &read_lines("pnmfile '$pnmfile' |") )
		{
		if( $line =~ /,\s+(\d+)\s+by\s+(\d+)\s+maxval/i )
		    {
		    $ret->{width} = $1;
		    $ret->{height} = $2;
		    last;
		    }
		}
	    }
	$ret->{frames} = 1;
	$ret->{time} = 0;
	}

    $ret->{ratio} = ( 1.0 * $ret->{width} / $ret->{height} )
	if( $ret->{height} );
#    print STDERR "media_info($filename):",
#        (map {sprintf("  %-10s%s\n",$_.":",$ret->{$_})} sort keys %{$ret});
    return $ret;
    }

#########################################################################
#	Figure out what we can from information already in hash.	#
#########################################################################
sub merge_dimensions
    {
    my( $argp, $mediap ) = @_;
    my %ret = %{$argp};
    if( $ret{geometry} )
        {
	if( $ret{geometry} =~ /^(\d+)x(\d+)/ )
	    { $ret{width}=$1; $ret{height}=$2; }
	if( $ret{geometry} =~ /([+\-])(\d+)([+\-])(\d+)$/ )
	    {
	    $ret{ $1 eq "+" ? "left" : "right" } = $2;
	    $ret{ $3 eq "+" ? "top" : "bottom" } = $2;
	    }
	}

    if( $mediap )
	{
	$ret{width} ||= $mediap->{width};
	$ret{height} ||= $mediap->{height};
	}

    if( defined($ret{left}) )
        {
	if( $ret{right} )
	    { $ret{width} = $ret{right}-$ret{left}; }
	elsif( $ret{width} )
	    { $ret{right} = $ret{left}+$ret{width}; }
	}
    elsif( $ret{right} && $ret{width} )
	{ $ret{left} = $ret{right} - $ret{width}; }

    if( defined($ret{top}) )
        {
	if( $ret{bottom} )
	    { $ret{height} = $ret{bottom}-$ret{top}; }
	elsif( $ret{height} )
	    { $ret{bottom} = $ret{top}+$ret{height}; }
	}
    elsif( $ret{bottom} && $ret{height} )
	{ $ret{top} = $ret{bottom} - $ret{height}; }

    $ret{dimensions} = "$ret{width}x$ret{height}"
	if( ! $ret{dimensions} && $ret{width} && $ret{height} );
    $ret{location} = "+$ret{left}+$ret{top}"
	if( ! $ret{location} && defined($ret{left}) && defined($ret{top}) );

    if( ! $ret{geometry} )
        {
	my @gpieces;
	push( @gpieces, $ret{dimensions} ) if( $ret{dimensions} );
	push( @gpieces, $ret{location} ) if( $ret{location} );
	$ret{geometry} = join("",@gpieces) if( @gpieces );
	}
#    print STDERR "merge_dimensions():\n",
#        (map {sprintf("  %-10s%s\n",$_.":",$ret{$_})} sort keys %ret);
    return \%ret;
    }

#########################################################################
#	Go find player and play the supplied files.			#
#	Tries far harder than it should.				#
#########################################################################
sub player
    {
    my $argp = ( ref($_[0]) eq "HASH" ? shift(@_) : {} );
    my @to_play_list = @_;
    my %best_for_types;

    foreach my $to_play ( @to_play_list )
	{
	my $qto_play = "'$to_play'";
	my $mediap = &media_info( $to_play );
	my $current_type = $mediap->{type} || "unknown";
	my $file_dep_argp = &merge_dimensions( $argp, $mediap );
	my $current_player;
	$current_player = ($file_dep_argp->{player} || $best_for_types{$current_type})
	    if( $current_type );
	if( ! $current_player )
	    {
	    if( $current_type eq "audio" )	# if $to_play is audio
		{ $current_player = &first_in_path(
		    "mpv --no-audio-display -really-quiet -quiet",	#a media player
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
		    "pia",	#play media files
		    "pragha",	#A lightweight music player, forked of Consonance Music ...
		    "vlc"	#the VLC media player
		    );
		}
	    elsif( $current_type eq "video"
		|| $to_play =~ /^(http|https):.*youtube/ )
		{ $current_player = &first_in_path(
		    "mpv -really-quiet -quiet",		#a media player
		    "mplayer -really-quiet -quiet",	#Movie Player for Linux
		    "aviplay",	#QT-based movie player
		    "ffplay",	#FFplay media player
		    "lqtplay",	#simple quicktime movie player for X11.
		    "madplay",	#decode and play MPEG audio stream(s)
		    "mpg123",	#play audio MPEG 1.0/2.0/2.5 stream (layers 1, 2 and 3)
		    "pia",	#play media files
		    "pragha",	#A lightweight music player, forked of Consonance Music ...
		    "vlc"	#the VLC media player
		    );
		}
	    elsif( $to_play =~ /^(http|https):/i )
	        { $current_player = &first_in_path(
		    "xdg-open",
		    "firefox",
		    "google-chrome",
		    "netscape" );
		}
	    elsif( $current_type eq "image" )
		{ $current_player = &first_in_path(
		    "display"	# From ImageMagick
		    );
		}
	    elsif( $current_type eq "pdf" || $current_type eq "postscript" )
		{ $current_player = &first_in_path(
		    "evince"
		    );
		}

	    if( ! $current_player )
	        {
		if( $current_type )
	    	    { &autopsy("Do not know how to play the $current_type file $to_play."); }
		else
	    	    { &autopsy("Do not know how to play the file $to_play."); }
		}
	    $best_for_types{$current_type} = $current_player;
	    }

	my @args = ($current_player);
	if( $current_player =~ /mplayer|mpv/ )
	    {
	    push(@args, "-volume=".$file_dep_argp->{amplitude} )
		if( defined($file_dep_argp->{amplitude} ) );
	    push( @args, " -geometry $file_dep_argp->{geometry}" )
		if($file_dep_argp->{geometry});
	    push( @args, "--ao=".($file_dep_argp->{ao}||"null") )
		if( ($file_dep_argp->{ao}||"") ne "" );
	    push( @args, "--vo=".($file_dep_argp->{vo}||"null") )
		if( ($file_dep_argp->{vo}||"") ne "" );

	    push( @args, "--loop-playlist=".($file_dep_argp->{loop}=~/\d/?$file_dep_argp->{times}:"inf") )
	        if( defined($file_dep_argp->{loop}) );
	    push( @args, "--fs" )
		if( $file_dep_argp->{fullscreen} || $file_dep_argp->{screen});
	    push( @args, "--speed=$file_dep_argp->{rate}" )
		if( $file_dep_argp->{rate} );
	    push( @args, "--title=='$file_dep_argp->{title}'" )
		if( $file_dep_argp->{title} );
	    push(@args,$qto_play);
	    }
	elsif( $current_player =~ /paplay/ )
	    {
	    push(@args,"--volume=".int(65536*$file_dep_argp->{amplitude}/100.0))
		if( defined($file_dep_argp->{amplitude} ) );
	    push(@args,$qto_play);
	    }
	elsif( $current_player =~ /ffplay/ )
	    {
	    push( @args, "-volume",int(65536*$file_dep_argp->{amplitude}/100.0) )
		if( defined($file_dep_argp->{amplitude} ) );
	    push(@args,$qto_play);
	    }
	elsif( $current_player =~ /\bplay/ )
	    {
	    push(@args,$qto_play);
	    push(@args,"vol",$file_dep_argp->{amplitude}/100.0)
		if( defined($file_dep_argp->{amplitude} ) );
	    }
	elsif( $current_player =~ /display/ )
	    {
	    push( @args, " -geometry $file_dep_argp->{geometry}" )
	        if($file_dep_argp->{geometry});
	    push( @args, " -resize $file_dep_argp->{dimensions}" )
	        if($file_dep_argp->{dimensions});
	    push( @args, $qto_play );
	    }
	elsif(	$current_player=~/google-chrome/
	  &&	$current_player=~/xdg-open/
	  &&	$current_player=~/firefox/
	  &&	$current_player=~/netscape/ )
	    {
	    push( @args, " -geometry $file_dep_argp->{geometry}" )
	        if($file_dep_argp->{geometry});
	    push( @args, $qto_play );
	    }
	else
	    { push( @args, $qto_play ); }
	&echodo( join(" ",@args) );
	}
    }
1;
