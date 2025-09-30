#!/usr/local/bin/perl -w
#@HDR@	$Id$
#@HDR@		Copyright 2024 by
#@HDR@		Christopher Caldwell/Brightsands
#@HDR@		P.O. Box 401, Bailey Island, ME 04003
#@HDR@		All Rights Reserved
#@HDR@
#@HDR@	This software comprises unpublished confidential information
#@HDR@	of Brightsands and may not be used, copied or made available
#@HDR@	to anyone, except in accordance with the license under which
#@HDR@	it is furnished.

use strict;

# Untested, HIGHLY unlikely to work (though it did at one time).

package cpi_trans_babelfish;

use strict;

use Exporter;
use AutoLoader;

our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );

our @EXPORT_OK = qw( );
our @EXPORT = qw( pkg_get_language_list_from_Babelfish
 pkg_set_language_pair pkg_trans_chunk );
#__END__
1;

my $BABEL_PROG	= "http://babelfish.altavista.com/tr";
my $DEBUG_TR	= "/tmp/trans.\%04d";

my $debtrctr	= 0;
my $tr_obj;

#########################################################################
#	Do whatever setup is required to translate from and to the	#
#	languages specified in the arguments.  Return the maximum	#
#	chunk size we can translate (or 0 if we've failed).		#
#########################################################################
sub pkg_set_language_pair
    {
    $tr_obj = \{ @_ };
    return 2000;
    }

#########################################################################
#	Translate a chunk of text.  Should already be setup with	#
#	set_language_pair.						#
#########################################################################
sub pkg_trans_chunk
    {
    my( $to_translate ) = @_;
    my $inphrase = $to_translate;
    $inphrase =~ s/([^a-zA-Z0-9_\.-])/uc sprintf("%%%02x",ord($1))/eg;
    my $postdata = "doit=done&intl=1"
        . "&lp=" . $tr_obj->src . "_" . $tr_obj->dest . "&trtext=$inphrase";
    my $tfilename;
    if( $DEBUG_TR )
	{ $tfilename = sprintf( "$DEBUG_TR.i", ++$debtrctr ); }
    elsif( length($postdata) > 1000 )
	{ $tfilename = &COMMON::tempfile(); }
    &COMMON::write_file( $tfilename, $postdata ) if( $tfilename );

    my $res;
    my $cmd =
      "wget -o /dev/null --header='Accept-Charset: ISO-8859-1,utf-8' " .
	( $tfilename
	    ?  "--post-file=$tfilename '$BABEL_PROG'"
	    : "'$BABEL_PROG?$postdata'"
	) . " -O - 2>/dev/null |";

    while( ($res= &COMMON::read_file($cmd)) eq "" )
	{ sleep(2); } # Loop because sometimes site returns nothing

    unlink( $tfilename ) if( ! $DEBUG_TR && $tfilename );
    if( $DEBUG_TR )
	{ &COMMON::write_file( sprintf("$DEBUG_TR.o",$debtrctr), $res ); }
    elsif( $tfilename )
	{ unlink( $tfilename ); }
    if( $res =~ /<div id="result"><div style="padding:0.6em;">(.*?)<\/div><\/div>/s )
	{
	my $badly_quoted = $1;
	$badly_quoted =~ s/\&amp; ([a-zA-A#0-9]+);/&$1;/gs;
	return $badly_quoted;
	}
    # elsif( $phrase =~ /^\s*0+\s*$/ )		# Would not compile
    elsif( $res =~ /^\s*0+\s*$/ )
	{ return $to_translate; }
    return "";
    }

#########################################################################
#	Get a list of languages Babelfish knows about.			#
#########################################################################
sub pkg_get_language_list_from_Babelfish
    {
    my( $langfrom ) = @_;
    my %langmap;
    open( INF, "wget -q -o /dev/null '$BABEL_PROG' -O - |" )
	|| &COMMON::fatal("Cannot wget $BABEL_PROG:  $!");
    while( $_ = <INF> )
	{
	if( /option value="${langfrom}_(.*?)">.*? to (.*?)<\/option>/ )
	    {
	    if( $2 eq "Chinese-simp" )
	        { $langmap{$1} = "simplified Chinese"; }
	    elsif( $2 eq "Chinese-trad" )
	        { $langmap{$1} = "traditional Chinese"; }
	    else
		{ $langmap{$1} = $2; }
	    }
	}
    close( INF );
    return %langmap;
    }

1;
