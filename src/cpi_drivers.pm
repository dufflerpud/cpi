#!/usr/bin/perl -w
#indx#	cpi_drivers.pm - Files for reading directory of different handlers
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
#doc#	cpi_drivers.pm - Files for reading directory of different handlers
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
