use MIME::Lite;
#__END__
1;
#########################################################################
#	Send e-mail to the specified destination.  Knows how to send	#
#	attachments.							#
#########################################################################
sub sendmail
    {
    my( $src, $dest, $subject, $msg, @files ) = @_;

    my $mime_msg = MIME::Lite->new
	( 
	From    => $src,
	To      => $dest,
	Subject => $subject,
	Type    => 'multipart/mixed',
	);

    my $msg_type;
    my $cid_ctr = 0;
    my %fn_to_cid = ();

    if( $msg =~ /^%PDF/i )
	{ $msg_type = "application/pdf"; }
    elsif( $msg =~ /<\/.*>/ )
        {
	my @msg_parts = ();
	$msg_type = "text/html";
	foreach my $mpart ( split(/("cid:.*?")/, $msg ) )
	    {
	    if( $mpart !~ /"cid:(.*)"/ )
	        { push( @msg_parts, $mpart ); }
	    else
	        {
		my $fn = $1;
		if( ! defined($fn_to_cid{$fn}) )
		    {
		    $fn_to_cid{$fn} = sprintf("%x-%x",$$,++$cid_ctr);
		    $fn_to_cid{$fn} .= ".$1" if( $fn =~ /\.(\w*)$/ );
		    }
		push( @msg_parts, "\"cid:$fn_to_cid{$fn}\"" );
		}
	    }
	$msg = join("", @msg_parts );
	}
    else
        { $msg_type = "TEXT"; }
    
    $mime_msg->attach
	(
	Type	=> $msg_type,
	Data	=> $msg
	) || die("Cannot attach body of message:  $!");

    &read_mime_types();
    foreach my $fn ( @files )
	{
	my $ext = ( ( $fn =~ /^[^\.].*\.([^\.]+)$/ ) ? $1 : "" );
	my $cid_name = $fn_to_cid{$fn};
	if( ! defined($cid_name) )
	    {
	    $cid_name = sprintf("%x-%x",$$,++$cid_ctr);
	    $cid_name .= ".$1" if( defined($ext) );
	    }
	$mime_msg->attach
	    (
	    Type		=> ($EXT_TO_MIME_TYPE{$ext}
				? $EXT_TO_MIME_TYPE{$ext}
				: "unknown/unknown"),
	    Path		=> $fn,
	    Filename	=> $cid_name,
	    Id		=> $cid_name,
	    Disposition	=> 'attachment'
	    ) || die("Cannot attach $fn:  $!");
	}

    open( OUT, "| $SENDMAIL -t -f '$src' 2>&1 > /tmp/sm.log" ) ||
        die("Cannot run $SENDMAIL:  $!");
    print OUT $mime_msg->as_string;
    close( OUT );
    &write_file( "/tmp/outgoing", $mime_msg->as_string );
    #&write_file( "/mytmp/outgoing", $mime_msg->as_string );
    }

#########################################################################
#	Send fax to the specified destination.				#
#########################################################################
sub sendfax
    {
    my( $dest, $msg, @pdf_files ) = @_;
    if( defined($msg) && $msg ne "" )
	{
	my $fmtmsg = $msg;
	if( $fmtmsg !~ /<\w+>/ )
	    {
	    $fmtmsg =~ s+&+\&amp;+gs;
	    $fmtmsg =~ s+<+\&lt;+gs;
	    $fmtmsg =~ s+>+\&gt;+gs;
	    $fmtmsg = "<pre>$fmtmsg</pre>";
	    }
	my $tf = &tempfile(".pdf");
	#open( CVT, "| tee /tmp/1.html | $HTML2PS | tee /tmp/1.ps | $PS2PDF - $tf" )
	open( CVT, "| tee /tmp/1.html | $HTML2PDF -q - $tf" )
	    || &fatal("Cannot convert message to pdf.");
	print CVT $msg;
	close( CVT );
	unshift( @pdf_files, $tf );
	}
    $dest =~ s+[^\d]++g;
#    &sendmail( $DAEMON_EMAIL,
#        "$dest\@efaxsend.com", "", "{nocoverpage}\n", @pdf_files );
#    &sendmail( $DAEMON_EMAIL,
#        "chris.interim\@gmail.com", "", "{nocoverpage}\n", @pdf_files );
    &sendmail( $DAEMON_EMAIL,
        "$dest\@myfax.com", "?", "", @pdf_files );
    &sendmail( $DAEMON_EMAIL,
        "chris.interim\@gmail.com", "?", "", @pdf_files );
    }

#########################################################################
#	Send phone message to the specified destination.		#
#########################################################################
sub sendphone
    {
    my( $dest, $msg ) = @_;
    # Don't know what to do, so we'll ignore it.
    }

#########################################################################
#	Send a message via different possible mediums.			#
#########################################################################
sub send_via
    {
    my( $means, $src, $dest, $subj, $msg, @files ) = @_;
    if( $means eq "e-mail" || $means eq "email" )
        { &sendmail( $src, $dest, $subj, $msg, @files ); }
    elsif( $means eq "fax" )
        { &sendfax( $dest, $msg, @files ); }
    elsif( $means eq "phone" )
        { &sendphone( $dest, $msg, @files ); }
    }

1;
