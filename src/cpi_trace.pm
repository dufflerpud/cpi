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

package cpi_trace;
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
#	Return a trace as a string for use in fatal, etc.		#
#########################################################################
sub get_trace
    {
    my @ret;
    for( my $i=0; 1; $i++ )
	{
	my($pack,$file,$line,$subname,$hasargs,$wantarray) = caller($i);
	return @ret if( ! $pack );
	push( @ret, "${file}:$line $subname" );
	}
    }

#########################################################################
#	Print an error message and die with a stack trace.		#
#########################################################################
sub stack_trace
    {
    my( @problems ) = @_;
    print STDERR join("\n\t",join("\n",@problems).":",&get_trace()), "\n";
    }

1;
