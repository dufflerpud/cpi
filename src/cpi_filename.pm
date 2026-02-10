#!/usr/bin/perl -w
#indx#	cpi_filename.pm - Filename manipulation
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
#doc#	cpi_filename.pm - Filename manipulation
########################################################################

use strict;

package cpi_filename;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( dirname basename filename_to_text text_to_filename no_ext_of
 just_ext_of same_ext);
use lib ".";


#__END__
1;

#########################################################################
#	Make text safe as a filename (without directory or extension).	#
#########################################################################
sub text_to_filename
    {
    my( $text ) = @_;				# Chris's  file!
    $text =~ s/'s/s/g;				# Chriss  file!
    $text =~ s/[^A-Za-z0-9\.]+/_/g;		# Chriss__file_
    $text =~ s/__*/_/g;				# Chriss_file_
    $text = $1 if( $text =~ /^_*(.*?)_*$/ );	# Chriss_file
    return $text;
    }
#
#########################################################################
#	Convert filename into text.					#
#########################################################################
sub filename_to_text
    {
    my( $text ) = @_;				# /tmp/Chris_file.jpg
    $text =~ s:.*/::;				# Chris_file.jpg
    $text =~ s/\.\w+$//;			# Chris_file
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

#########################################################################
#	Apparently perl's basename has gone away.			#
#########################################################################
sub basename
    {
    my( $str, @suffixes ) = @_;
    $str =~ s+.*/++;
    foreach my $toremove ( @suffixes )
	{ $str =~ s+$toremove$++; }
    return $str;
    }

#########################################################################
#	Return a file without any extension.				#
#########################################################################
sub no_ext_of
    {
    my( $fname ) = @_;
    return ( $fname =~ /(.*)\.(\w+)$/ ? $1 : $fname );
    }

#########################################################################
#	Return the extension of a filename.				#
#########################################################################
sub just_ext_of
    {
    my( $fname, $defext ) = @_;
    return $2 if ( $fname =~ /(.*)\.(\w+)$/ );
    return $defext if( defined($defext) );
    return "";
    }

#########################################################################
#	Return extension of one filename appended to another.		#
#########################################################################
sub same_ext
    {
    my( $fname1, $fname2 ) = @_;
    return &no_ext_of( $fname1 ) . "." . &just_exit_of( $fname2 );
    }
1;
