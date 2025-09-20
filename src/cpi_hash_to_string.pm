#__END__
1;
#########################################################################
#       Return string that would initialize a hash string.              #
#########################################################################
sub hash_to_string
    {
    my $hash_to_do = $_[0];

    my( $str ) = '%{$_} = (';
    my( $sep ) = "\n";
    my( $k );
    foreach $k ( sort keys %$hash_to_do )
        {
        my( $v ) = ${$hash_to_do}{$k};
        next if( $v eq "" );
        $str .= ("$sep\"".&perl_esc($k). "\", \"".&perl_esc($v)."\"");
        $sep = ",\n";
        }
    $str .= "\n);\n1;\n";
    return $str;
    }
1;
