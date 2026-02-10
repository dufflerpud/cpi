#!/usr/bin/perl -w
#indx#	cpi_db.pm - Various routines for accessing databases
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
#doc#	cpi_db.pm - Various routines for accessing databases
########################################################################

use strict;

package cpi_db;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( db_cleanup db_gdbm db_gothere db_perlobj
 db_readable db_sql db_status db_unique db_writable dbadd
 dbarr dbclose dbdel dbdelkey dbforget dbget dbisin dbget_gdbm
 dbget_hash dbget_perlobj dbget_sql dbnew dbnew_gdbm
 dbnew_perlobj dbnew_sql dbnewkey dbopen_sql dbpop dbput
 dbput_gdbm dbput_hash dbput_perlobj dbput_sql dbread
 dbread_gdbm dbread_perlobj dbread_sql dbtest dbtype dbupdate
 dbwrite find_db new_sql_table
 DBread DBwrite DBpop DBclose DBget DBput DBdelkey DBadd DBdel DBnewkey );
use lib ".";

use cpi_compress_integer qw( compress_integer );
use cpi_config qw( read_config );
use cpi_file qw( cleanup autopsy register_cleanup write_file );
use cpi_lock qw( lock_file unlock_file );
use cpi_trace qw( stack_trace );
use cpi_inlist qw( inlist );
use cpi_vars;
use Data::Dumper;
use GDBM_File;
use DBI;
#__END__
1;

#########################################################################
#	Used to turn multiple indices into a single index for accessing	#
#	a one dimensional array (such as a database).  Also used for	#
#	combining multiple items of an array into one item to store in	#
#	such an array.							#
#########################################################################
sub dbarr
    {
    return join($cpi_vars::DBSEP,@_);
    }

#########################################################################
#	Returns type of database.					#
#########################################################################
my %DBTYPES =
    (
    "gdbm"	=> {	"pat"	=>"\\.db\$",
		    	"new"	=>\&dbnew_gdbm,
		    	"read"	=>\&dbread_gdbm,
		    	"write"	=>\&db_gdbm,
		    	"get"	=>\&dbget_hash,
		    	"put"	=>\&dbput_hash },
    "sql"	=> {	"pat"	=>"^DBI:.*:",
		    	"new"	=>\&dbnew_sql,
		    	"read"	=>\&dbread_sql,
		    	"write"	=>\&db_sql,
		    	"get"	=>\&dbget_sql,
		    	"put"	=>\&dbput_sql },
    "perlobj"	=> {	"pat"	=>"\\.po\$",
		    	"new"	=>\&dbnew_perlobj,
		    	"read"	=>\&dbread_perlobj,
		    	"write"	=>\&db_perlobj,
		    	"get"	=>\&dbget_hash,
		    	"put"	=>\&dbput_hash },
    );
sub dbtype
    {
    my( $dbname ) = @_;
    my $ret;
    foreach my $dbtype ( keys %DBTYPES )
        {
	if( $dbname =~ /$DBTYPES{$dbtype}{pat}/ )
	    {
	    $ret = $cpi_vars::db_type{$dbname} = $dbtype;
	    last;
	    }
	}
    &autopsy("Cannot identify [$dbname] database type.",1) if( ! $ret );
    #print STDERR "dbtype($dbname) = $ret.\n";
    return $ret;
    }

#########################################################################
#	Create an empty database.  Don't leave it open.			#
#	Invoke database specific handler for it (following).		#
#########################################################################
sub dbnew
    {
    my( $dbname ) = @_;
    return &{ $DBTYPES{ &dbtype($dbname) }{"new"} }( $dbname );
    }

#########################################################################
#	Perl object specific routine to create a new database.		#
#########################################################################
sub dbnew_perlobj
    {
    &write_file( $_[0], Dumper({}) );
    }

#########################################################################
#	GDBM specific routine to create a new database.			#
#	(An empty file will do)						#
#########################################################################
sub dbnew_gdbm
    {
    my( $dbname ) = @_;
    &write_file( $dbname, "" ); 
    &dbwrite( $dbname );
    %{$cpi_vars::databases{$dbname}} = ();
    &dbclose( $dbname );
    }

