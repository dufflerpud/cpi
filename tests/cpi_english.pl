#!/usr/bin/perl -w

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( fatal );
use cpi_english qw( match_case plural nword );

if( scalar(@ARGV) == 1 )
    { print &plural($ARGV[0]), ".\n"; }
elsif( scalar(@ARGV) == 2 )
    { print &nword($ARGV[0],$ARGV[1]), ".\n"; }
else
    { &fatal( "Usage:  cpi_english word n\n" ); }
