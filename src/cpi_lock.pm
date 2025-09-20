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

package cpi_lock;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw();
use lib ".";

use cpi_file;
use cpi_trace;
#__END__
1;

#########################################################################
#       Check if file is locked.  If not locked, lock it.               #
#########################################################################
sub lock_check
    {
    return symlink( "/$$", "$_[0].lock" );
    }

#########################################################################
#       Keep checking the lock until we get it.                         #
#########################################################################
sub lock_file
    {
    my( $lockname ) = @_;
    my $trace_name	= "$lockname.trace";
    my $trace_new	= "$trace_name.$$";
    my $trace_current	= "$trace_name.current";
    my $trace_last	= "$trace_name.last";

    &cpi_file::write_file( $trace_new, join("\n",&cpi_trace::get_trace())."\n" );
    until( &lock_check( $lockname ) )
        { sleep(1); }
    rename( $trace_current, $trace_last );	# First time ever will fail
    rename( $trace_new, $trace_current );	# Should always work
    }

#########################################################################
#       By removing the link previously put there by a lock_check,    #
#       we allow one of the processes waiting on the lock file in.      #
#########################################################################
sub unlock_file
    {
    unlink( "$_[0].lock" );
    }

1;
