#!/usr/bin/perl -w
#
#indx#	cpi_mime.pm - Parse mimes config file for extension and base types
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2025-2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
#@HDR@
#@HDR@	Permission is hereby granted, free of charge, to any person
#@HDR@	obtaining a copy of this software and associated documentation
#@HDR@	files (the "Software"), to deal in the Software without
#@HDR@	restriction, including without limitation the rights to use,
#@HDR@	copy, modify, merge, publish, distribute, sublicense, and/or
#@HDR@	sell copies of the Software, and to permit persons to whom
#@HDR@	the Software is furnished to do so, subject to the following
#@HDR@	conditions:
#@HDR@	
#@HDR@	The above copyright notice and this permission notice shall be
#@HDR@	included in all copies or substantial portions of the Software.
#@HDR@	
#@HDR@	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
#@HDR@	KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
#@HDR@	WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
#@HDR@	AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#@HDR@	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#@HDR@	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#@HDR@	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#@HDR@	OTHER DEALINGS IN THE SOFTWARE.
#
#hist#	2026-02-09 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	cpi_mime.pm - Parse mimes config file for extension and base types
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
    %cpi_vars::EXT_TO_BASE_TYPE = ();
    %cpi_vars::MIME_TYPE_TO_EXTS = ();
    %cpi_vars::MIME_TYPE_TO_BASE_TYPE = ();
    %cpi_vars::BASE_TYPE_TO_EXTS = ();
    %cpi_vars::BASE_TYPE_TO_MIME_TYPES = ();
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
	    grep( $cpi_vars::BASE_TYPE_TO_EXTS{$base_type}{$_}=1, @exts );
	    $cpi_vars::BASE_TYPE_TO_MIME_TYPES{$base_type}{$mimestr} = 1;
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
