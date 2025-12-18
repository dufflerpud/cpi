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

package cpi_trace;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( get_trace stack_trace );
use lib ".";
use Devel::StackTrace;

#__END__
1;

#########################################################################
#	Return a trace as a string for use in autopsy, etc.		#
#########################################################################
sub get_trace
    {
    #   my @ret;
    #   for( my $i=0; 1; $i++ )
    #	{
    #	my($pack,$file,$line,$subname,$hasargs,$wantarray) = caller($i);
    #	return @ret if( ! $pack );
    #	push( @ret, "${file}:$line $subname" );
    #	}
    my $trace_obj = Devel::StackTrace->new();
    return $trace_obj->as_string;
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
