#!/usr/bin/perl -w
#
#indx#	cpi_lock.pl - Software for testing file locking
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
#doc#	cpi_lock.pl - Software for testing file locking
########################################################################

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( fatal read_file cleanup );
use cpi_arguments qw( parse_arguments );
use cpi_lock qw( lock_file unlock_file );
use cpi_vars;

our %ARGS;
our @problems;

sub usage
    {
    &fatal( @_, "Usage:  $cpi_vars::PROG <argument>",
	"Where <argument> is:",
	"-lock            Lock the file",
	"-unlock          Unlock the file",
	"-file <file>     Specify file to lock",
        "-debug 0         Turn tracing off",
        "-debug 1         Turn tracing on",
	"-break_stale 0   Hang even with stale locks",
	"-break_stale 1   Break stale locks");
    }

sub test_lock
    {
    &lock_file( @_ );
    system("ls -ld $ARGS{file}*");
    }

sub test_unlock
    {
    &unlock_file( @_ );
    system("ls -ld $ARGS{file}*");
    }

%ARGS = &parse_arguments( {
    switches=>
	{
	"verbosity"	=> 0,
	"file"		=> "test_file",
	"mode"		=> ["wait","lock","unlock"],
	"wait"		=> { alias => [ "-mode", "wait" ] },
	"lock"		=> { alias => [ "-mode", "lock" ] },
	"unlock"	=> { alias => [ "-mode", "unlock" ] },
	"debug"		=> 1,
	"break_stale"	=> 1,
	} } );

$cpi_vars::LOCK_DEBUG		= $ARGS{debug};
$cpi_vars::LOCK_BREAK_STALE	= $ARGS{break_stale};

if( $ARGS{mode} eq "wait" )
    {
    &test_lock( $ARGS{file} );
    print "Hit return when done:  ";
    $_ = <STDIN>;
    &test_unlock( $ARGS{file} );
    }
elsif( $ARGS{mode} eq "lock" )
    { &test_lock( $ARGS{file} ); }
elsif( $ARGS{mode} eq "unlock" )
    { &test_unlock( $ARGS{file} ); }
else
    { &fatal("Mode [$ARGS{mode}] unsupported."); }
