#!/usr/local/bin/perl -w
#
#indx#	cpi_trans_shell.pm - Back-end to getting text translated
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2024-2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
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
#doc#	cpi_trans_shell.pm - Back-end to getting text translated
########################################################################

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
