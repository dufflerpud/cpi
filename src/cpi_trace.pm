#__END__
1;

#########################################################################
#	Return a trace as a string for use in fatal, etc.		#
#########################################################################
sub get_trace
    {
    my @ret;
    for( my $i=0; 1; $i++ )
	{
	my($pack,$file,$line,$subname,$hasargs,$wantarray) = caller($i);
	return @ret if( ! $pack );
	push( @ret, "${file}:$line $subname" );
	}
    }

#########################################################################
#	Print an error message and die with a stack trace.		#
#########################################################################
sub stack_trace
    {
    my( @problems ) = @_;
    print STDERR join("\n\t",join("\n",@problems).":",&get_trace()), "\n";
    }

1;
