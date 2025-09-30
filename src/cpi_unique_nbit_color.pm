#!/usr/bin/perl -w
########################################################################
#@HDR@	$Id$
#@HDR@		Copyright 2025 by
#@HDR@		Christopher Caldwell/Brightsands
#@HDR@		P.O. Box 401, Bailey Island, ME 04003
#@HDR@		All Rights Reserved
#@HDR@
#@HDR@	This software comprises unpublished confidential information
#@HDR@	of Brightsands and may not be used, copied or made available
#@HDR@	to anyone, except in accordance with the license under which
#@HDR@	it is furnished.
########################################################################

use strict;

package cpi_unique_nbit_color;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( contrast_color unique_nbit_color );
use lib ".";

#__END__
1;

#########################################################################
#	Return N bit color code based on index.  The idea is that	#
#	Colors with low numbers are more different than those with	#
#	high numbers.							#
#	For 24 bit color (nbit=24), width=8.				#
#	Tries to handle nbit%3!=0 reasonably (e.g. 8 bit color)		#
#	but not well tested.						#
#########################################################################
my $COLOR_CHANNELS = 3;
my @unique_nbit_shifters;
my @unique_nbit_index;
sub unique_nbit_color
    {
    my( $val, $nbit ) = @_;
    $nbit ||= 24;
    $val = $unique_nbit_index[$nbit]++ if( ! defined($val) );
    if( ! $unique_nbit_shifters[$nbit] )
        {
	my $minwidth = int( $nbit / $COLOR_CHANNELS );
	my $extra_bits = $nbit % $COLOR_CHANNELS;
	my $chan;
	my @width;
	for( $chan=0; $chan<$COLOR_CHANNELS; $chan++ )
	    {
	    $width[$chan] = $minwidth + ($chan<$extra_bits?1:0);
	    }
	my $base = 0;
	my @bitnum;
	while( --$chan >= 0 )
	    {
	    $base += $width[$chan];
	    $bitnum[$chan] = $base;
	    }
	my @offsets;
	for( my $i=0; $i<$nbit; $i++ )
	    {
	    push( @offsets, 1<<--$bitnum[ ++$chan%$COLOR_CHANNELS ] );
	    }
	$unique_nbit_shifters[$nbit] = \@offsets;
	}

    my $res = 0;
    for( my $ind=0; $val; $ind++ )
        {
	$res |= $unique_nbit_shifters[$nbit][$ind] if( $val & 1 );
	$val >>= 1;
	}
    return $res;
    }

#########################################################################
#	Choose a color that will have a reasonable contrast with the	#
#	specified 24 bit color.  For right now either black or white.	#
#########################################################################
my %contrast_color_cache;
sub contrast_color
    {
    my( $bgcolor ) = @_;
    if( ! defined( $contrast_color_cache{$bgcolor} ) )
	{
	my ( $amt_red, $amt_green, $amt_blue );
	if( /^#*([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])$/ )
	    {
	    $amt_red=hex($1);
	    $amt_green=hex($2);
	    $amt_blue=hex($3);
	    }
	else
	    {
	    my $toshift = $bgcolor;
	    $amt_blue=$toshift%256;		$toshift=int($toshift/256);
	    $amt_green=$toshift%256;		$toshift=int($toshift/256);
	    $amt_red=$toshift%256;
	    }
	my $lum = ($amt_red * 0.3) + ($amt_green * 0.59) + ($amt_blue * 0.11);
	$contrast_color_cache{$bgcolor} = ( $lum < 128 ? '#ffffff' : '#000000' );
	}
    return $contrast_color_cache{$bgcolor}
    }

1;
