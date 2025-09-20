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

package cpi_trans_none;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw();
use lib ".";


#__END__
1;

#########################################################################
#	Can get invoked either during translation or getting lang list	#
#########################################################################
sub pkg_configure_for_translation
    {
    }

#########################################################################
#	Do whatever setup is required to translate from and to the	#
#	languages specified in the arguments.  Return the maximum	#
#	chunk size we can translate (or 0 if we've failed).		#
#########################################################################
sub pkg_set_language_pair
    {
    my( $lang_from, $lang_to ) = @_;
    return 4096;
    }

#########################################################################
#	Translate a chunk of text.  Should already be setup with	#
#	set_language_pair.						#
#########################################################################
sub pkg_trans_chunk
    {
    return $_[0];
    }

#########################################################################
#	Get a list of languages Google knows about.			#
#########################################################################
sub pkg_get_language_list
    {
    my( $langfrom ) = @_;

    &configure_for_translation();

    my %langmap = ( "en" => "English" );
    return %langmap;
    }
1;
