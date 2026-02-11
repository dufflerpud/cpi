#!/usr/bin/perl -w
#
#indx#	cpi_english.pl - Software for testing pluralization logic
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
#doc#	cpi_english.pl - Software for testing pluralization logic
########################################################################

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( fatal cleanup );
use cpi_english qw( match_case plural nword conjoin list_items );
use cpi_arguments qw( parse_arguments );

our @problems;

sub usage
    {
    &fatal( @_,
	"",
	"Usage:  $cpi_vars::PROG -<flag> word1 word2 word3 ...",
	"where <flag> is one or more of:",
	"-conjoin       Call conjoin()",
	"-list_items    Call list_items()",
	"-nword         Call nword()",
	"-plural        Call plural()" );
    }

our @words;
my %ARGS = &parse_arguments(
    {
    flags=>
	[
	"conjoin",
	"list_items",
	"nword",
	"plural"
	],
    non_switches=>\@words
    } );

push( @problems, "Unknown function.")
    if( !$ARGS{conjoin}
     && !$ARGS{list_items}
     && !$ARGS{nword}
     && !$ARGS{plural} );

&usage( @problems ) if( @problems );

print &conjoin(		@words ), "\n"	if( $ARGS{conjoin}	);
print &list_items(	@words ), "\n"	if( $ARGS{list_items}	);
print &nword(		@words ), "\n"	if( $ARGS{nword}	);
print &plural(		@words ), "\n"	if( $ARGS{plural}	);

&cleanup(0);
