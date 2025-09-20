use Data::Dumper;
#__END__
1;

#########################################################################
#	Create an ascii representation of the specified database.	#
#########################################################################
sub dumpdb
    {
    my( $dbname, $outfile ) = @_;
    &fatal("Must specify an output file") if(!defined($outfile));
    &dbread( $dbname );
    &write_file( $outfile,
	Dumper( \%{$databases{$dbname}} ) );
    &cleanup(0);
    }

#########################################################################
#	Read an ascii representation of the specified database.		#
#########################################################################
sub undumpdb
    {
    my( $dbname, $infile ) = @_;
    &fatal("Must specify an input file") if(!defined($infile));
    my %swallow_db;
    open(TOUCHFILE,">$dbname")|| &fatal("Cannot truncate $dbname:  $!");
    chmod( 0666, $dbname) || &fatal("Cannot chmod(0666,$dbname):  $!");
    close(TOUCHFILE);
    tie( %swallow_db, 'GDBM_File', $dbname, &GDBM_WRITER, 0666 ) ||
        &fatal("undumpdb gdbm tie failed for ${dbname}:  $!");
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
    my $old_dbtype = $db_type{$old_dbname};
    my $old_ishash = grep( $_ eq $old_dbtype, "gdbm", "perlobj" );

    &dbnew( $new_dbname );
    &dbwrite( $new_dbname );
    my $new_dbtype = $db_type{$new_dbname};
    my $new_ishash = grep( $_ eq $new_dbtype, "gdbm", "perlobj" );

    if( $old_ishash )
        {
	if( $new_ishash )
	    {
	    %{$databases{$new_dbname}} =
		%{$databases{$old_dbname}};
	    }
	else
	    {
	    foreach my $k ( keys %{$databases{$old_dbname}} )
	        {
		my( $tbl, $rec, @fieldnames ) = split($DBSEP,$k);
		my $fieldname = join( $SQLSEP, @fieldnames );
		my $val = $databases{$old_dbname}{$k};
		print "xfer $val to [",join(",",$tbl,$rec,@fieldnames),"]\n";
		&dbput( $new_dbname, $tbl, $rec, $fieldname, $val );
		}
	    }
	}
    $DBWRITTEN{$new_dbname}++;
    &dbclose( $old_dbname );
    &dbclose( $new_dbname );
    &cleanup( 0 );
    }

1;
