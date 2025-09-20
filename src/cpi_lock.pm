#__END__
1;

#########################################################################
#       Check if file is locked.  If not locked, lock it.               #
#########################################################################
sub lock_check
    {
    return symlink( "/$$", "$_[0].lock" );
    }

#########################################################################
#       Keep checking the lock until we get it.                         #
#########################################################################
sub lock_file
    {
    my( $lockname ) = @_;
    my $trace_name	= "$lockname.trace";
    my $trace_new	= "$trace_name.$$";
    my $trace_current	= "$trace_name.current";
    my $trace_last	= "$trace_name.last";

    &write_file( $trace_new, join("\n",&get_trace())."\n" );
    until( &lock_check( $lockname ) )
        { sleep(1); }
    rename( $trace_current, $trace_last );	# First time ever will fail
    rename( $trace_new, $trace_current );	# Should always work
    }

#########################################################################
#       By removing the link previously put there by a lock_check,    #
#       we allow one of the processes waiting on the lock file in.      #
#########################################################################
sub unlock_file
    {
    unlink( "$_[0].lock" );
    }

1;
