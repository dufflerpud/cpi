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
#########################################################################
sub abbrev
    {
    my( $word, @the_list ) = @_;
    my $word_len = length( $word );
    $word =~ tr/A-Z/a-z/;
    my $result;
    foreach $_ ( @the_list )
        {
	if( $word eq $_ )
	    {
	    $result = $word;
	    last;
	    }
	elsif( substr( $_, 0, $word_len ) eq $word )
	    {
	    if( defined($result) )
	        {
		$result = undef;
		last;
		}
	    $result = $_;
	    }
	}
#    print "abbrev($word,[",join(",",@the_list),"]) returns ",
#        (defined($result)?"'$result'":"UNDEF"), ".\n";
    return $result;
    }
1;