#########################################################################
#	An routine to examine a hash database and create the table	#
#	requests to create a corresponding SQL table.			#
#########################################################################
sub new_sql_table
    {
    my( $old_dbname, $new_dbname ) = @_;

    my($proto,$dbtype,$dbname,$username,$password)=split(':',$new_dbname);

    my $database = $dbname;
    my $allprivs = "ALL PRIVILEGES";
    my $userhost = "'$username'\@'localhost'";

    &dbread( $old_dbname );
    my @sql_cmds = ();
    my %seen_field = ();
    foreach my $k ( keys %{$cpi_vars::databases{$old_dbname}} )
        {
	my( $tbl, $rec, @fields ) = split($cpi_vars::DBSEP,$k);
	my $sqlfield = join($cpi_vars::SQLSEP,@fields);
	#print "TBL=$tbl REC=$rec [",join(",",@fields),"] sqlfield=[$sqlfield] v=[", $cpi_vars::databases{$old_dbname}{$k}, "]\n";
	push( @{$seen_field{$tbl}{$sqlfield}}, $rec );
	}

    foreach my $tbl ( sort keys %seen_field )
        {
	my $sep = " ";
	push( @sql_cmds, <<EOF0,
CREATE DATABASE $database;
GRANT $allprivs ON $database.* TO $userhost;
USE $database;
CREATE TABLE $tbl
 (
EOF0
	    " id int",
	    (map { ",\n $_ VARCHAR(100) DEFAULT NULL" }
		sort keys %{$seen_field{$tbl}} ), <<EOF1 );
 );
GRANT $allprivs ON TABLE $tbl TO $userhost;
EOF1
	}

    print join("",@sql_cmds);
    &cleanup(0);
    }

#########################################################################
#	SQL specific routine to create a new database.			#
#########################################################################
sub dbnew_sql
    {
    # SQL logic unimplemented
    }

#########################################################################
#	Return database entry at specified indices.  If we're looking	#
#	for an array, split result by DBSEP character.  This means	#
#	that we shouldn't store entries with DBSEPs in it.  Call DB	#
#	specific handler for reading (following).			#
#########################################################################
sub dbget
    {
    my( $dbname, @args ) = @_;
    &autopsy("XL(Cannot read [[" . join(",",@args) . "]]:"
        . "  database [[$dbname]] not open)")
        if( ($cpi_vars::DBSTATUS{$dbname}||"") eq "" );

    my $res = &{ $DBTYPES{ &dbtype($dbname) }{"get"} }($dbname,@args);

    if( ! wantarray )
	{ return $res; }
    if( ! defined($res) || $res eq "" )
	{ return (); }
    else
	{ return split($cpi_vars::DBSEP,$res); }
    }

#########################################################################
#	Return true if specified item (last argument) is in the list	#
#	specified.							#
#########################################################################
sub dbisin
    {
    my( $dbname, @args ) = @_;
    &autopsy("XL(Cannot read [[" . join(",",@args) . "]]:"
        . "  database [[$dbname]] not open)")
        if( ($cpi_vars::DBSTATUS{$dbname}||"") eq "" );
    my $check_for = pop( @args );

    my $res = &{ $DBTYPES{ &dbtype($dbname) }{"get"} }($dbname,@args);
    return undef if( ! defined($res) );
    return &inlist( $check_for, split($cpi_vars::DBSEP,$res) );
    }

#########################################################################
#	For perlobj or gdbm databases.					#
#########################################################################
sub dbget_hash
    {
    my( $dbname, @args ) = @_;
    my @problems;
    push( @problems, "Database not specified") if( ! $dbname );
    push( @problems, "No arguments specified to dbget_hash")
	if( ! @args || !defined( $args[0] ) );
    return $cpi_vars::databases{$dbname}{join($cpi_vars::DBSEP,@args)}
	if( ! @problems );
    &stack_trace( @problems );
    return undef;
    }

#########################################################################
#	For completeness.  We actually just call dbget_hash directly.	#
#########################################################################
sub dbget_gdbm		{ return &dbget_hash( @_ ); }
sub dbget_perlobj	{ return &dbget_hash( @_ ); }

#########################################################################
#	For SQL:							#
#########################################################################
sub dbget_sql
    {
    my( $dbname, $tablename, $recordname, @fieldnames ) = @_;
    my( $fieldname ) = join($cpi_vars::SQLSEP,@fieldnames);
    # SQL logic
    my $dbh = $cpi_vars::db_fh{$dbname};
    my $sth = $dbh->prepare(
        "SELECT '$fieldname' FROM '$tablename' WHERE id='$recordname'" );
    my @result = $sth->fetchrow_array();
    return $result[0];
    }

