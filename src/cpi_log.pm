#!/usr/bin/perl -w
#indx#	cpi_log.pm - Standardize logger
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
#doc#	cpi_log.pm - Standardize logger
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
