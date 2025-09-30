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

package cpi_config;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( read_config );
use lib ".";

use cpi_file qw( autopsy read_file );
#__END__
1;
#########################################################################
#	Read in a previously written configuration file.		#
#########################################################################
sub read_config
    {
    my( $fn, $varref ) = @_;
    my( $vtype ) = ref( $varref );

    if( -f $fn )
	{ $_ = &read_file( $fn ); }
    else
        { $_ = "\$VAR1 = {};"; }

    if( /^\$VAR1/ )
        {
	my $VAR1;	# Will be set by evaluating $_
	eval( $_ );
	if( $vtype eq "HASH" )
	    { %{$varref} = %{ $VAR1 }; }
	elsif( $vtype eq "ARRAY" )
	    { @{$varref} = @{ $VAR1 }; }
	return;
	}

    if( $vtype eq "HASH" )
	{
	my %temp;		# Why do I have to create a temporary var?
	eval( "\%temp = $_" );
	%{$varref} = %temp;
	}
    elsif( $vtype eq "ARRAY" )
	{
	my @temp;		# Why do I have to create a temporary var?
	eval( "\@temp = $_" );
	@{$varref} = @temp;
	}
    else
	{&autopsy("read_config refers to unknown variable type:".$vtype);}
    return 1;
    }
1;