#########################################################################
#	Possible ways of modifying a database entry.			#
#	First entry of @_ is the name of the database.			#
#	Last entry of @_ is the value to put into, add or remove from	#
#	the database.							#
#########################################################################
sub dbput	{ &dbupdate( "put", @_ ); }
sub dbadd	{ &dbupdate( "add", @_ ); }
sub dbdel	{ &dbupdate( "del", @_ ); }
sub dbdelkey	{ &dbupdate( "put", @_, "" ); }

#########################################################################
#	dbput, dbadd or dbdel called to modify database.  Perform	#
#	preliminary verifications and then actually perform operation	#
#	based on first argument (put,add,del) calling db dependent	#
#	routines for writing (below).					#
#########################################################################
sub dbupdate
    {
    my $func	= shift(@_);	# First arg
    my $dbname	= shift(@_);	# Second arg
    my $val	= pop(@_);	# Last arg
    my @inds	= @_;		# Args in between second and last

    my( $ind ) = join($cpi_vars::DBSEP,@inds);
    my( $newval );
    &autopsy(
	"Cannot update [".join(",",@inds)."]:  database $dbname not open")
        if( $cpi_vars::DBSTATUS{$dbname} eq "" );
    &autopsy(
        "Cannot update [".join(",",@inds)."]:  database $dbname read-only")
        if( $cpi_vars::DBSTATUS{$dbname} eq "RO" );
    if( $func eq "put" )
	{ $newval = $val; }
    else
	{
	my( %SEENIND ) = ();
	my $fetched =
	    &{ $DBTYPES{$cpi_vars::db_type{$dbname}}{"get"} } ( $dbname, @inds );
	grep( $SEENIND{$_}++, split($cpi_vars::DBSEP, $fetched ) )
	    if( defined($fetched) );
	if( $func eq "add" )
	    { $SEENIND{$val} = 1; }
	elsif( $func eq "del" )
	    { $SEENIND{$val} = 0; }
	else
	    {
	    &autopsy(
	        "Unknown function $func for dbupdate for $dbname.");
	    }
	$newval =
	    join( $cpi_vars::DBSEP,
		grep( $SEENIND{$_}>0, sort keys %SEENIND ) );
	}

    &{ $DBTYPES{$cpi_vars::db_type{$dbname}}{"put"} } ( $dbname, @inds, $newval );

    #print "Setting {$dbname}{$ind} to [$newval].<br>\n";
    $cpi_vars::DBWRITTEN{$dbname}++;
    }

#########################################################################
#	Write data to gdbm or perlobj database.				#
#########################################################################
sub dbput_hash
    {
    my $dbname	= shift(@_);	# First arg
    my $val	= pop(@_);	# Last arg
    my @inds	= @_;		# Args between first and last arg

    return $cpi_vars::databases{$dbname}{join($cpi_vars::DBSEP,@inds)} = $val;
    }

#########################################################################
#	For completeness.  We actually just call dbput_hash directly.	#
#########################################################################
sub dbput_gdbm { return &dbput_hash( @_ ); }
sub dbput_perlobj { return &dbput_hash( @_ ); }

#########################################################################
#	For SQL:							#
#########################################################################
sub dbput_sql
    {
    my $dbname	= shift(@_);	# First arg
    my $val	= pop(@_);	# Last arg
    my @inds	= @_;		# Args between first and last arg

    my( $tablename, $recordname, @fieldnames ) = @inds;
    return if( $tablename !~ /Hospital_report/ || $recordname !~ /^\d+$/ );
    my ( $fieldname ) = join($cpi_vars::SQLSEP,@fieldnames);
    # SQL put logic
    my $dbh = $cpi_vars::db_fh{$dbname};
#    print
#	"Tablename=<", $tablename, ">\n",
#	"Recordname=<", $recordname, ">\n",
#	"Fieldnames=<", join("|",@fieldnames), ">\n",
#	"Fieldname=<", $fieldname, ">\n",
#	"val=<", $val, ">\n";
    my $cmd="UPDATE $tablename SET $fieldname = '$val' WHERE id='$recordname'";
    #print "[ $cmd ]\n";
    my $sth = $dbh->do( $cmd );
    }

