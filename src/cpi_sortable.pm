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

package cpi_sortable;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw();
use lib ".";


#__END__
1;
#########################################################################
#	Make numbers all take same number of digits so can be used for	#
#	sorting.							#
#########################################################################
sub sortable
    {
    my( $val ) = @_;
    $val =~ s/(\d+)/uc sprintf("%020d",$1)/eg;
    return $val
    }

#########################################################################
#	Numeric sort.							#
#########################################################################
sub numeric_sort
    {
    return sort { &sortable($a,$b) } @_;
    }

#########################################################################
#	Get rid of all redundant items in an array.			#
#########################################################################
sub unique
    {
    my %seen;
    grep( $seen{$_}, @_ );
    return keys %seen;
    }
1;
