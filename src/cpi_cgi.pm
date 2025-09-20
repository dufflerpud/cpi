#__END__
1;

#########################################################################
#	Debug routine:  Print out a hash's keys and values in HTML.	#
#########################################################################
sub show_vars
    {
    my( $msg, @excludevars ) = @_;
    print <<EOF;
<table cellspacing=0 cellpadding=0 bgcolor=black frame=border>
<tr><th bgcolor="#2050d0" colspan=3><font color=white>$msg</font></th></tr>
EOF
    foreach my $svn ( sort keys %FORM )
        {
	print "<tr><th align=left bgcolor='#2050d0'>" .
	    "<font color=white>${svn}:</font></th>" .
	    "<td width=10% bgcolor='#2050d0'></td>" .
	    "<td bgcolor='#2050d0'>" .
	    "<font color=white>[".$FORM{$svn}."]</font></td></tr>\n"
	    unless( grep( $svn eq $_, @excludevars ) );
	}
    print "</table></p>\n";
    }

#########################################################################
#	Give some limited css (others will override).			#
#########################################################################
sub starting_CSS
    {
    my $css = "";
    if( $ENV{HTTP_USER_AGENT} )
	{
	while( defined($_=shift(@CSS_PER_DEVICE_TYPE)) )
	    {
	    if( $ENV{HTTP_USER_AGENT} !~ /$_/ )
	        { shift(@CSS_PER_DEVICE_TYPE); }
	    else
	        { $css=shift(@CSS_PER_DEVICE_TYPE); last; }
	    }
	}
    print <<EOF;

<html><head>
<style type="text/css">
<!--
$css
-->
</style>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=utf-8">
EOF
    }

#########################################################################
#	Print out a CGI header if we haven't already printed one.	#
#	Arguments are pairs of variable=value for cookies.		#
#########################################################################
my $CGIheader_flag = 0;
sub CGIheader
    {
    my( @varvals ) = @_;
    if( ! $CGIheader_has_been_printed++ )
	{
	if(! exists &main::check_if_app_needs_header || &main::check_if_app_needs_header() )
	    {
	    print "Content-type:  text/html; charset=\"utf-8\"\n";
	    my $found = 0;
	    while( my $vr = shift(@varvals) )
		{
		print ($found++ == 0 ?"Set-Cookie:  ":";");
		print $vr, "=", shift(@varvals);
		}
	    print "\n" if( $found );
	    &starting_CSS();
	    if( exists &app_intro )
	        { &app_intro(); }
	    else
	        {
		print &read_file( $COMMONJS ) if( $COMMONJS && -r $COMMONJS );
		print "<link href='$CSS_URL' rel='stylesheet' type='text/css' />\n"
		    if( $CSS_URL );
		print "<link href='$PROG_CSS_URL' rel='stylesheet' type='text/css' />\n"
		    if( $PROG_CSS_URL );
		print "<link rel='shortcut icon' href='$ICON_URL' />\n"
		    if( $ICON_URL );
		if( $IOS_ICON_URL )
		    {
		    print "<link rel='apple-touch-icon' href='$IOS_ICON_URL' />\n";
#		    foreach my $sz ( 57, 120, 152, 167, 180 )
#		        {
#		        print "<link rel='apple-touch-icon' sizes='${sz}x${sz}' href='$IOS_ICON_URL' />\n";
#			}
		    }
		}
	    }
	}
    }


