#!/usr/bin/perl -w
#
#indx#	cpi_hash.pl - Software for testing hash routines
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
#doc#	cpi_hash.pl - Software for testing hash routines
########################################################################

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
