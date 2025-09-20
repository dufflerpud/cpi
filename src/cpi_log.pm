#__END__
1;

#########################################################################
#	Log a message.							#
#########################################################################
my $log_opened = 0;
sub log
    {
    my( $msg ) = @_;
    $msg =~ s/XL\((.*?)\)/$1/g;
    my($sec,$min,$hour,$mday,$month,$year) = localtime(time);
    my $str = sprintf( "%02d/%02d/%04d %02d:%02d:%02d %s %d:  %s\n",
        $month+1,$mday,$year+1900,$hour,$min,$sec,$PROG,$$,$msg);
    if( ! $log_opened )
	{
	open( CLOG, ">> $ACCOUNTING_LOG" ) ||
	    die "Cannot append messages to $ACCOUNTING_LOG:  $!\n" .
	    	"Message was:  $str";
	$log_opened = 1;
	}
    syswrite CLOG, $str;
    }

1;