#########################################################################
#	Open database for reading.  Invokes DB specific routines below.	#
#########################################################################
sub dbread
    {
    my( $dbname ) = @_;
    &stack_trace("Database not specified") if( ! $dbname );
#    &autopsy("Database $dbname already open for writing")
#	if( $cpi_vars::DBSTATUS{$dbname} eq "RW" );
    if(!defined($cpi_vars::DBSTATUS{$dbname}) || $cpi_vars::DBSTATUS{$dbname} eq "")
	{
	&{ $DBTYPES{ &dbtype($dbname) } {"read"} } ( $dbname );
	}
    no strict 'refs';
    push( @{$cpi_vars::db_stati{$dbname}}, $cpi_vars::DBSTATUS{$dbname} );
    use strict 'refs';
    $cpi_vars::DBSTATUS{$dbname} = "RO";
    }

#########################################################################
#	GDBM specific routines to open a database for reading only.	#
#########################################################################
sub dbread_gdbm
    {
    my( $dbname ) = @_;
    until( tie( %{$cpi_vars::databases{$dbname}}, 'GDBM_File', $dbname,
	&GDBM_READER, 0666 ) )
	{
	&autopsy("dbread_gdbm cannot tie $dbname for reading:  $!")
	    if( $! ne "Resource temporarily unavailable" );
	sleep(1);
	}
    }

#########################################################################
#	Perl object routines to open a database for reading only.	#
#########################################################################
sub dbread_perlobj
    {
    my( $dbname ) = @_;
    &read_config( $dbname, \%{$cpi_vars::databases{$dbname}} );
    }

#########################################################################
#	SQL specific routines to open a database for reading only.	#
#########################################################################
sub dbread_sql		{ return &dbopen_sql( @_ ); }
#########################################################################
#	Open database for reading and then flag it as writable.		#
#	This means that we'll store the modifications we've made and	#
#	write them back out when we close the database.  Invoke DB	#
#	specific routines below to do the actual database-open.		##
#########################################################################
sub dbwrite
    {
    my( $dbname ) = @_;
    &stack_trace("Database not specified") if( ! $dbname );
    if((($cpi_vars::DBSTATUS{$dbname}||"") ne "RW")
	&& ! grep( ($_||"") eq "RW", @{$cpi_vars::db_stati{$dbname}}))
	{
	&register_cleanup( \&db_cleanup );
	&lock_file( $dbname );
	&{ $DBTYPES{ &dbtype($dbname) } {"write"} } ( $dbname );
	}
    push( @{$cpi_vars::db_stati{$dbname}}, $cpi_vars::DBSTATUS{$dbname} );
    $cpi_vars::DBSTATUS{$dbname} = "RW";
    }

#########################################################################
#	GDBM specific routines to open a database for writing.		#
#########################################################################
sub db_gdbm
    {
    my( $dbname ) = @_;
    untie( %{$cpi_vars::databases{$dbname}} ) if( $cpi_vars::DBSTATUS{$dbname} );
    until( tie( %{$cpi_vars::databases{$dbname}}, 'GDBM_File', $dbname,
	&GDBM_WRITER, 0666 ) )
	{
	my $errcode = $!;
	&unlock_file( $dbname );
	&autopsy("db_gdbm cannot tie $dbname for writing:  $!")
	    if( $errcode ne "Resource temporarily unavailable" );
	sleep(1);
	&lock_file( $dbname );
	}
    }

#########################################################################
#	Perl object routines to open a database for writing.		#
#	Since all writing is done when the database is closed, we only	#
#	read the database in here.					#
#########################################################################
sub db_perlobj
    {
    my( $dbname ) = @_;
    &read_config( $dbname, \%{$cpi_vars::databases{$dbname}} )
	if( ($cpi_vars::DBSTATUS{$dbname}||"") eq "" );
    }

#########################################################################
#	SQL specific routines to open a database for writing.		#
#########################################################################
sub db_sql		{ return &dbopen_sql( @_ ); }

#########################################################################
#	At least for now, opening SQL for reading and writing is same.	#
#########################################################################
sub dbopen_sql
    {
    my( $dbspec ) = @_;
    my( $proto, $dbtype, $dbname, $username, $password ) = split(':',$dbspec);
    $cpi_vars::db_fh{$dbspec} = DBI->connect(
        "${proto}:${dbtype}:${dbname}", $username, $password,
	{ RaiseError => 1 }
	);
    print "db_fh{$dbspec} set to $cpi_vars::db_fh{$dbspec}.\n";
    }

