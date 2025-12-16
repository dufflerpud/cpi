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

package cpi_inlist;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( abbrev inlist );
use lib ".";

#__END__
1;

#########################################################################
#	Return true if the first item is anywhere in specified list.	#
#########################################################################
sub inlist
    {
    my( $word, @the_list ) = @_;
    return grep( $word eq $_, @the_list );
    }

#########################################################################
#	Check user input against a list of words looking for best fit.	#
#	Note that if we're doing abbreviations, we don't care about	#
#	case.								#
#########################################################################
sub abbrev
    {
    my( $word, @the_list ) = @_;
    my $word_len = length( $word );
    $word =~ tr/A-Z/a-z/;
    my $result;
    foreach my $check ( @the_list )
        {
	$_ = lc( $check );
	if( $word eq $_ )
	    {
	    $result = $check;
	    last;
	    }
	elsif( substr( $_, 0, $word_len ) eq $word )
	    {
	    if( defined($result) )
	        {
		$result = undef;
		last;
		}
	    $result = $check;
	    }
	}
#    print "abbrev($word,[",join(",",@the_list),"]) returns ",
#        (defined($result)?"'$result'":"UNDEF"), ".\n";
    return $result;
    }
1;
