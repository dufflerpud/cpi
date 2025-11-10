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

package cpi_compress_integer;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( compress_integer );
use lib ".";


#__END__
1;
#########################################################################
#	Convert a number to a more compact string, basically base 62.	#
#	We could have had more digits to COMPACT_LEX, such as "_", but	#
#	decided not to because once this was used for generating unique	#
#	ids and changing the character set would mean potential		#
#	conflicts.  Useful for database keys.				#
#########################################################################
my @COMPACT_LEX = ( '0'..'9', 'A'..'Z', 'a'..'z' );
my $COMPLEX_LEX_SIZE = scalar(@COMPACT_LEX);
sub compress_integer
    {
    my ( $num ) = @_;
    $num =~ s/[^\d]//g;		# Force input to be an integer
    my @compact=();
    do  {
	push( @compact, $COMPACT_LEX[$num % $COMPLEX_LEX_SIZE] );
	} while($num=int($num/$COMPLEX_LEX_SIZE));
    return join("",reverse(@compact));
    }
1;
