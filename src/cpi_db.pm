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
    return join($DBSEP,@_);
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
	    $ret = $db_type{$dbname} = $dbtype;
	    last;
	    }
	}
    &fatal("Cannot identify [$dbname] database type.",1) if( ! $ret );
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
    &write_file( $_[0], "" );
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
    foreach my $k ( keys %{$databases{$old_dbname}} )
        {
	my( $tbl, $rec, @fields ) = split($DBSEP,$k);
	my $sqlfield = join($SQLSEP,@fields);
	#print "TBL=$tbl REC=$rec [",join(",",@fields),"] sqlfield=[$sqlfield] v=[", $databases{$old_dbname}{$k}, "]\n";
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
    &fatal("XL(Cannot read [[" . join(",",@args) . "]]:"
        . "  database [[$dbname]] not open)")
        if( ($DBSTATUS{$dbname}||"") eq "" );

    my $res = &{ $DBTYPES{ &dbtype($dbname) }{"get"} }($dbname,@args);

    if( ! wantarray )
	{ return $res; }
    if( ! defined($res) || $res eq "" )
	{ return (); }
    else
	{ return split($DBSEP,$res); }
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
    return $databases{$dbname}{join($DBSEP,@args)} if( ! @problems );
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
    my( $fieldname ) = join($SQLSEP,@fieldnames);
    # SQL logic
    my $dbh = $db_fh{$dbname};
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

    my( $ind ) = join($DBSEP,@inds);
    my( $newval );
    &fatal(
	"Cannot update [".join(",",@inds)."]:  database $dbname not open")
        if( $DBSTATUS{$dbname} eq "" );
    &fatal(
        "Cannot update [".join(",",@inds)."]:  database $dbname read-only")
        if( $DBSTATUS{$dbname} eq "RO" );
    if( $func eq "put" )
	{ $newval = $val; }
    else
	{
	my( %SEENIND ) = ();
	my $fetched =
	    &{ $DBTYPES{$db_type{$dbname}}{"get"} } ( $dbname, @inds );
	grep( $SEENIND{$_}++, split($DBSEP, $fetched ) )
	    if( defined($fetched) );
	if( $func eq "add" )
	    { $SEENIND{$val} = 1; }
	elsif( $func eq "del" )
	    { $SEENIND{$val} = 0; }
	else
	    {
	    &fatal(
	        "Unknown function $func for dbupdate for $dbname.");
	    }
	$newval =
	    join( $DBSEP,
		grep( $SEENIND{$_}>0, sort keys %SEENIND ) );
	}

    &{ $DBTYPES{$db_type{$dbname}}{"put"} } ( $dbname, @inds, $newval );

    #print "Setting {$dbname}{$ind} to [$newval].<br>\n";
    $DBWRITTEN{$dbname}++;
    }

#########################################################################
#	Write data to gdbm or perlobj database.				#
#########################################################################
sub dbput_hash
    {
    my $dbname	= shift(@_);	# First arg
    my $val	= pop(@_);	# Last arg
    my @inds	= @_;		# Args between first and last arg

    return $databases{$dbname}{join($DBSEP,@inds)} = $val;
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
    my ( $fieldname ) = join($SQLSEP,@fieldnames);
    # SQL put logic
    my $dbh = $db_fh{$dbname};
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
#    &fatal("Database $dbname already open for writing")
#	if( $DBSTATUS{$dbname} eq "RW" );
    if(!defined($DBSTATUS{$dbname}) || $DBSTATUS{$dbname} eq "")
	{
	&{ $DBTYPES{ &dbtype($dbname) } {"read"} } ( $dbname );
	}
    no strict 'refs';
    push( @{$db_stati{$dbname}}, $DBSTATUS{$dbname} );
    use strict 'refs';
    $DBSTATUS{$dbname} = "RO";
    }

