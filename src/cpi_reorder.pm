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

package cpi_reorder;
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
1;
