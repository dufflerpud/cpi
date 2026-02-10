#!/usr/bin/perl -w
#
#indx#	cpi_unique_nbit_color.pm - Generate unique color strings
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
#doc#	cpi_unique_nbit_color.pm - Generate unique color strings
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
