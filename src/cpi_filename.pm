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

package cpi_filename;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( dirname filename_to_text text_to_filename );
use lib ".";


#__END__
1;

#########################################################################
#	Make text safe as a filename (without directory or extension).	#
#########################################################################
sub text_to_filename
    {
    my( $text ) = @_;				# Chris's file!
    $text =~ s/'s/s/g;				# Chriss file!
    $text =~ s/[^A-Za-z0-9\.]+/_/g;		# Chriss_file_
    $text = $1 if( $text =~ /^_*(.*?)_*$/ );	# Chriss_file
    return $text;
    }
#
#########################################################################
#	Convert filename (without directory or extension) into text.	#
#########################################################################
sub filename_to_text
    {
    my( $text ) = @_;				# Chris_file
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
1;