#########################################################################
#	Print status of database provided in argument.			#
#########################################################################
sub db_status
    {
    my( $dbname ) = @_;
    my( $ind ) = 0;
    my $nl = ( $cpi_vars::THIS ? "<br>\n" : "\n" );
    my $spacing = ( $cpi_vars::THIS ? "<dd>" : "    " );

    my @toprint =
	( "${nl}DBWRITTEN{$dbname} = $cpi_vars::DBWRITTEN{$dbname}${nl}" );
    foreach my $stat ( @{$cpi_vars::db_stati{$dbname}} )
        {
	push( @toprint, "${spacing}db_stati_$dbname [$ind] = $stat${nl}" );
	$ind++;
	}
    push( @toprint, "Current status{$dbname} = $cpi_vars::DBSTATUS{$dbname}$nl$nl" );
    print @toprint;
    }

#########################################################################
#	Print status of database provided in argument.			#
#########################################################################
sub db_gothere
    {
    my( $lnum, $msg, $dbname ) = @_;
    my( $ind ) = 0;
    my $nl = "\n";

    &stack_trace("$lnum stack trace {$msg}:");
    my @toprint =
	( "${nl}DBWRITTEN{$dbname} = ", $cpi_vars::DBWRITTEN{$dbname}||"UNDEF", $nl);
    if( $cpi_vars::db_stati{$dbname} )
	{
	push( @toprint, "db_stati = ", scalar( @{$cpi_vars::db_stati{$dbname}} ), ":\n" );
	foreach my $stat ( @{$cpi_vars::db_stati{$dbname}} )
	    {
	    push( @toprint, "    db_stati_$dbname [$ind] = ",$stat||"UNDEF",$nl );
	    $ind++;
	    }
	}
    push( @toprint, "Current status{$dbname} = ",
        $cpi_vars::DBSTATUS{$dbname}||"UNDEF",
	"$nl$nl" );
    print STDERR @toprint;
    }

#########################################################################
#	Return database to state prior to last dbread or dbwrite.	#
#	This may involve closing it and then opening it again.		#
#########################################################################
sub dbpop
    {
    my( $dbname ) = @_;
    my $dbt = &dbtype( $dbname );
    if( $cpi_vars::DBSTATUS{$dbname} eq "RO" )
	{
 	if( ! grep(($_||"") eq "RW", @{$cpi_vars::db_stati{$dbname}})	&&
 	    ! grep(($_||"") eq "RO", @{$cpi_vars::db_stati{$dbname}})	)
	    {
	    if( $dbt eq "perlobj" )
		{ }	# Nothing to do since object is in memory
	    elsif( $dbt eq "gdbm" )
		{ dbmclose( %{ $cpi_vars::databases{$dbname} } ); }
	    elsif( $dbt eq "sql" )
		{ $cpi_vars::db_fh{$dbname}->disconnect(); }
	    else
		{ &autopsy("Unknown database type [$_] for $dbname."); }
	    }
	}
    elsif( ($cpi_vars::DBSTATUS{$dbname}||"") eq "RW" )
	{
 	if( ! grep(($_||"") eq "RW", @{$cpi_vars::db_stati{$dbname}}) )
	    {
	    if( $dbt eq "perlobj" )
		{
		&write_file($dbname,
		    Dumper(\%{$cpi_vars::databases{$dbname}}))
		    if( $cpi_vars::DBWRITTEN{$dbname} > 0 );
		}
	    elsif( $dbt eq "gdbm" )
		{
		dbmclose( %{ $cpi_vars::databases{$dbname} } );
 		if( grep(($_||"") eq "RO", @{$cpi_vars::db_stati{$dbname}}) )
		    {
		    until(
			tie(%{$cpi_vars::databases{$dbname}},'GDBM_File',$dbname,
			    &GDBM_READER, 0666 ) )
			{
			&autopsy("Cannot open $dbname for writing:  $!")
		    	    if( $! ne "Resource temporarily unavailable" );
			}
		    }
		}
	    elsif( $dbt eq "sql" )
		{
		#$cpi_vars::db_fh{$dbname}->commit();
		$cpi_vars::db_fh{$dbname}->disconnect();
		}
	    else
		{ &autopsy("Unknown database type [$_] for $dbname."); }
	    &unlock_file( $dbname );
	    $cpi_vars::DBWRITTEN{$dbname} = 0;
	    }
	}
    else
        { &autopsy("dbpop failed:  Database $dbname not open"); }
    $cpi_vars::DBSTATUS{$dbname} = pop( @{$cpi_vars::db_stati{$dbname}} );
    }

