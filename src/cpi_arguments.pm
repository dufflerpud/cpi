#!/usr/bin/perl -w
########################################################################
#@HDR@	$Id$
#@HDR@		Copyright 2025 by
#@HDR@		Christopher Caldwell
#@HDR@		P.O. Box 401, Bailey Island, ME 04003
#@HDR@		All Rights Reserved
#@HDR@
#@HDR@	This software comprises unpublished confidential information
#@HDR@	of the copyright holder and may not be used, copied or made
#@HDR@	available to anyone, except in accordance with the license
#@HDR@	under which it is furnished.
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

use cpi_inlist qw( abbrev inlist );
use cpi_file qw( autopsy );
use cpi_english qw( conjoin );

use Data::Dumper;

#__END__
1;

#########################################################################
#	Check if new value conforms to switches description.  If not,	#
#	add to problems, otherwise at to results.			#
#########################################################################
#&try_arg( $switchname, $argp->{switches}, $rhe );
sub try_arg
    {
    my( $resp, $problemsp, $switchname, $argp, $new_value ) = @_;
    $resp->{$switchname} = $new_value;	# Do it but check for errors ...

    my $reftype = ref( $argp );

    if( $reftype eq "HASH" )
	{}
    elsif( $reftype eq "ARRAY" )
	{ $argp = { oneof=>$argp }; }
    elsif( $reftype eq "CODE" )
	{ $argp = { code=>$argp }; }
    elsif( $reftype eq "" )
	{ $argp = {}; }
    else
	{ &autopsy("try_arg(-$switchname) called with ref(\$argp)=$reftype."); }

    my $preface = "-$switchname value \"$new_value\"";

    if( ! $argp || ! $argp->{oneof} )
	{ $resp->{$switchname} = $new_value; }
    elsif( defined( $resp->{$switchname} = &abbrev( $new_value, @{$argp->{oneof}} ) ) )
	{ $new_value = $resp->{$switchname}; }
    else
	{
        push( @{$problemsp}, "$preface must be one of ".
	    &conjoin("or",@{$argp->{oneof}}). "." );
	}

    if( $argp->{code} )
	{
	my $problem = &{$argp->{code}}( $switchname, $new_value );
        push( @{$problemsp}, "$preface problem:  $problem" )
	    if( defined( $problem ) );
	}

    push( @{$problemsp},
	"$preface must match the regular expression $argp->{re}." )
	if( $argp->{re} && $new_value !~ /$argp->{re}/ );

    if( $new_value =~ /^(\d+)|(\d+\.\d+)$/ )
	{
	push( @{$problemsp}, "$preface is less than $argp->{min}." )
	    if( defined($argp->{min}) && $new_value < $argp->{min} );
	push( @{$problemsp}, "$preface is more than $argp->{max}." )
	    if( defined($argp->{max}) && $new_value > $argp->{max} );
	}
    elsif( defined($argp->{min}) || defined($argp->{max}) )
	{ push( @{$problemsp}, "$preface is not a number." ); }
    }

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
	#print "Processing [$arg]\n";

	if( $arg eq "--" )
	    {
	    if( $argp->{non_switches} )
		{ push( @{ $res{non_switches} }, @my_argv ); }
	    else
	        { grep( push(@problems,"Unrecognized switch:  $arg"), @my_argv ); }
	    last;
	    }
	elsif( $arg =~ /^-\.\w+$/ )
	    # -.extension means either stdin or stdout with the desired type
	    { push( @{ $res{non_switches} }, $arg ); }
	elsif( $arg !~ /^-(.+)/ )
	    {
	    if( $argp->{non_switches} )
		{ push( @{ $res{non_switches} }, $arg ); }
	    else
	        { push(@problems,"Unrecognized argument:  $arg"); }
	    }
	else
	    {
	    my( $lhe, $rhe );
	    if( $arg =~ /^-(.+)=+(.*)$/ )
	    	{ $lhe=$1; $rhe=$2; }
	    elsif( $arg =~ /^-([A-Za-z_]+)([^A-Za-z_].*)/ &&
		&abbrev( $1, keys %{$argp->{switches}} ) )
	    	{ $lhe=$1; $rhe=$2; }
	    elsif( $arg =~ /^-(.+)/ )
	    	{ $lhe=$1; }
	    # else won't happen
	    #print __LINE__, " lhe=$lhe rhe=", ($rhe||"UNDEF"), ".\n";
	    my $switchname = &abbrev( $lhe,
	        keys %{$argp->{switches}},
		@{ $argp->{flags} } );
	    #print __LINE__, " switchname=[$switchname]\n";
	    if( defined($switchname) )
	        {
		&autopsy("argp not defined.") if( ! $argp );
		&autopsy("argp->{switches} not defined.") if( ! $argp->{switches} );
		if( defined($argp->{switches}{$switchname})
		  &&ref( $argp->{switches}{$switchname}) eq "HASH"
		  &&$argp->{switches}{$switchname}{alias} )
		    {
		    @my_argv =
			(
			@{$argp->{switches}{$switchname}{alias}},
			@my_argv
			);
		    }
		elsif( defined( $res{$switchname} ) )
		    {
		    push( @problems, "-$switchname specified multiple times ($res{$switchname})." );
		    }
		elsif( defined( $rhe ) )
		    {
		    &try_arg( \%res, \@problems,
			$switchname, $argp->{switches}{$switchname}, $rhe );
		    }
		elsif( ! defined( $argp->{switches}{$switchname} ) )
		    {
		    # Else it's a flag.  Very simple.
		    $res{$switchname} = 1;
		    }
		elsif( ! @my_argv )
		    { push(@problems,"-$switchname has no specified value."); }
		else
		    {
		    &try_arg( \%res, \@problems,
			$switchname, $argp->{switches}{$switchname}, shift(@my_argv) );
		    }
		}
	    else
	        { push( @problems, "Unrecognized switch: -$lhe." ); }
	    }
	}

    my $num_non_switches = $res{non_switches} ? scalar(@{$res{non_switches}}) : 0;
    push( @problems, "Not enough non-switch arguments specified." )
        if( $num_non_switches < ($argp->{min_non_switches}||0) );
    push( @problems, "Too many non-switch arguments specified." )
        if( defined($argp->{max_non_switches})
	 && $num_non_switches > $argp->{max_non_switches} );

    if( ! @problems )
	{
	foreach my $switch (
	    grep( !defined($res{$_}), keys %{$argp->{switches}} ) )
	    {
	    my $reftype = ref($argp->{switches}{$switch});
	    if( $reftype eq "" )
		{ $res{$switch} = $argp->{switches}{$switch}; }
	    elsif( $reftype eq "ARRAY" )
		{ $res{$switch} = $argp->{switches}{$switch}[0]; }
	    elsif( $reftype eq "HASH" )
		{
		if( defined($argp->{switches}{$switch}{default}) )
		    { $res{$switch} = $argp->{switches}{$switch}{default}; }
		elsif( defined($argp->{switches}{$switch}{oneof}) )
		    { $res{$switch} = $argp->{switches}{$switch}{oneof}[0]; }
#		else
#		    { push( @problems, "No default for -$switch."); }
		}	
	    }
	}

    if( @problems )
        {
	if( exists &main::usage )
	    { &main::usage( @problems ); }
	else
	    { &autopsy( join("\n",@problems) ); }
	}

    %{$copy_res_to} = %res if( $copy_res_to );
    return %res;
    }
1;
