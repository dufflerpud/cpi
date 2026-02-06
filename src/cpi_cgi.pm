#!/usr/bin/perl -w
########################################################################
#@HDR@	$Id$
#@HDR@		Copyright 2025 by
#@HDR@		Christopher Caldwell
#@HDR@		P.O. Box 401, Bailey Island, ME 04003
#@HDR@		All Rights Reserved
#@HDR@
#@HDR@	This software comprises unpublished confidential information
#@HDR@	of the copyright holder and may not be used, copied or made
#@HDR@	available to anyone, except in accordance with the license
#@HDR@	under which it is furnished.
########################################################################

use strict;

package cpi_cgi;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( CGIheader CGIreceive embed_css note_to_html
 embed_javascript safe_html safe_url show_vars starting_CSS );
use lib ".";

use cpi_file qw( read_file );
use cpi_vars;
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
    foreach my $svn ( sort keys %cpi_vars::FORM )
        {
	print "<tr><th align=left bgcolor='#2050d0'>" .
	    "<font color=white>${svn}:</font></th>" .
	    "<td width=10% bgcolor='#2050d0'></td>" .
	    "<td bgcolor='#2050d0'>" .
	    "<font color=white>[".$cpi_vars::FORM{$svn}."]</font></td></tr>\n"
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
	while( defined($_=shift(@cpi_vars::CSS_PER_DEVICE_TYPE)) )
	    {
	    if( $ENV{HTTP_USER_AGENT} !~ /$_/ )
	        { shift(@cpi_vars::CSS_PER_DEVICE_TYPE); }
	    else
	        { $css=shift(@cpi_vars::CSS_PER_DEVICE_TYPE); last; }
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
    if( ! $cpi_vars::CGIheader_has_been_printed )
	{
	if(! exists &main::check_if_app_needs_header || &main::check_if_app_needs_header() )
	    {
	    $cpi_vars::CGIheader_has_been_printed++;
	    print "Content-type:  text/html; charset=\"utf-8\"\n";
	    while( my $vr = shift(@varvals) )
		{
		if( $vr =~ /=/ )
		    { print "Set-Cookie:  $vr\n"; }
		elsif( ref($vr) ne "HASH" )
		    { print "Set-Cookie:  $vr=", shift(@varvals), "\n"; }
		else
		    {
		    print "Set-Cookie: $vr->{name}=$vr->{value}";
		    foreach my $k ( sort keys %{$vr} )
			{
			print "; $k=$vr->{$k}" if( $k ne "name" && $k ne "value" );
			}
		    print "\n";
		    }
		}
	    print "\n";
	    &starting_CSS();
	    if( exists &app_intro )
	        { &app_intro(); }
	    else
	        {
		print &read_file( $cpi_vars::COMMONJS ) if( $cpi_vars::COMMONJS && -r $cpi_vars::COMMONJS );
		print "<link href='$cpi_vars::CSS_URL' rel='stylesheet' type='text/css' />\n"
		    if( $cpi_vars::CSS_URL );
		print "<link href='$cpi_vars::PROG_CSS_URL' rel='stylesheet' type='text/css' />\n"
		    if( $cpi_vars::PROG_CSS_URL );
		print "<link rel='shortcut icon' href='$cpi_vars::ICON_URL' />\n"
		    if( $cpi_vars::ICON_URL );
		if( $cpi_vars::IOS_ICON_URL )
		    {
		    print "<link rel='apple-touch-icon' href='$cpi_vars::IOS_ICON_URL' />\n";
#		    foreach my $sz ( 57, 120, 152, 167, 180 )
#		        {
#		        print "<link rel='apple-touch-icon' sizes='${sz}x${sz}' href='$cpi_vars::IOS_ICON_URL' />\n";
#			}
		    }
		}
	    }
	}
    }


#########################################################################
#	Put <form> information into %cpi_vars::FORM (from STDIN or ENV).	#
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
		$cpi_vars::FORM{$flname} .= ","
		    if (defined($cpi_vars::FORM{$flname})
		        && $cpi_vars::FORM{$flname} ne "");

		$cpi_vars::FORM{$flname} .= $val;
		$cpi_vars::FORM{$flname} =~ s/[\r\n]*$//s;

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
	    if( defined($cpi_vars::FORM{$name}) )
		{ $cpi_vars::FORM{$name} .= ",$value"; }
	    else
		{ $cpi_vars::FORM{$name} = $value; }

	    #### Add to ordered list if not on list already
	    push (@fields, $name) unless (grep(/^$name$/, @fields));
	    }
	}
    foreach my $ind ( sort keys %cpi_vars::FORM )
	{
	my $topr = $cpi_vars::FORM{$ind};
	$topr = substr($topr,0,40) . " ..." if( length($topr) > 40 );
        $topr =~ s/([^ -z])/uc sprintf("\\%03o",ord($1))/eg;
	print STDERR "    $ind = $topr\n";
	}
    print STDERR "Form:\n";
    foreach my $k ( sort keys %cpi_vars::FORM )
        {
	if( length($cpi_vars::FORM{$k}) <= 50 )
	    { print STDERR "  $k=[$cpi_vars::FORM{$k}]\n"; }
	else
	    {
	    printf STDERR ( "  %s=[%.50s] (%db)\n",
		$k, $cpi_vars::FORM{$k}, length( $cpi_vars::FORM{$k} ) );
	    }
	}
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

#########################################################################
#	Convert a string from "input type=note" to text and pics.	#
#########################################################################
sub note_to_html
    {
    my( $arg ) = @_;
    my $argp = ( ref($arg) eq "HASH" ) ? $arg : { data=>$arg };
    $argp->{data} = shift(@_) if( ! defined( $argp->{data} ) );

    $argp->{width} ||= "90%";
    my $splitter = $argp->{split} || "~~~";

    my @pieces;
    foreach my $pc ( split(/$splitter/,$argp->{data}) )
	{
	if( $pc !~ /(data:image\/jpeg;base64,)(.*)/ )
	    { push( @pieces, "<pre><b>$pc</b></pre>" ); }
	else
	    {
	    my $intro = $1;
	    my $splitpc = $2;
	    $splitpc =~ s/(.{1,76})/$1\n/gs;
	    push(@pieces, "<img width=$argp->{width} src='$intro$splitpc' />");
	    }
	}
    return join("",@pieces);
    }
1;