#########################################################################
#	GDBM specific routines to open a database for reading only.	#
#########################################################################
sub dbread_gdbm
    {
    my( $dbname ) = @_;
    until( tie( %{$databases{$dbname}}, 'GDBM_File', $dbname,
	&GDBM_READER, 0666 ) )
	{
	&fatal("dbread_gdbm cannot tie $dbname for reading:  $!")
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
    &read_config( $dbname, \%{$databases{$dbname}} );
    }

#########################################################################
#	SQL specific routines to open a database for reading only.	#
#########################################################################
sub dbread_sql		{ return &dbopen_sql( @_ ); }
#########################################################################
#	Open database for reading and then flag it as writable.		#
#	This means that we'll store the modifications we've made and	#
#	write them back out when we close the database.  Invoke DB	#
#	specific routines below to do the actual database-open.		#
#########################################################################
sub dbwrite
    {
    my( $dbname ) = @_;
    &stack_trace("Database not specified") if( ! $dbname );
    if((($DBSTATUS{$dbname}||"") ne "RW")
	&& ! grep( ($_||"") eq "RW", @{$db_stati{$dbname}}))
	{
	&register_cleanup( \&db_cleanup );
	&lock_file( $dbname );
	&{ $DBTYPES{ &dbtype($dbname) } {"write"} } ( $dbname );
	}
    push( @{$db_stati{$dbname}}, $DBSTATUS{$dbname} );
    $DBSTATUS{$dbname} = "RW";
    }

#########################################################################
#	GDBM specific routines to open a database for writing.		#
#########################################################################
sub db_gdbm
    {
    my( $dbname ) = @_;
    untie( %{$databases{$dbname}} ) if( $DBSTATUS{$dbname} );
    until( tie( %{$databases{$dbname}}, 'GDBM_File', $dbname,
	&GDBM_WRITER, 0666 ) )
	{
	my $errcode = $!;
	&unlock_file( $dbname );
	&fatal("db_gdbm cannot tie $dbname for writing:  $!")
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
    &read_config( $dbname, \%{$databases{$dbname}} )
	if( ($DBSTATUS{$dbname}||"") eq "" );
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
    $db_fh{$dbspec} = DBI->connect(
        "${proto}:${dbtype}:${dbname}", $username, $password,
	{ RaiseError => 1 }
	);
    print "db_fh{$dbspec} set to $db_fh{$dbspec}.\n";
    }

#########################################################################
#	Print status of database provided in argument.			#
#########################################################################
sub db_status
    {
    my( $dbname ) = @_;
    my( $ind ) = 0;
    my $stat;
    my $nl = ( $THIS ? "<br>\n" : "\n" );
    my $spacing = ( $THIS ? "<dd>" : "    " );

    my @toprint =
	( "${nl}DBWRITTEN{$dbname} = $DBWRITTEN{$dbname}${nl}" );
    foreach $stat ( @{$db_stati{$dbname}} )
        {
	push( @toprint, "${spacing}db_stati_$dbname [$ind] = $stat${nl}" );
	$ind++;
	}
    push( @toprint, "Current status{$dbname} = $DBSTATUS{$dbname}$nl$nl" );
    print @toprint;
    }

#########################################################################
#	Return database to state prior to last dbread or dbwrite.	#
#	If it was open for writing, but no p
#########################################################################
sub dbpop
    {
    my( $dbname ) = @_;
    my $dbt = &dbtype( $dbname );
    if( $DBSTATUS{$dbname} eq "RO" )
	{
 	if( ! grep(($_||"") eq "RW", @{$db_stati{$dbname}})	&&
 	    ! grep(($_||"") eq "RO", @{$db_stati{$dbname}})	)
	    {
	    if( $dbt eq "perlobj" )
		{ }	# Nothing to do since object is in memory
	    elsif( $dbt eq "gdbm" )
		{ dbmclose( %{ $databases{$dbname} } ); }
	    elsif( $dbt eq "sql" )
		{ $db_fh{$dbname}->disconnect(); }
	    else
		{ &fatal("Unknown database type [$_] for $dbname."); }
	    }
	}
    elsif( ($DBSTATUS{$dbname}||"") eq "RW" )
	{
 	if( ! grep(($_||"") eq "RW", @{$db_stati{$dbname}}) )
	    {
	    if( $dbt eq "perlobj" )
		{
		&write_file($dbname,
		    Dumper(\%{$databases{$dbname}}))
		    if( $DBWRITTEN{$dbname} > 0 );
		}
	    elsif( $dbt eq "gdbm" )
		{
		dbmclose( %{ $databases{$dbname} } );
 		if( grep(($_||"") eq "RO", @{$db_stati{$dbname}}) )
		    {
		    until(
			tie(%{$databases{$dbname}},'GDBM_File',$dbname,
			    &GDBM_READER, 0666 ) )
			{
			&fatal("Cannot open $dbname for writing:  $!")
		    	    if( $! ne "Resource temporarily unavailable" );
			}
		    }
		}
	    elsif( $dbt eq "sql" )
		{
		#$db_fh{$dbname}->commit();
		$db_fh{$dbname}->disconnect();
		}
	    else
		{ &fatal("Unknown database type [$_] for $dbname."); }
	    &unlock_file( $dbname );
	    $DBWRITTEN{$dbname} = 0;
	    }
	}
    else
        { &fatal("dbpop failed:  Database $dbname not open"); }
    $DBSTATUS{$dbname} = pop( @{$db_stati{$dbname}} );
    }

#########################################################################
#	Shut the database down, no matter how many times it has been	#
#	opened.  If there is a lock, it will unlock it.			#
#########################################################################
sub dbclose
    {
    my( $dbname ) = @_;
    while( ($DBSTATUS{$dbname}||"") ne "" )
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
    while( $DBSTATUS{$dbname} ne "" )
        { $DBSTATUS{$dbname} = pop( @{$db_stati{$dbname}} ); }
    $DBWRITTEN{$dbname} = 0;
    %{$databases{$dbname}} = ();	# (Shouldn't be necessary)
    }

#########################################################################
#	Return status of database specified in argument.		#
#########################################################################
sub db_readable { return ( ($DBSTATUS{$_[0]}||"") ne ""   ); }
sub db_writable { return ( ($DBSTATUS{$_[0]}||"") eq "RW" ); }

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
#    $ACCOUNTDB="$COMMONDIR/accounts.db";
#	Figure out which DB to use for this program.			#
#########################################################################
sub find_db
    {
    my( $base, @EXTS ) = @_;

    @DB_EXTS if(0);			# Get rid of 'only used once' warnings
    @EXTS = @DB_EXTS if( ! @EXTS );

    foreach my $ext ( @EXTS )
	{
	foreach my $attempt
	    (
	    "$base.$PROG.$WEBSITE$ext",
	    "$base.$PROG$ext",
	    "$base.$WEBSITE$ext",
	    "$base$ext"
	    )
	    {
	    return $attempt if( -f $attempt );
	    }
	}
    print STDERR "Could not find match for base=$base ext=[",join(" ",@EXTS),"] PROG=$PROG WEBSITE=$WEBSITE.\n";
    return undef;
    }

#########################################################################
#	Close any open databases.					#
#########################################################################
sub db_cleanup
    {
    grep( &dbclose($_), keys %databases );
    }
1;
