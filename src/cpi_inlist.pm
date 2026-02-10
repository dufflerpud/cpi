#!/usr/bin/perl -w
#indx#	cpi_inlist.pm - Return item if it's in a list.
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
#doc#	cpi_inlist.pm - Return item if it's in a list.
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
