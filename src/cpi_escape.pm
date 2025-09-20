#__END__
1;

#########################################################################
#       Return string with characters having special meaning in perl    #
#       strings escaped with backslashes.                               #
#########################################################################
sub perl_esc
    {
    $_ = $_[0];
    s/\\/\\\\/g;
    s/"/\\"/g;
    s/'/\\'/g;
    s/@/\\@/g;
    s/\$/\\\$/g;
    s/([^ -z])/uc sprintf("\\%03o",ord($1))/eg;
    return $_;
    }

#########################################################################
#       Return string with characters having special meaning in		#
#       javascript strings escaped with backslashes.			#
#########################################################################
sub javascript_esc
    {
    my( $str, $what, $to ) = @_;
    $what = '"' if( ! defined($what) );
    $to = "\\$what" if( ! defined($to) );
    $str =~ s/$what/$to/g;
    return $str;
    }

1;