#########################################################################
#	Shut the database down, no matter how many times it has been	#
#	opened.  If there is a lock, it will unlock it.			#
#########################################################################
sub dbclose
    {
    my( $dbname ) = @_;
    while( ($cpi_vars::DBSTATUS{$dbname}||"") ne "" )
        { &dbpop($dbname); }
    }

#########################################################################
#	Forget we had a particular database opened.  Used for forked	#
#	code in the child process.  If the original process had the	#
#	database open for writing, the parent will be responsible for	#
#	writing	the changes it made out and cleaning up locks, etc.	#
#########################################################################
sub dbforget
    {
    my( $dbname ) = @_;
    while( $cpi_vars::DBSTATUS{$dbname} ne "" )
        { $cpi_vars::DBSTATUS{$dbname} = pop( @{$cpi_vars::db_stati{$dbname}} ); }
    $cpi_vars::DBWRITTEN{$dbname} = 0;
    %{$cpi_vars::databases{$dbname}} = ();	# (Shouldn't be necessary)
    }

#########################################################################
#	Return status of database specified in argument.		#
#########################################################################
sub db_readable { return ( ($cpi_vars::DBSTATUS{$_[0]}||"") ne ""   ); }
sub db_writable { return ( ($cpi_vars::DBSTATUS{$_[0]}||"") eq "RW" ); }

#########################################################################
#	Return an ever increasing integer for database.  Useful for	#
#	creating new record names.  First integer will be 1.		#
#########################################################################
sub db_unique
    {
    my( $dbname, $nm ) = @_;
    $nm |= "unique";
    &dbwrite( $dbname );
    my( $ret ) = (&dbget( $dbname, $nm ) || 0) + 1;
    &dbput( $dbname, $nm, $ret );
    &dbpop( $dbname );
    return $ret;
    }

#########################################################################
#	Return an ever increasing string that can be used as an index	#
#	into database.  Useful for creating new record names.		#
#########################################################################
sub dbnewkey
    {
    return &compress_integer( &db_unique(@_) );
    }

#########################################################################
#	Lots of testing done through this hook.				#
#########################################################################
sub dbtest
    {
    my( $testdb ) = "/tmp/testdb";
    &dbwrite( $testdb );
    &dbwrite( $testdb );
    &dbwrite( $testdb );
    }

#########################################################################
#    $cpi_vars::ACCOUNTDB="$cpi_vars::COMMONDIR/accounts.db";
#	Figure out which DB to use for this program.			#
#########################################################################
sub find_db
    {
    my( $base, @EXTS ) = @_;

    @cpi_vars::DB_EXTS if(0);			# Get rid of 'only used once' warnings
    @EXTS = @cpi_vars::DB_EXTS if( ! @EXTS );

    foreach my $ext ( @EXTS )
	{
	foreach my $attempt
	    (
	    "$base.$cpi_vars::PROG.$cpi_vars::WEBSITE$ext",
	    "$base.$cpi_vars::PROG$ext",
	    "$base.$cpi_vars::WEBSITE$ext",
	    "$base$ext"
	    )
	    {
	    return $attempt if( -f $attempt );
	    }
	}
    print STDERR "Could not find match for base=$base ext=[",join(" ",@EXTS),"] PROG=$cpi_vars::PROG WEBSITE=$cpi_vars::WEBSITE.\n";
    return undef;
    }

#########################################################################
#	Close any open databases.					#
#########################################################################
sub db_cleanup
    {
    grep( &dbclose($_), keys %cpi_vars::databases );
    }

#########################################################################
#	Avoid some typing.  Make prettier code.				#
#	Most applications use only one database for anything other	#
#	than logging ($DB).						#
#########################################################################
sub DBread	{ return &dbread	( $cpi_vars::DB	);	}
sub DBwrite	{ return &dbwrite	( $cpi_vars::DB	);	}
sub DBpop	{ return &dbpop		( $cpi_vars::DB	);	}
sub DBclose	{ return &dbclose	( $cpi_vars::DB	);	}
sub DBget	{ return &dbget		( $cpi_vars::DB,@_);	}
sub DBput	{ return &dbput		( $cpi_vars::DB,@_);	}
sub DBdelkey	{ return &dbdelkey	( $cpi_vars::DB,@_);	}
sub DBadd	{ return &dbadd		( $cpi_vars::DB,@_);	}
sub DBdel	{ return &dbdel		( $cpi_vars::DB,@_);	}
sub DBnewkey	{ return &dbnewkey	( $cpi_vars::DB,@_);	}
1;
