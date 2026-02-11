#!/usr/bin/perl -w
#
#indx#	cpi_send_file.pl - Testing sending mail, faxes etc
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
#doc#	cpi_send_file.pl - Testing sending mail, faxes etc
########################################################################

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( fatal cleanup );
use cpi_time qw( time_string );
use cpi_arguments qw( parse_arguments );
use cpi_send_file qw( sendmail );
use cpi_vars;

our @problems;
our %ARGS;
our @files;

my $now_string = &time_string("%04d-%02d-%02d %02d:%02d:%02d");

#########################################################################
#	Print a usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_,
	"",
	"Usage:  $cpi_vars::PROG { <argument> } file file file...",
	"where <argument> is one or more of:",
	"-to <address>",
	"-from <address>",
	"-subject <subject>");
    }

#########################################################################
#	Main								#
#########################################################################
%ARGS = &parse_arguments(
    {
    #flags		=>	[ "delete", "yes", "ask_password" ],
    flags		=>	[ "verbose" ],
    switches=>
	{
	"from"		=>	"chris.interim\@gmail.com",
	"to"		=>	"chris.interim\@gmail.com",
	"subject"	=>	"Mail sent $now_string",
	"message"	=>	"This is a test message."
	},
    non_switches	=>	\@files
    } );

print "from=$ARGS{from} to=$ARGS{to} subject=$ARGS{subject}\n"
    if( $ARGS{verbose} );
&sendmail(
    $ARGS{from},
    $ARGS{to},
    $ARGS{subject},
    $ARGS{message},
    @files );
&cleanup(0);
