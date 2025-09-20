#__END__
1;
#########################################################################
#	Return an arbitrary list reordered randomly.			#
#########################################################################
sub reorder
    {
    my ( @old_list ) = @_;
    my( @new_list );
    push( @new_list, splice( @old_list, int(rand()*scalar(@old_list)), 1 ) )
        while( scalar(@old_list) );
    return @new_list;
    }
1;
