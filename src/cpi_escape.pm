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

package cpi_escape;
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
