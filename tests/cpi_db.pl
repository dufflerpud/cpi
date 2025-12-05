#!/usr/bin/perl -w

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
