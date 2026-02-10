#!/usr/bin/perl -w
#indx#	cpi_compress_integer.pm - Convert an integer to base 52
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
#doc#	cpi_compress_integer.pm - Convert an integer to base 52
########################################################################

use strict;

package cpi_compress_integer;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( compress_integer );
use lib ".";


#__END__
1;
#########################################################################
#	Convert a number to a more compact string, basically base 62.	#
#	We could have had more digits to COMPACT_LEX, such as "_", but	#
#	decided not to because once this was used for generating unique	#
#	ids and changing the character set would mean potential		#
#	conflicts.  Useful for database keys.				#
#########################################################################
my @COMPACT_LEX = ( '0'..'9', 'A'..'Z', 'a'..'z' );
my $COMPLEX_LEX_SIZE = scalar(@COMPACT_LEX);
sub compress_integer
    {
    my ( $num ) = @_;
    $num =~ s/[^\d]//g;		# Force input to be an integer
    my @compact=();
    do  {
	push( @compact, $COMPACT_LEX[$num % $COMPLEX_LEX_SIZE] );
	} while($num=int($num/$COMPLEX_LEX_SIZE));
    return join("",reverse(@compact));
    }
1;
