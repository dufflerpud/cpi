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

package cpi_mime;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( mime_string read_mime_types );
use lib ".";

use cpi_file qw( read_lines );
use cpi_vars;
#__END__
1;

#########################################################################
#	Read in /etc/mime.types to map extensions to mime types.	#
#	Creates global variables:					#
#	    EXT_TO_MIME_TYPES	- Indexed by extension to give mime	#
#	    MIME_TYPE_TO_EXTS	- Indexed by mime and ext		#
#	Returns a list of known mime types.				#
#########################################################################
sub read_mime_types
    {
    %cpi_vars::EXT_TO_MIME_TYPE = ();
    %cpi_vars::MIME_TYPE_TO_EXTS = ();
    %cpi_vars::MIME_TYPE_TO_BASE_TYPE = ();
    %cpi_vars::EXT_TO_BASE_TYPE = ();
    foreach my $file_to_try ( grep( -r $_,
	"/etc/mime.types",
	"/etc/apache2/mime.types",
	"/etc/httpd/conf/mime.types" ) )
	{
	foreach $_ ( &read_lines( $file_to_try ) )
	    {
	    my( $mimestr, @exts ) = split(/\s+/,lc($_));
	    grep( $cpi_vars::EXT_TO_MIME_TYPE{$_}=$mimestr, @exts );
	    grep( $cpi_vars::MIME_TYPE_TO_EXTS{$mimestr}{$_}=1, @exts );
	    my $base_type =
		( $mimestr =~ /movie/		? "movie"
		: $mimestr =~ /gif/		? "gif"
		: $mimestr !~ m/(.*)\/(.*)/	? $mimestr
		: $1 eq "application"		? $2
		: $1 );
	    $cpi_vars::MIME_TYPE_TO_BASE_TYPE{$mimestr} = $base_type;
	    grep( $cpi_vars::EXT_TO_BASE_TYPE{$_} = $base_type, @exts );
	    }
	}
    return sort keys %cpi_vars::MIME_TYPE_TO_EXTS;
    }

#########################################################################
#	Look at a file and return mime type.  Right now, just based	#
#	answer on file's extension.					#
#########################################################################
sub mime_string
    {
    my( $fn ) = @_;
    my $ret;
    &read_mime_types() if( ! %cpi_vars::EXT_TO_MIME_TYPE );
    if( $fn =~ /\.(.*?)$/ )
        {
	$ret = $cpi_vars::EXT_TO_MIME_TYPE{$1};
	return $ret || "unknown/unknown";
	}
    return "unknown/unknown";
    }

1;
