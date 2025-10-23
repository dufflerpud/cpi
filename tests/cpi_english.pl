#!/usr/bin/perl -w

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
