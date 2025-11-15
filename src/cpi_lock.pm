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

package cpi_lock;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( lock_file unlock_file );
use lib ".";

use cpi_file qw( write_file read_file );
use cpi_trace qw( get_trace );
use cpi_vars;

#__END__
1;

#########################################################################
#       Check if file is locked.  If not locked, lock it.               #
#       Returns true if lock successful, false if someone else has	#
#       the lock.							#
#########################################################################
my %lock_trace_file;
sub lock_file
    {
    my( $resource_name ) = @_;
    my $pid = $$;
    my $lockname = "$resource_name.lock";
    my $contents;
    my $trace_file;

    if( $cpi_vars::LOCK_DEBUG )
	{
	$trace_file=$lock_trace_file{$resource_name}="$resource_name.trace.$pid";
	$contents = join("\n",&get_trace(),"");
	&write_file( $trace_file, $contents );
	}

    while( ! symlink( $pid, $lockname ) )	# Works because symlink() is atomic
        {
	if( my $old_pid=readlink($lockname) )
	    {
	    if( $contents )
		{
		&write_file( $trace_file,
		    join("\n",
			$contents,
			"HOLDING ON ${old_pid}:",
			&read_file( "$resource_name.trace.$old_pid", "?" ) ) );
		}
            if( $cpi_vars::LOCK_BREAK_STALE && ! -e "/proc/$old_pid" )
	        {
		unlink( $lockname );
		print STDERR "Breaking ${old_pid}'s lock for $resource_name.\n";
		}
	    else
		{ sleep(1); }
	    }
	}

    if( $contents )
        {
	unlink( "$resource_name.trace.current" );
	symlink( $trace_file, "$resource_name.trace.current" );
	}
    return 1;
    }

#########################################################################
#       By removing the link previously put there by a lock_file,	#
#       we allow one of the processes waiting on the lock file in.	#
#########################################################################
sub unlock_file
    {
    my( $resource_name ) = @_;
    if( my $trace_file = $lock_trace_file{$resource_name} )
        {
	unlink( "$resource_name.trace.current" );
	unlink( $trace_file );
	undef $lock_trace_file{$resource_name};
	}
    unlink( "$resource_name.lock" );
    }

1;
