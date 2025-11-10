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

package cpi_sortable;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( sortable numeric_sort unique );
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
    return sort { &sortable($a) cmp &sortable($b) } @_;
    }

#########################################################################
#	Get rid of all redundant items in an array, preserve order.	#
#########################################################################
sub unique
    {
    my %seen;
    return grep( ! $seen{$_}++, @_ );
    }
1;
