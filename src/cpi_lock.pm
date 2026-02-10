#!/usr/bin/perl -w
#indx#	cpi_lock.pm - Simple locking (depends on symlinks being atomic)
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
#doc#	cpi_lock.pm - Simple locking (depends on symlinks being atomic)
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
