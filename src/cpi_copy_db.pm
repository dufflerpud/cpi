#!/usr/bin/perl -w
#indx#	cpi_copy_db.pm - Copy database from one format to another
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
#doc#	cpi_copy_db.pm - Copy database from one format to another
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
