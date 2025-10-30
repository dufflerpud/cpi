#!/usr/local/bin/perl -w
########################################################################
#@HDR@	$Id$
#@HDR@		Copyright 2024 by
#@HDR@		Christopher Caldwell/Brightsands
#@HDR@		P.O. Box 401, Bailey Island, ME 04003
#@HDR@		All Rights Reserved
#@HDR@
#@HDR@	This software comprises unpublished confidential information
#@HDR@	of Brightsands and may not be used, copied or made available
#@HDR@	to anyone, except in accordance with the license under which
#@HDR@	it is furnished.
########################################################################
#	(Replace with brief explanation of what this file is or does)
#
#	2024-04-20 - c.m.caldwell@alumni.unh.edu - Created
########################################################################

use strict;

use lib "/usr/local/lib/perl";
use cpi_vars;
use cpi_file qw( fatal cleanup read_file write_file files_in );
use cpi_arguments qw( parse_arguments );
use cpi_inlist qw( inlist );
use cpi_template qw( subst_list );
use cpi_perl qw( pretty_qw );

# Put constants here

our %ONLY_ONE_DEFAULTS =
    (
    "d"	=>	"/usr/local/lib/perl",
    "i"	=>	"/dev/stdin",
    "o"	=>	"/dev/stdout",
    "h"	=>	"header",
    "v"	=>	"0",
    );

# Put variables here.

our $exit_stat = 0;

# These variables are used by &cpi_arguments::parse_arguments()
our @problems;
our %ARGS;
our @files;

# Put interesting subroutines here

#=======================================================================#
#	New code not from prototype.pl					#
#		Should at least include:				#
#			parse_arguments()				#
#			CGI_arguments()					#
#			usage()						#
#=======================================================================#

#########################################################################
#	Setup arguments if CGI.						#
#########################################################################
sub CGI_arguments
    {
    &CGIreceive();
    }

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "",
	"Usage:  $cpi_vars::PROG <possible arguments>","",
	"where <possible arguments> is:",
	"    -i <input file>",
	"    -o <output file>",
	"    -v 1 or 0 for verbose on or off"
	);
    }

#########################################################################
#	Replace this with the meat of the new software.			#
#########################################################################
sub do_it
    {
    my @module_files = &files_in( $ARGS{d}, "cpi_.*.pm" );
    my @code_files
	= grep(!
	    &inlist($_,
		"cpi_vars.pm","cpi_setup.pm",
		"cpi_trans_babelfish.pm","cpi_trans_lingua.pm"
		), @module_files );
    my @ordered_module_files =
	(
	"cpi_vars.pm",
	( sort @code_files ),
	"cpi_setup.pm"
	);

    my @headers = ( &read_file( $ARGS{h} ) );
    my @bodies;
    my @exported;

    foreach my $module_file ( @ordered_module_files )
	{
	my $contents = &read_file( $module_file );
	&fatal("$module_file does not appear to be a cpi module.")
	    if( $contents !~ /^(.*?)\n1;\n(.*)$/ms );
	my ( $header, $body ) = ( $1, $2 );

	$header =~ s/\n#\@HDR\@[^\n]*//gms;
	$header =~ s/\n##+\n/\n/gms;
	$header =~ s/\n##+\n/\n/gms;
	$header =~ s/\nuse strict;\n/\n/ms;
	$header =~ s/\npackage .*?;//ms;
	$header =~ s/\nuse Exporter;\n/\n/ms;
	$header =~ s/\nuse AutoLoader;\n/\n/ms;
	$header =~ s/\nour \@ISA.*?\n/\n/ms;
	$header =~ s/\n#\@ISA =.*?\n/\n/ms;
	$header =~ s/\nour \@EXPORT_OK = qw\(\s*\);\n/\n/ms;
        push( @exported, split(/\s+/,$1) )
	    if( $header =~ /\nour \@EXPORT = qw\(\s*(.*?)\s*\);/ms );
	$header =~ s/\nour \@EXPORT = qw\(.*?\);\n/\n/ms;
	$header =~ s/\n##use vars.*?\n/\n/ms;
	$header =~ s:\nuse lib "/usr/local/lib/perl";\n:\n:ms;
	$header =~ s:\nuse lib "\.";\n:\n:ms;
	$header =~ s/\nuse cpi_.*?;//gms;
	$header =~ s/\n#*__END__/\n/ms;
	$header =~ s/^#!.*?\n//ms;
	$header =~ s/\n\n*/\n/gms;
	$header =~ s/^\n*(.*?)\n*$/$1/gs;

	push( @headers, "\n# Header from ${module_file}:", $header )
	    if( $header );

	$body =~ s/^1;\n/\n/gms;
	$body =~ s/\n1;\n/\n/gms;
	$body =~ s/cpi_\w+:://g;
	$body =~ s/^\n*(.*?)\n*$/$1/gs;
	push( @bodies, "# Body from ${module_file}:", $body )
	    if( $body );
	}

    $headers[0] = &cpi_template::subst_list( $headers[0],
	'%%EXPORTS%%', &pretty_qw( "our \@EXPORT = qw(",@exported,");") );
    &write_file( $ARGS{o}, join("\n",@headers,"#__END__","1;",@bodies,"1;\n") );
    }

#########################################################################
#	Main								#
#########################################################################

if( 0 && $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    { &parse_arguments(); }

&do_it();

&cleanup(0);
