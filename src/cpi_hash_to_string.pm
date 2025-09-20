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

package cpi_hash_to_string;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw();
use lib ".";

use cpi_escape;
#__END__
1;
#########################################################################
#       Return string that would initialize a hash string.              #
#########################################################################
sub hash_to_string
    {
    my $hash_to_do = $_[0];

    my( $str ) = '%{$_} = (';
    my( $sep ) = "\n";
    my( $k );
    foreach $k ( sort keys %$hash_to_do )
        {
        my( $v ) = ${$hash_to_do}{$k};
        next if( $v eq "" );
        $str .= ("$sep\"".&cpi_escape::perl_esc($k). "\", \"".&cpi_escape::perl_esc($v)."\"");
        $sep = ",\n";
        }
    $str .= "\n);\n1;\n";
    return $str;
    }
1;
