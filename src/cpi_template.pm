#__END__
1;

#########################################################################
#	Apply a list of substitutions to a string.			#
#########################################################################
sub subst_list
    {
    my( $contents, @substs ) = @_;
    my $varname;

    push( @substs,
	"%%BODY_TAGS%%",	$BODY_TAGS,
	"%%TABLE_TAGS%%",	$TABLE_TAGS,
	"%%SID%%",		$SID,
	"%%USER%%",		$USER,
	"%%PROG%%",		$PROG
	);
    while( defined($varname = shift(@substs) ) )
	{
	my $val = shift(@substs);
	$contents =~ s/$varname/$val/gms;
	}
    return $contents;
    }

#########################################################################
#	Apply substitutions to a file.					#
#########################################################################
sub template
    {
    my( $filename, @substs ) = @_;
    return &subst_list( &read_file($filename), @substs );
    }

1;
