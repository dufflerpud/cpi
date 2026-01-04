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

package cpi_perl;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( pretty_qw quotes );
use lib ".";

#__END__
1;

#########################################################################
#	Return a prettier qw from a list of items.			#
#	Note that the first item will be something like "@foo=qw("	#
#	and the last item will be something like ");"			#
#########################################################################
sub pretty_qw
    {
    my( @items ) = @_;
    my @lines = ( shift(@items) );
    my $end = pop( @items );
    foreach my $item ( @items )
	{
	if( ( length($lines[$#lines])+length($item)+1 ) > 70 )
	    { push( @lines, $item ); }
	else
	    { $lines[$#lines] .= " $item"; }
	}
    return join("\n ",@lines) . $end;
    }

#########################################################################
#	Created a string from an array of quoted elements.		#
#	Good for constructing command lines.				#
#########################################################################
sub quotes
    {
    return join( " ", (map{"'$_'"} @_) );
    }

1;

