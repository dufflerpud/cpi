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

package cpi_copy_db;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw();
use lib ".";

use cpi_config;
use cpi_db;
use cpi_file;
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
    &cpi_file::fatal("Must specify an output file") if(!defined($outfile));
    &cpi_db::dbread( $dbname );
    &cpi_file::write_file( $outfile,
	Dumper( \%{$cpi_vars::databases{$dbname}} ) );
    &cpi_file::cleanup(0);
    }

#########################################################################
#	Read an ascii representation of the specified database.		#
#########################################################################
sub undumpdb
    {
    my( $dbname, $infile ) = @_;
    &cpi_file::fatal("Must specify an input file") if(!defined($infile));
    my %swallow_db;
    open(TOUCHFILE,">$dbname")|| &cpi_file::fatal("Cannot truncate $dbname:  $!");
    chmod( 0666, $dbname) || &cpi_file::fatal("Cannot chmod(0666,$dbname):  $!");
    close(TOUCHFILE);
    tie( %swallow_db, 'GDBM_File', $dbname, &GDBM_WRITER, 0666 ) ||
        &cpi_file::fatal("undumpdb gdbm tie failed for ${dbname}:  $!");
    &cpi_config::read_config( $infile, \%swallow_db );
    dbmclose( %swallow_db );
    &cpi_file::cleanup(0);
    }

#########################################################################
#########################################################################
sub copydb
    {
    my( $old_dbname, $new_dbname ) = @_;

    &cpi_db::dbread( $old_dbname );
    my $old_dbtype = $cpi_vars::db_type{$old_dbname};
    my $old_ishash = grep( $_ eq $old_dbtype, "gdbm", "perlobj" );

    &cpi_db::dbnew( $new_dbname );
    &cpi_db::dbwrite( $new_dbname );
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
		&cpi_db::dbput( $new_dbname, $tbl, $rec, $fieldname, $val );
		}
	    }
	}
    $cpi_vars::DBWRITTEN{$new_dbname}++;
    &cpi_db::dbclose( $old_dbname );
    &cpi_db::dbclose( $new_dbname );
    &cpi_file::cleanup( 0 );
    }

1;
