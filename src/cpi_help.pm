#__END__
1;

#########################################################################
#	Change help= strings in form objects to something more useful.	#
#########################################################################
sub help_strings
    {
    my @ret;
    foreach my $piece ( split(/(help='[\w_\-]+'|help="[\w_\-]+"|help=[\w_\-]+)/,join("",@_) ) )
        {
	if( $piece !~ /help=['"]*([\w_-]*)['"]*/ )
	    { push( @ret, $piece ); }
	else
	    {
	    my $subject = $1;
	    if( -r "$HELPDIR/$subject.cgi" )
	        {
		push( @ret,
		    ( map { " on$_='help_event(event,&quot;$subject.cgi&quot;);'" }
			@HELP_EVENTS )  );
		}
	    elsif( -r "$HELPDIR/$subject.html" )
	        {
		push( @ret,
		    ( map { " on$_='help_event(event,&quot;$subject.html&quot;);'" }
			@HELP_EVENTS )  );
		}
	    elsif( -r "$HELPDIR/help_template.cgi" )
	        {
		&write_file( "$HELPDIR/$subject.cgi",
		    &template( "$HELPDIR/help_template.cgi",
			"%%MISSING%%", "$HELPDIR/$subject.cgi") );
		system("chmod 755 $HELPDIR/$subject.cgi");
		}
	    elsif( -r "$HELPDIR/help_template.html" )
	        {
		&write_file( "$HELPDIR/$subject.html",
		    &template( "$HELPDIR/help_template.html",
			"%%MISSING%%", "$HELPDIR/$subject.html") );
		}
	    }
	}
    return join("",@ret);
    }

1;
