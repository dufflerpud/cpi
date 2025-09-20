#__END__
1;

#########################################################################
#	Read in /etc/mime.types to map extensions to mime types.	#
#########################################################################
sub read_mime_types
    {
    %EXT_TO_MIME_TYPE = ();
    foreach my $file_to_try (
	"/etc/mime.types",
	"/etc/apache2/mime.types",
	"/etc/httpd/conf/mime.types" )
	{
	if( open(INF,$file_to_try) )
	    {
	    while( $_ = <INF> )
		{
		s/[#\r\n].*//;
		my( $mimestr, @exts ) = split(/\s+/);
		grep( $EXT_TO_MIME_TYPE{$_}=$mimestr, @exts );
		}
	    close(INF);
	    }
	}
    }

#########################################################################
#	Look at a file and return mime type.  Right now, just based	#
#	answer on file's extension.					#
#########################################################################
sub mime_string
    {
    my( $fn ) = @_;
    my $ret;
    &read_mime_types() if( ! %EXT_TO_MIME_TYPES );
    if( $fn =~ /\.(.*?)$/ )
        {
	$ret = $EXT_TO_MIME_TYPE{$1};
	return $ret || "unknown/unknown";
	}
    return "unknown/unknown";
    }

1;
