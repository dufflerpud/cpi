#!/usr/bin/perl -w
#
#indx#	cpi_sortable.pm - Routines to help sort strings with numbers in them
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
#doc#	cpi_sortable.pm - Routines to help sort strings with numbers in them
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
