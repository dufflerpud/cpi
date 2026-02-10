#!/usr/bin/perl -w
#
#indx#	cpi_reorder.pm - Easy list manipulation
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2025-2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
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
#hist#	2026-02-09 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	cpi_reorder.pm - Easy list manipulation
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
