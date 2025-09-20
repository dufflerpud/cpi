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

package cpi_mime;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw();
use lib ".";

use cpi_vars;
#__END__
1;

#########################################################################
#	Read in /etc/mime.types to map extensions to mime types.	#
#########################################################################
sub read_mime_types
    {
    %cpi_vars::EXT_TO_MIME_TYPE = ();
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
		grep( $cpi_vars::EXT_TO_MIME_TYPE{$_}=$mimestr, @exts );
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
    &read_mime_types() if( ! %cpi_vars::EXT_TO_MIME_TYPES );
    if( $fn =~ /\.(.*?)$/ )
        {
	$ret = $cpi_vars::EXT_TO_MIME_TYPE{$1};
	return $ret || "unknown/unknown";
	}
    return "unknown/unknown";
    }

1;
