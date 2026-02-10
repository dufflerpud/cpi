#!/usr/bin/perl -w
#indx#	cpi_escape.pm - Escaping strings for different languages
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
#doc#	cpi_escape.pm - Escaping strings for different languages
########################################################################

use strict;

package cpi_escape;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( javascript_esc perl_esc );
use lib ".";


#__END__
1;

#########################################################################
#       Return string with characters having special meaning in perl    #
#       strings escaped with backslashes.                               #
#########################################################################
sub perl_esc
    {
    $_ = $_[0];
    s/\\/\\\\/g;
    s/"/\\"/g;
    s/'/\\'/g;
    s/@/\\@/g;
    s/\$/\\\$/g;
    s/([^ -z])/uc sprintf("\\%03o",ord($1))/eg;
    return $_;
    }

#########################################################################
#       Return string with characters having special meaning in		#
#       javascript strings escaped with backslashes.			#
#########################################################################
sub javascript_esc
    {
    my( $str, $what, $to ) = @_;
    $what = '"' if( ! defined($what) );
    $to = "\\$what" if( ! defined($to) );
    $str =~ s/$what/$to/g;
    return $str;
    }

1;
