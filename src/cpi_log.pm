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

package cpi_log;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( log );
use lib ".";

use cpi_vars;
#__END__
1;

#########################################################################
#	Log a message.							#
#########################################################################
my $log_opened = 0;
sub log
    {
    my( $msg ) = @_;
    $msg =~ s/XL\((.*?)\)/$1/g;
    my($sec,$min,$hour,$mday,$month,$year) = localtime(time);
    $cpi_vars::PROG if(0);	# Get rid of only used once warnings
    my $str = sprintf( "%02d/%02d/%04d %02d:%02d:%02d %s %d:  %s\n",
        $month+1,$mday,$year+1900,$hour,$min,$sec,$cpi_vars::PROG,$$,$msg);
    if( ! $log_opened )
	{
	open( CLOG, ">> $cpi_vars::ACCOUNTING_LOG" ) ||
	    die "Cannot append messages to $cpi_vars::ACCOUNTING_LOG:  $!\n" .
	    	"Message was:  $str";
	$log_opened = 1;
	}
    syswrite CLOG, $str;
    }

1;
