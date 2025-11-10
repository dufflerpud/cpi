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

package cpi_config;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( read_config read_map );
use lib ".";

use cpi_file qw( autopsy read_file read_lines );
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

#########################################################################
#	Create a map of all different kinds of ways of saying the	#
#	same thing back to the canonical form.				#
#	Returns a search string for all those things plus a map.	#
#########################################################################
sub read_map
    {
    my( $filename ) = @_;
    my %map;
    my @all_items;
    foreach my $ln ( &read_lines( $filename ) )
	{
	my( @items ) = split(/\s*,\s*/,$ln);
	my( @lcitems ) = map { lc($_) } @items;
	grep( $map{ $_ } = $items[0], @lcitems );
	push( @all_items, @lcitems );
	}
    my $search = join("|",@all_items);
    return( $search, %map );
    }
1;
