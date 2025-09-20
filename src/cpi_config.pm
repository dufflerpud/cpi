#__END__
1;
#########################################################################
#	Read in a previously written configuration file.		#
#########################################################################
sub read_config
    {
    my( $fn, $varref ) = @_;
    my( $vtype ) = ref( $varref );

    if( -f $fn )
	{ $_ = &read_file( $fn ); }
    else
        { $_ = "\$VAR1 = {};"; }

    if( /^\$VAR1/ )
        {
	my $VAR1;	# Will be set by evaluating $_
	eval( $_ );
	if( $vtype eq "HASH" )
	    { %{$varref} = %{ $VAR1 }; }
	elsif( $vtype eq "ARRAY" )
	    { @{$varref} = @{ $VAR1 }; }
	return;
	}

    if( $vtype eq "HASH" )
	{
	my %temp;		# Why do I have to create a temporary var?
	eval( "\%temp = $_" );
	%{$varref} = %temp;
	}
    elsif( $vtype eq "ARRAY" )
	{
	my @temp;		# Why do I have to create a temporary var?
	eval( "\@temp = $_" );
	@{$varref} = @temp;
	}
    else
	{&fatal("read_config refers to unknown variable type:".$vtype);}
    return 1;
    }
1;
