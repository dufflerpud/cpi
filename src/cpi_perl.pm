#!/usr/bin/perl -w
#
#indx#	cpi_perl.pm - Software for writing readable perl
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
#doc#	cpi_perl.pm - Software for writing readable perl
########################################################################

use strict;

package cpi_perl;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( pretty_qw quotes );
use lib ".";

#__END__
1;

#########################################################################
#	Return a prettier qw from a list of items.			#
#	Note that the first item will be something like "@foo=qw("	#
#	and the last item will be something like ");"			#
#########################################################################
sub pretty_qw
    {
    my( @items ) = @_;
    my @lines = ( shift(@items) );
    my $end = pop( @items );
    foreach my $item ( @items )
	{
	if( ( length($lines[$#lines])+length($item)+1 ) > 70 )
	    { push( @lines, $item ); }
	else
	    { $lines[$#lines] .= " $item"; }
	}
    return join("\n ",@lines) . $end;
    }

#########################################################################
#	Created a string from an array of quoted elements.		#
#	Good for constructing command lines.				#
#########################################################################
sub quotes
    {
    return join( " ", (map{"'$_'"} @_) );
    }

1;

