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

package cpi_trans_lingua;

use Lingua::Translate;
#use Lingua::Translate::Google;
use I18N::LangTags::List;

use Exporter;
use AutoLoader;

our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );

our @EXPORT_OK = qw( );
our @EXPORT = qw( pkg_configure_for_translation
 pkg_get_language_list pkg_set_language_pair pkg_trans_chunk );
#__END__
1;

my $GOOGLE_PROG = "http://translate.google.com";

my $tr_obj;

my @BAD_LANGUAGES = ( "az", "eu", "hy", "ka", "la", "ur" );

#########################################################################
#	Can get invoked either during translation or getting lang list	#
#########################################################################
my $tr_configured;
sub pkg_configure_for_translation
    {
    if( ! $tr_configured )
	{
	Lingua::Translate::config
	    (
	    back_end	=> 'Google',
	    #api_key	=> 'YoUrApIkEy',
	    referer	=> 'http://www.brightsands.com/',
	    format	=> 'html',
	    userip	=> '75.191.175.95'
	    );
	$tr_configured = 1;
	}
    }

#########################################################################
#	Do whatever setup is required to translate from and to the	#
#	languages specified in the arguments.  Return the maximum	#
#	chunk size we can translate (or 0 if we've failed).		#
#########################################################################
sub pkg_set_language_pair
    {
    my( $lang_from, $lang_to ) = @_;

    &configure_for_translation();
    $tr_obj = Lingua::Translate->new(src=>$lang_from,dest=>$lang_to);
    return 4096;
    }

#########################################################################
#	Translate a chunk of text.  Should already be setup with	#
#	set_language_pair.						#
#########################################################################
sub pkg_trans_chunk
    {
    my( $l ) = length( $_[0] );
    #print "length($l):  $_[0]\n";
    return $tr_obj->translate( @_ );
    }

#########################################################################
#	Get a list of languages Google knows about.			#
#########################################################################
sub pkg_get_language_list
    {
    my( $langfrom ) = @_;

    &configure_for_translation();
    $tr_obj = Lingua::Translate::Google->new(src=>"en",dest=>"en");

    my %langmap = ();
    foreach my $lang_pair ( $tr_obj->available() )
        {
	if( $lang_pair =~ /^en_(.*)$/ )
	    {
	    $langmap{$1} = I18N::LangTags::List::name($1)
	        if( ! grep( $1 eq $_, @BAD_LANGUAGES ) );
	    }
	}
#    foreach my $k ( sort keys %langmap )
#        { print STDERR "$k=>$langmap{$k}\n"; }
    return %langmap;
    }
1;
