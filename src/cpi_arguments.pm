#!/usr/bin/perl -w
########################################################################
#@HDR@	$Id$
#@HDR@		Copyright 2025 by
#@HDR@		Christopher Caldwell/Brightsands
#@HDR@		P.O. Box 401, Bailey Island, ME 04003
#@HDR@		All Rights Reserved
#@HDR@
#@HDR@	This software comprises unpublished confidential information
#@HDR@	of Brightsands and may not be used, copied or made available
#@HDR@	to anyone, except in accordance with the license under which
#@HDR@	it is furnished.
########################################################################

use strict;

package cpi_arguments;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( parse_arguments );
use lib ".";

use cpi_inlist qw( abbrev );
use cpi_file qw( autopsy );

#__END__
1;

#########################################################################
#	Parse the arguments						#
#########################################################################
sub parse_arguments
    {
    my( $argp ) = @_;
    my %res;
    my $copy_res_to;
    my @problems;

    if( ! $argp )	# Backward compatibility
    	{
	$argp = {};
	$argp->{switches} = \%main::ONLY_ONE_DEFAULTS
	    ;#if( exists ( %main::ONLY_ONE_DEFAULTS ) );
	$copy_res_to = \%main::ARGS
	    ;#if( exists( %main::ARGS ) );
	$argp->{non_switches} = \@main::files
	    ;#if exists( @main::files ) );
	}

    $res{non_switches} = $argp->{non_switches} if($argp->{non_switches} );
    $argp->{flags} ||= [];
    $argp->{switches} ||= {};

    my @my_argv = ( $argp->{argv} ? @{$argp->{argv}} : @ARGV );

    while( @my_argv )
	{
	my $arg = shift(@my_argv);

	if( $arg eq "--" )
	    {
	    if( $argp->{non_switches} )
		{ push( @{ $res{non_switches} }, @my_argv ); }
	    else
	        { grep( push(@problems,"Unrecognized switch:  $_"), @my_argv ); }
	    last;
	    }
	elsif( $arg !~ /^-(.+)/ )
	    {
	    if( $argp->{non_switches} )
		{ push( @{ $res{non_switches} }, $arg ); }
	    else
	        { push(@problems,"Unrecognized switch:  $arg"); }
	    }
	else
	    {
	    my( $lhe, $rhe );
	    if( $arg =~ /^-(.+)=+(.*)$/ )
	    	{ $lhe=$1; $rhe=$2; }
	    elsif( $arg =~ /^-(.)(.+)/ && defined($argp->{switches}{$1}) )
	    	{ $lhe=$1; $rhe=$2; }
	    elsif( $arg =~ /^-(.+)/ )
	    	{ $lhe=$1; }
	    # else won't happen
	    my $switchname = &abbrev( $lhe,
	        keys %{$argp->{switches}},
		@{ $argp->{flags} } );
	    if( defined($switchname) )
	        {
		push( @problems, "-$switchname specified multiple times ($res{$switchname}})." )
		    if( defined( $res{$switchname} ) );
		if( defined( $rhe ) )
		    { $res{$switchname} = $rhe; }
		elsif( ! defined( $argp->{switches}{$lhe} ) )
		    { $res{$switchname} = 1; }
		elsif( ! @my_argv )
		    { push(@problems,"-$switchname has no specified value."); }
		else
		    { $res{$switchname} = shift(@my_argv); }
		}
	    else
	        { push( @problems, "Unrecognized switch -$lhe." ); }
	    }
	}

    my $num_non_switches = $res{non_switches} ? scalar(@{$res{non_switches}}) : 0;
    &push( @problems, "Not enough non-switch arguments specified." )
        if( $num_non_switches < ($argp->{min_non_switches}||0) );
    &push( @problems, "Too many non-switch arguments specified." )
        if( defined($argp->{max_non_switches})
	 && $num_non_switches > $argp->{max_non_switches} );

    if( @problems )
        {
	if( exists &main::usage )
	    { &main::usage( @problems ); }
	else
	    { &autopsy( join("\n",@problems) ); }
	}

    grep( $res{$_}=(defined($res{$_})?$res{$_}:$argp->{switches}{$_}),
	keys %{$argp->{switches}} );

    %{$copy_res_to} = %res if( $copy_res_to );
    return %res;
    }
1;
