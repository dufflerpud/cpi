use MIME::Base64 qw( encode_base64 );
use Imager::QRCode;
#__END__
1;

#########################################################################
#	Return text as a QR code, probably as a jpeg.			#
#########################################################################
sub qrcode_of
    {
    my( $text, $argp ) = @_;
    my $fmt = $argp->{type} || "jpeg";
    my $qrcode = Imager::QRCode->new
        (
        size          => 2,
        margin        => 5,
        version       => 1,
        level         => 'M',
        casesensitive => 1,
        lightcolor    => Imager::Color->new(255, 255, 255),
        darkcolor     => Imager::Color->new(0, 0, 0),
	);
    &fatal("Imager::QRCode->new failed:  $!") if( ! $qrcode );
    print STDERR "Going to write QR $fmt to ", ($argp->{file} || "UNDEF"), ".\n";
    my $img = $qrcode->plot($text);
    &fatal("Imager::QRCode->plot($text) failed:  $!") if( ! $img );

    my $ret;
    $img->write(data =>\$ret, type => $fmt);

    if( ! $ret )
        { &fatal("image writer failed:  $!"); }
    else
	{
	if( my $encoding = $argp->{encoding} )
	    {
	    if( $encoding eq "base64" )
		{ $ret = encode_base64( $ret ); }
	    elsif( $encoding eq "image" )
		{ $ret = "<img src='data:image/jpeg;base64,".encode_base64($ret)."'/>"; }
	    }

	&write_file( $argp->{file}, $ret ) if( $argp->{file} );
	}
    print STDERR "qrcode_of() returned.\n";
    return $ret;
    }
1;
