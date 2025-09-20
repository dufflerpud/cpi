#!/usr/bin/perl -w
########################################################################
#@HDR@	$Id$
#@HDR@		Copyright 2025 by
#@HDR@		Christopher Caldwell/Brightsands
#@HDR@		P.O. Box 401, Bailey Island, ME 04003
#@HDR@		All Rights Reserved
#@HDR@
#@HDR@	This software comprises unpublished confidential information
#@HDR@	of Brightsands and may not be used, copied or made available
#@HDR@	to anyone, except in accordance with the license under which
#@HDR@	it is furnished.
########################################################################

use strict;

package cpi_send_file;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw();
use lib ".";

use cpi_file;
use cpi_mime;
use cpi_vars;
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

    &cpi_mime::read_mime_types();
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
	    Type		=> ($cpi_vars::EXT_TO_MIME_TYPE{$ext}
				? $cpi_vars::EXT_TO_MIME_TYPE{$ext}
				: "unknown/unknown"),
	    Path		=> $fn,
	    Filename	=> $cid_name,
	    Id		=> $cid_name,
	    Disposition	=> 'attachment'
	    ) || die("Cannot attach $fn:  $!");
	}

    open( OUT, "| $cpi_vars::SENDMAIL -t -f '$src' 2>&1 > /tmp/sm.log" ) ||
        die("Cannot run $cpi_vars::SENDMAIL:  $!");
    print OUT $mime_msg->as_string;
    close( OUT );
    &cpi_file::write_file( "/tmp/outgoing", $mime_msg->as_string );
    #&cpi_file::write_file( "/mytmp/outgoing", $mime_msg->as_string );
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
	my $tf = &cpi_file::tempfile(".pdf");
	#open( CVT, "| tee /tmp/1.html | $cpi_vars::HTML2PS | tee /tmp/1.ps | $cpi_vars::PS2PDF - $tf" )
	open( CVT, "| tee /tmp/1.html | $cpi_vars::HTML2PDF -q - $tf" )
	    || &cpi_file::fatal("Cannot convert message to pdf.");
	print CVT $msg;
	close( CVT );
	unshift( @pdf_files, $tf );
	}
    $dest =~ s+[^\d]++g;
#    &sendmail( $cpi_vars::DAEMON_EMAIL,
#        "$dest\@efaxsend.com", "", "{nocoverpage}\n", @pdf_files );
#    &sendmail( $cpi_vars::DAEMON_EMAIL,
#        "chris.interim\@gmail.com", "", "{nocoverpage}\n", @pdf_files );
    &sendmail( $cpi_vars::DAEMON_EMAIL,
        "$dest\@myfax.com", "?", "", @pdf_files );
    &sendmail( $cpi_vars::DAEMON_EMAIL,
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
