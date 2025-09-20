#__END__
1;

use Digest::MD5 qw(md5_hex);
#########################################################################
#	Create a string that is really likely to be unique.		#
#########################################################################
sub hashof
    {
    return md5_hex(@_);
    }
1;
