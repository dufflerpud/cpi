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

package cpi_filename;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( dirname filename_to_text text_to_filename no_ext_of
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
    $text =~ s/[^A-Za-z0-9]+/_/g;		# Chriss__file_
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
