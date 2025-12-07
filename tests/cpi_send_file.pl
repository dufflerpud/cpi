#!/usr/bin/perl -w

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
