#__END__
1;

#########################################################################
#	Make text safe as a filename (without directory or extension).	#
#########################################################################
sub text_to_filename
    {
    my( $text ) = @_;				# Chris's file!
    $text =~ s/'s/s/g;				# Chriss file!
    $text =~ s/[^A-Za-z0-9\.]+/_/g;		# Chriss_file_
    $text = $1 if( $text =~ /^_*(.*?)_*$/ );	# Chriss_file
    return $text;
    }
#
#########################################################################
#	Convert filename (without directory or extension) into text.	#
#########################################################################
sub filename_to_text
    {
    my( $text ) = @_;				# Chris_file
    $text =~ s/_+/ /g;				# Chris file
    return $text;
    }

#########################################################################
#	Apparently perl's dirname has gone away.			#
#########################################################################
sub dirname
    {
    my( $str ) = @_;
    return "." if( $str !~ /\// );
    $str =~ s+/[^/]*$++;
    return $str;
    }
1;
