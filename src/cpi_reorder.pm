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

package cpi_reorder;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( reorder orderer );
use lib ".";
use cpi_sortable qw( unique numeric_sort );

#__END__
1;
#########################################################################
#	Return an arbitrary list reordered randomly.			#
#########################################################################
sub reorder
    {
    my ( @old_list ) = @_;
    my( @new_list );
    push( @new_list, splice( @old_list, int(rand()*scalar(@old_list)), 1 ) )
        while( scalar(@old_list) );
    return @new_list;
    }

#########################################################################
#	Swiss army knife for sorting arrays.				#
#########################################################################
sub orderer
    {
    my( $argp, @items ) = @_;

    my @before;
    if( $argp->{first} )
        {
	foreach my $item ( @{ $argp->{first} } )
	    {
	    my $pregrep = scalar( @items );
	    @items = grep( $_ ne $item, @items );
	    push( @before, $item ) if( scalar(@items) != $pregrep );
	    }
	}

    my @after;
    if( $argp->{last} )
        {
	foreach my $item ( @{ $argp->{last} } )
	    {
	    my $pregrep = scalar( @items );
	    @items = grep( $_ ne $item, @items );
	    unshift( @after, $item ) if( scalar(@items) != $pregrep );
	    }
	}

    if( $argp->{exclude} )
	{
	foreach my $item ( @{ $argp->{exclude} } )
	    { @items = grep( $_ ne $item, @items ); }
	}

    my @ret;
    if( ! $argp->{sort} )
	{ @ret = ( @before, @items, @after ); }
    else
        {
	if( $argp->{sort} eq "random" )
    	    { @ret = ( @before, &reorder(@items), @after ); }
	elsif( $argp->{sort} eq "numeric" )
    	    { @ret = ( @before, &numeric_sort(@items), @after ); }
	elsif( ref( $argp->{sort} ) eq "CODE" )
    	    { @ret = ( @before, &{$argp->{sort}}(@items), @after ); }
	else
    	    { @ret = ( @before, sort @items, @after ); }
	}

    @ret = &unique( @ret ) if( $argp->{unique} );
    
    return @ret;
    }

1;
