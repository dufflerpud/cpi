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

package cpi_drivers;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( get_drivers device_debug );
use lib ".";

use cpi_file qw( read_file files_in );
use cpi_template qw( template );

our %fq_drivers;
#__END__
1;

#########################################################################
#	Get drivers							#
#########################################################################
sub get_drivers
    {
    my( $dirname, $driver ) = @_;
    my %drivers;
    $driver ||= "driver.pl";
    foreach my $filename ( &files_in( $dirname ) )
        {
	my $driver_name;
	my $fqn;
	my $driver_dir;
	if( $filename =~ /^(.*)\.pl$/ )
	    {
	    $driver_dir = $dirname;
	    $driver_name = $1;
	    $fqn = "$dirname/$filename";
	    }
	else
	    {
	    $driver_dir = "$dirname/$filename";
	    $fqn = "$driver_dir/$driver";
	    $driver_name = $filename if( -e $fqn );
	    }
	if( $driver_name )
	    {
	    $drivers{$driver_name} = $cpi_drivers::fq_drivers{$fqn} =
	    	{
		name		=> $driver_name,
		fqn		=> $fqn,
		dir		=> $driver_dir
		};
	    #print "About to eval driver $driver_name from $fqn...\n";
	    my $contents =
		&cpi_template::template( $fqn,
		    "DRIVER", "cpi_drivers::fq_drivers{'$fqn'}",
		    "%%DRIVER_NAME%%", $driver_name );
	    $contents =~ s/(my \$cpi_drivers::.*?);/#$1/ms;
	    eval( $contents );
	    print "eval returned [$@]\n" if( $@ );
	    #print "Done eval driver $driver_name.\n";
	    }
	}
    return %drivers;
    }

#########################################################################
#	Print out debug information.					#
#########################################################################
sub device_debug
    {
    my( $filename, $line, $msg ) = @_;;
    printf("%s %d:  %s\n",$filename,$line,$msg);
    }

1;