#########################################################################
#	Put <form> information into %FORM (from STDIN or ENV).	#
#########################################################################
sub CGIreceive
    {
    my ( $name, $value );
    my ( @fields, @ignorefields, @requirefields );
    my ( @parts );
    my $incoming = "";
    if ( defined($ENV{REQUEST_METHOD}) && $ENV{REQUEST_METHOD} eq "POST")
	{
	binmode STDIN;
	read(STDIN, $incoming, $ENV{'CONTENT_LENGTH'});
	}
    elsif( defined($ENV{QUERY_STRING}) )
	{ $incoming = $ENV{'QUERY_STRING'}; }

    my($sec,$min,$hour,$mday,$month,$year) = localtime(time);
    my $fname = sprintf("%04d.%02d.%02d.%02d:%02d.%02d.%d",
	$year+1900,$month+1,$mday,$hour,$min,$sec,$$);
    if( open(RCV,">/var/log/cgi/$fname") )
        {
	foreach my $ev ( sort keys %ENV )
	    { print RCV $ev, "=\"", $ENV{$ev}, "\"\n"; }
	print RCV "==========\n$incoming";
	close( RCV );
	}
    
    if( $ENV{"CONTENT_TYPE"}
	&& $ENV{"CONTENT_TYPE"} =~ m#^multipart/form-data# )
	{
	#CONTENT_TYPE:multipart/form-data; boundary=*****org.apache.cordova.formBoundary
	my $bnd = $ENV{"CONTENT_TYPE"};
	$bnd =~ s/.*boundary=//;
	#print STDERR "bnd=[$bnd]\n";
	$bnd =~ s/([*+])/\\$1/g;
	foreach $_ ( split(/--$bnd/s,$incoming) )
	    {
	    #print "Processing:  <pre>[$_]</pre><br>\n";
	    if( /^.*? name="(.*?)"(.*?)\r\n*\r\n*(.*)/s )
		{
		my( $flname, $desc, $val ) = ( $1, $2, $3 );
		#### Skip generally blank fields
		next if ($val eq "");

		#### Allow for multiple values of a single name
		$FORM{$flname} .= ","
		    if (defined($FORM{$flname})
		        && $FORM{$flname} ne "");

		$FORM{$flname} .= $val;
		$FORM{$flname} =~ s/[\r\n]*$//s;

		#print STDERR "Setting [$flname] to [$val]<br>\n";
		#### Add to ordered list if not on list already
		push (@fields, $flname) unless (grep(/^$flname$/, @fields));
		}
	    }
	}
    else
	{
	foreach ( split('&', $incoming) )
	    {
	    ($name, $value) = split('=', $_);

	    $name  =~ tr/+/ /;
	    $value =~ tr/+/ /;
	    $name  =~ s/%([A-F0-9][A-F0-9])/pack("C", hex($1))/gie;
	    $value =~ s/%([A-F0-9][A-F0-9])/pack("C", hex($1))/gie;

	    #### Strip out semicolons unless for special character
	    #$value =~ s/;/$$/g;

	    $value =~ s/&(\S{1,6})$$/&$1;/g;
	    $value =~ s/$$/ /g;

	    #$value =~ s/\|/ /g;
	    $value =~ s/^!/ /g; ## Allow exclamation points in sentences

	    #### Split apart any directive prefixes
	    #### NOTE: colons are reserved to delimit these prefixes
	    @parts = split(':', $name);
	    $name = $parts[$#parts];
	    if (grep(/^require$/, @parts))
		{
		push (@requirefields, $name);
		}
	    if (grep(/^ignore$/, @parts))
		{
		push (@ignorefields, $name);
		}
	    if (grep(/^dynamic$/, @parts))
		{
		#### For simulating a checkbox
		#### It may be dynamic, but useless if nothing entered
		next if ($value eq "");
		$name = $value;
		$value = "on";
		}

	    #### Skip generally blank fields
	    next if ($value eq "");

	    #### Allow for multiple values of a single name
	    if( defined($FORM{$name}) )
		{ $FORM{$name} .= ",$value"; }
	    else
		{ $FORM{$name} = $value; }

	    #### Add to ordered list if not on list already
	    push (@fields, $name) unless (grep(/^$name$/, @fields));
	    }
	}
    foreach my $ind ( sort keys %FORM )
	{
	my $topr = $FORM{$ind};
	$topr = substr($topr,0,40) . " ..." if( length($topr) > 40 );
        $topr =~ s/([^ -z])/uc sprintf("\\%03o",ord($1))/eg;
	print STDERR "    $ind = $topr\n";
	}
    print STDERR "Form:\n", map { "  $_ = [$FORM{$_}]\n" } sort keys %FORM;
    }

#########################################################################
#	Read in a file and surround it with javascript text.		#
#########################################################################
sub embed_javascript
    {
    return join("",
        "<script TYPE='text/javascript'>\n", &read_file($_[0]), "</script>\n");
    }

#########################################################################
#	Read in a file and surround it with css text.			#
#########################################################################
sub embed_css
    {
    return join("","<style type='text/css'>\n",&read_file($_[0]),"</style>\n");
    }

#########################################################################
#	Change HTML's magic characters into an HTML appropriate string.	#
#########################################################################
sub safe_html
    {
    my( $ret ) = @_;
    $ret = "" if( ! defined($ret) );
    $ret =~ s+&+\&amp;+g;
    $ret =~ s+<+\&lt;+g;
    $ret =~ s+>+\&gt;+g;
    $ret =~ s+"+\&quot;+g;
    #$ret =~ join("<br>",split(/\n/,$ret));
    return $ret;
    }

#########################################################################
#	Returns string coded with hex chars for non alphanum.		#
#########################################################################
sub safe_url
    {
    my( $ret ) = @_;
    $ret =~ s/([^A-Za-z0-9])/uc sprintf("%%%02x",ord($1))/eg;
    return $ret;
    }

1;
