#!/usr/bin/perl -w
#
#indx#	cpi_db.pl - Software for testing database handler
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
#doc#	cpi_db.pl - Software for testing database handler
########################################################################

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( fatal cleanup );
use cpi_db qw( dbread dbwrite dbclose dbnew );
use cpi_arguments qw( parse_arguments );
use cpi_copy_db qw( copydb );
use cpi_vars;

#use Cwd;
use Cwd 'abs_path';

# Put constants here

our @problems;
our %ARGS;
our @files;
our $exit_stat = 0;

#########################################################################
#	Setup arguments if CGI.						#
#########################################################################
sub CGI_arguments
    {
    &CGIreceive();
    &usage("No supported web interface.");
    }

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "", "Usage:  $cpi_vars::PROG { <various arguments> }",
	"    where <various arguments> includes:",
	"\t-new <database>",
	"\t-information <database>",
	"\t<source database> <destination database>",
	"\t-verbosity 0 | 1",
	"\t-yes" );
    }

#########################################################################
#	Basic database manipulation from the command line.		#
#########################################################################
sub command_line
    {
    if( $ARGS{information} ne "" )
	{
	push( @problems, "Only one file should be specified with -new." )
	    if( @files );
	&usage( @problems ) if( @problems );
	&dbread( $ARGS{information} );
	my @keylist = keys %{$cpi_vars::databases{$ARGS{information}}};
	&dbclose( $ARGS{information} );
	my %counts;
	grep( /^(.)/ && $counts{$1}++, @keylist );
	print scalar(@keylist), ":",
	    (map {" $_=$counts{$_}"} sort keys %counts),
	    "\n";
	}
    elsif( $ARGS{new} ne "" )
	{
	push( @problems, "Only one file should be specified with -new." )
	    if( @files );
	push( @problems, "$ARGS{new} already exists.  Specify -yes to overwrite.")
	    if( -e $ARGS{new} && ! $ARGS{yes} );
	&usage( @problems ) if( @problems );
	&dbnew( $ARGS{new} );
	}
    elsif( scalar(@files)==0 )
	{ &usage("No files specified."); }
    elsif( scalar(@files)!=2 )
	{ &usage("Must specify exactly two files to copy database."); }
    elsif( -e $files[1] && ! $ARGS{yes} )
	{ &usage("$files[1] exists.  Specify -yes to overwrite."); }
    else
	{ &copydb( abs_path($files[0]), abs_path($files[1]) ); }
    }

#########################################################################
#	Main								#
#########################################################################

%ARGS = &parse_arguments({
    flags		=> [ "yes" ],
    switches=>
	{
	"verbosity"	=> [ 0, 1 ],
	"information"	=> "",
	"new"		=> "",
	},
    non_switches	=> \@files
    });

if( $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    { &command_line(); }

&cleanup($exit_stat);
