#!/usr/bin/perl -w
#
#indx#	cpi_media.pl - Software for testing media players
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
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
#hist#	2026-02-10 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	cpi_media.pl - Software for testing media players
########################################################################

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( fatal read_file cleanup tempfile );
use cpi_arguments qw( parse_arguments );
use cpi_media qw( player media_info );
use cpi_vars;

our @files;
our %ARGS;
our @problems;

sub usage
    {
    &fatal( @_, "Usage:  $cpi_vars::PROG <argument>",
	"Where <argument> is:",
	"	<file>"
	);
    }

%ARGS = &parse_arguments( {
    flags		=> [ "information" ],
    non_switches	=> \@files,
    switches=>
	{
	"verbosity"	=> 0,
	"btop"		=> "",
	"bleft"		=> "",
	"bright"	=> "",
	"bbottom"	=> "",
	"bwidth"	=> "",
	"bheight"	=> "",
	"geometry"	=> ""
	} } );

$cpi_vars::VERBOSITY = $ARGS{verbosity};

if( $ARGS{"information"} )
    {
    my $infop = &media_info( $files[0] );
    foreach my $k ( sort keys %{$infop} )
	{
	printf("%-20s%s\n",${k}.":",$infop->{$k});
	}
    }
else
    {
    my %args;
    foreach my $dim ( "top", "bottom", "left", "right", "width", "height" )
        { $args{$dim} = $ARGS{"b$dim"} if( $ARGS{"b$dim"} ); }
    &player( \%args, @files );
    }

&cleanup( 0 );
