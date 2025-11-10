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

package cpi_drivers;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( this );
our @EXPORT = qw( get_drivers add_driver device_debug get_driver );
use lib "/usr/local/lib/perl";

use Data::Dumper;
use cpi_file qw( read_file files_in autopsy );
use cpi_filename qw( dirname );
use cpi_template qw( template );

our %fq_drivers;
#__END__
1;

#########################################################################
#	Eval the specified file which will add information to a driver	#
#	table.								#
#########################################################################
sub add_driver
    {
    my( $driverp, $filename, $driver_name ) = @_;
    #print __FILE__," ",__LINE__,":  this=[", Dumper($driverp), "]\n";

    if( -r $filename )
	{
	#&autopsy("$filename not found.") if( ! -r $filename );
	$driverp->{$driver_name} = $cpi_drivers::fq_drivers{$filename} =
	    {
	    name	=> $driver_name,
	    fqn		=> $filename,
	    dir		=> &dirname( $filename )
	    };
	do $filename or &autopsy("Perl error with $filename:\n(\@=$@)\n(!=$!)");
#	#print "About to eval driver $driver_name from $fqn...\n";
#	my $contents =
#	    &cpi_template::template( $filename,
#		"DRIVER", "cpi_drivers::fq_drivers{'$filename'}",
#		"%%DRIVER_NAME%%", $driver_name );
#	$contents =~ s/(my \$cpi_drivers::.*?);/#$1/ms;
#	#print STDERR "eval $driver_name [$contents]\n";
#	eval( $contents );
#	print "eval returned [$@]\n" if( $@ );
#	#print "Done eval driver $driver_name.\n";
	}
    }

#########################################################################
#	Get drivers							#
#########################################################################
sub get_drivers
    {
    my( $dirname, $defdriver ) = @_;
    $defdriver ||= "driver.pl";
    my %drivers;
    #print __FILE__," ",__LINE__,":  drivers=[", Dumper(\%drivers), "]\n";
    foreach my $dirfile ( &files_in( $dirname ) )
        {
	if( $dirfile =~ /(.*).pl$/ )
	    { &add_driver( \%drivers, "$dirname/$dirfile", $1 ); }
	else
	    {
	    my $filename = "$dirname/$dirfile/$defdriver";
	    if( -r $filename )
		{
		#&device_debug( __FILE__, __LINE__, "filename=[$filename]" );
		&add_driver( \%drivers, $filename, $dirfile )
		}
	    }
	}
    #print __FILE__," ",__LINE__,":  drivers=[", Dumper(\%drivers), "]\n";
    return %drivers;
    }

#########################################################################
#	Return a pointer to the driver structure associated with the	#
#	file name provided.						#
#########################################################################
sub get_driver
    {
    my( $filename ) = @_;
    return $fq_drivers{ $filename };
    }

#########################################################################
#	Print out debug information.					#
#########################################################################
sub device_debug
    {
    my( $filename, $line, $msg ) = @_;;
    printf STDERR ("%s %d:  %s\n",$filename,$line,$msg);
    }

1;
