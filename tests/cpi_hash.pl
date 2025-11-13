#!/usr/bin/perl -w

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( fatal read_file cleanup );
use cpi_arguments qw( parse_arguments );
use cpi_hash qw( hashof match_password salted_password set_best_password_hash );
use cpi_vars;

our %ARGS;
our @problems;
our @files;
our %ONLY_ONE_DEFAULTS =
    (
    "verbosity"		=> 0,
    "input_file"	=> "/dev/stdin",
    "hash_type"		=> ""
    );

sub usage
    {
    &fatal( @_, "Usage:  $cpi_vars::PROG [<string0> [<string1>]]",
	"Where <string0> is a password in clear text",
	"and <string1> is an encrypted string" );
    }

&parse_arguments();

&set_best_password_hash( $ARGS{hash_type} ) if( $ARGS{hash_type} );

if( ! @files )
    { print STDOUT &hashof( &read_file( $ARGS{input_file} ) ), "\n"; }
elsif( scalar(@files) == 1 )
    { print STDOUT ( &salted_password(@files) || "UNDEF" ), "\n"; }
elsif( scalar(@files) == 2 )
    { print STDOUT ( &match_password(@files) || "UNDEF" ), "\n"; }
else
    { &usage("Too many strings specified."); }

&cleanup(0);
