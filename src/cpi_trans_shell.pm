#!/usr/local/bin/perl -w
#@HDR@	$Id$
#@HDR@		Copyright 2024 by
#@HDR@		Christopher Caldwell
#@HDR@		P.O. Box 401, Bailey Island, ME 04003
#@HDR@		All Rights Reserved
#@HDR@
#@HDR@	This software comprises unpublished confidential information
#@HDR@	of the copyright holder and may not be used, copied or made
#@HDR@	available to anyone, except in accordance with the license
#@HDR@	under which it is furnished.

use strict;

package cpi_trans_shell;

use Exporter;
use AutoLoader;

our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );

our @EXPORT_OK = qw( );
our @EXPORT = qw( pkg_configure_for_translation
 pkg_get_language_list pkg_set_language_pair pkg_trans_chunk );

use lib ".";
use cpi_file qw( tempfile read_file write_file read_lines );

my $TRANS_BIN = "/bin/trans";
#__END__
1;

#########################################################################
#	Can get invoked either during translation or getting lang list	#
#########################################################################
my $tmp_file;
sub pkg_configure_for_translation
    {
    $tmp_file = &tempfile( ".txt" ) if( ! $tmp_file );
    }

#########################################################################
#	Do whatever setup is required to translate from and to the	#
#	languages specified in the arguments.  Return the maximum	#
#	chunk size we can translate (or 0 if we've failed).		#
#########################################################################
my ( $glob_lang_from, $glob_lang_to );
sub pkg_set_language_pair
    {
    my( $lang_from, $lang_to ) = @_;
    ( $glob_lang_from, $glob_lang_to ) = ( $lang_from, $lang_to );
    return 4096;
    }

#########################################################################
#	Translate a chunk of text.  Should already be setup with	#
#	set_language_pair.						#
#########################################################################
sub pkg_trans_chunk
    {
    my( $text ) = @_;
    my( $l ) = length( $text );
    &pkg_configure_for_translation();
    #print "length($l):  $text\n";
    &write_file( $tmp_file, $text );
    my $ret = &read_file(
	"$TRANS_BIN -b ${glob_lang_from}:${glob_lang_to} < $tmp_file |" );
    print STDERR "trans_chunk(${glob_lang_from}:${glob_lang_to},$text) returns [",
	( $ret ? $ret : "UNDEF" ), "]\n";
    return $ret;
    }

#########################################################################
#	Get a list of languages Google knows about.			#
#########################################################################
sub pkg_get_language_list
    {
    my( $langfrom ) = @_;

    &pkg_configure_for_translation();
    my %langmap = ();
    foreach $_ ( &read_lines( "$TRANS_BIN -list-all |" ) )
	{
	my( $code, $english, $native ) = split(/\s\s\s*/,$_);
	#$langmap{$code} = $native;
	$langmap{$code} = $english;
	}

#    foreach my $k ( sort keys %langmap )
#        { print STDERR "$k=>$langmap{$k}\n"; }

    return %langmap;
    }
1;
