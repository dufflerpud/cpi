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

package cpi_copy_db;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( copydb dumpdb undumpdb );
use lib ".";

use cpi_config qw( read_config );
use cpi_db qw( dbclose dbnew dbput dbread dbwrite );
use cpi_file qw( cleanup autopsy write_file );
use cpi_vars;
use Data::Dumper;
#__END__
1;

#########################################################################
#	Create an ascii representation of the specified database.	#
#########################################################################
sub dumpdb
    {
    my( $dbname, $outfile ) = @_;
    &autopsy("Must specify an output file") if(!defined($outfile));
    &dbread( $dbname );
    &write_file( $outfile,
	Dumper( \%{$cpi_vars::databases{$dbname}} ) );
    &cleanup(0);
    }

#########################################################################
#	Read an ascii representation of the specified database.		#
#########################################################################
sub undumpdb
    {
    my( $dbname, $infile ) = @_;
    &autopsy("Must specify an input file") if(!defined($infile));
    my %swallow_db;
    open(TOUCHFILE,">$dbname")|| &autopsy("Cannot truncate $dbname:  $!");
    chmod( 0666, $dbname) || &autopsy("Cannot chmod(0666,$dbname):  $!");
    close(TOUCHFILE);
    tie( %swallow_db, 'GDBM_File', $dbname, &GDBM_WRITER, 0666 ) ||
        &autopsy("undumpdb gdbm tie failed for ${dbname}:  $!");
    &read_config( $infile, \%swallow_db );
    dbmclose( %swallow_db );
    &cleanup(0);
    }

#########################################################################
#########################################################################
sub copydb
    {
    my( $old_dbname, $new_dbname ) = @_;

    &dbread( $old_dbname );
    my $old_dbtype = $cpi_vars::db_type{$old_dbname};
    my $old_ishash = grep( $_ eq $old_dbtype, "gdbm", "perlobj" );

    &dbnew( $new_dbname );
    &dbwrite( $new_dbname );
    my $new_dbtype = $cpi_vars::db_type{$new_dbname};
    my $new_ishash = grep( $_ eq $new_dbtype, "gdbm", "perlobj" );

    if( $old_ishash )
        {
	if( $new_ishash )
	    {
	    %{$cpi_vars::databases{$new_dbname}} =
		%{$cpi_vars::databases{$old_dbname}};
	    }
	else
	    {
	    foreach my $k ( keys %{$cpi_vars::databases{$old_dbname}} )
	        {
		my( $tbl, $rec, @fieldnames ) = split($cpi_vars::DBSEP,$k);
		my $fieldname = join( $cpi_vars::SQLSEP, @fieldnames );
		my $val = $cpi_vars::databases{$old_dbname}{$k};
		print "xfer $val to [",join(",",$tbl,$rec,@fieldnames),"]\n";
		&dbput( $new_dbname, $tbl, $rec, $fieldname, $val );
		}
	    }
	}
    $cpi_vars::DBWRITTEN{$new_dbname}++;
    &dbclose( $old_dbname );
    &dbclose( $new_dbname );
    &cleanup( 0 );
    }

1;
