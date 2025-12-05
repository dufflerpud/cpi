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

package cpi_translate;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( breakup_and_translate_strings
 cleanup_translator gen_language_params
 get_full_language_list get_language_list init_phrases
 save_phrases set_language_pair tran_db trans trans_chunk
 transeq translate xlate xlfatal xlphrase xprint );
use lib ".";

use cpi_db qw( db_readable db_writable dbarr dbget dbpop
 dbput dbread dbwrite );
use cpi_file qw( autopsy register_cleanup read_file write_file );
use cpi_help qw( help_strings );
use cpi_trans_shell qw( pkg_get_language_list
 pkg_set_language_pair pkg_trans_chunk );
use cpi_lock qw( lock_file unlock_file );
use cpi_trans_shell;	# Or cpi_trans_babel or cpi_trans_lingua
use cpi_vars;
#__END__
1;

my %needs_translation = ();

sub set_language_pair	{ return &pkg_set_language_pair(@_); }
sub get_language_list	{ return &pkg_get_language_list(@_); }
sub trans_chunk		{ return &pkg_trans_chunk(@_); }

#########################################################################
#	Get any phrases that we're keeping track of.			#
#########################################################################
sub init_phrases
    {
    my $phrase_file = "$cpi_vars::COMMONDIR/phrases";
    grep( $needs_translation{$_}++, &read_lines( $phrase_file ) )
	if( -f $phrase_file );
    }

#########################################################################
#	Save any new phrases we've seen for translation.		#
#########################################################################
sub save_phrases
    {
    my $phrase_file = "$cpi_vars::COMMONDIR/phrases";
    &write_file( $phrase_file, map { $_, "\n" } sort keys %needs_translation );
    }

#########################################################################
#	Break a really big string up into acceptably sized pieces	#
#	based on a provided regular expression.				#
#########################################################################
sub breakup_and_translate_strings
    {
    my( $str, $lang_from, $lang_to, $expr ) = @_;
    my @ret = ();
    my @sofar = ();
    my $len_so_far = 0;
    my $size = &set_language_pair( $lang_from, $lang_to );
    $expr = "($expr)";
    foreach my $piece ( split(m~$expr~i,$str) )
        {
	my $l = length($piece);
	if( @sofar && ($len_so_far + $l) > $size )
	    {
	    push( @ret, &trans_chunk( join("",@sofar) ) );
	    @sofar = ();
	    $len_so_far = 0;
	    }
	push( @sofar, $piece );
	$len_so_far += $l;
	}
    push( @ret, &trans_chunk( join("",@sofar) ) );
    return join("",@ret);
    }

#########################################################################
#	Translate phrase from and to specified languages.		#
#########################################################################
sub translate
    {
    my( $langfrom, $langto, $phrase ) = @_;
    print STDERR "Translate [$phrase] from [$langfrom] to [$langto]\n";
    my $retres;
    if( $phrase !~ /\w/ )
	{ $retres = $phrase; }
    elsif( $langfrom eq $langto )
        { $retres = "[0:$phrase]"; }
    else
	{
	$retres = &breakup_and_translate_strings(
	    $phrase,$langfrom,$langto,".*?\\.\\s+");
	$retres =~ s/[\r\n]+/ /gs;
    	}
    return $retres;
    }

#########################################################################
#	Get a list of languages we generally know about.		#
#########################################################################
sub get_full_language_list
    {
    my( $lang_from ) = @_;
    my %langmap = &get_language_list( $lang_from );
    $langmap{$cpi_vars::WRITTEN_IN} = "English";
    $langmap{$cpi_vars::LANG_TRAN} = "Double Translation";
    return %langmap;
    }

#########################################################################
#	Read in all the phrases already queued up to be translated.	#
#########################################################################
my %text_batched_to_translate;
my $batch_state = "unread";
sub add_to_batch
    {
    grep( $text_batched_to_translate{$_}=1,
	split("####\n", &read_file($cpi_vars::TRANSLATIONS_TODO)) );
    }

#########################################################################
#	Look for previous translation.  If we don't have one, call	#
#	the translater and remember the results.			#
#########################################################################
sub tran_db
    {
    my( $langfrom, $langto, $phrase ) = @_;

    if( $phrase =~ /^(\w+)\|(.*)/ )
        {
	$langfrom = $1;
	$phrase = $2;
	}

    if( ($langfrom eq $langto) || ($phrase !~ /\w/) )
        {
	return $phrase;
	}
    elsif( $langto eq $cpi_vars::LANG_TRAN )
	{
	my( $interim ) = ( ($langfrom eq "en") ? "fr" : "en" );
	my( $pass1, $pass2 );
	return "[1:$phrase]"
	    unless defined($pass1=&tran_db($langfrom,$interim,$phrase));
	return "[2:$phrase]"
	    unless defined($pass2=&tran_db($interim,$langfrom,$pass1));
	return "[$pass2]";
	}
    else
	{
	&dbread($cpi_vars::TRANSLATIONS_DB)
	    if( ! &db_readable( $cpi_vars::TRANSLATIONS_DB ) );
	my $mapped_phrase =
	    &dbget( $cpi_vars::TRANSLATIONS_DB,
		$langfrom, $langto, $phrase );
	if( ! defined($mapped_phrase) )
	    {
	    $cpi_vars::TRANSLATIONS_BATCH if(0);	# Get rid of "only used once" warning
	    if( $cpi_vars::TRANSLATIONS_BATCH )
		{
		if( $batch_state eq "unread" )
		    {
		    %text_batched_to_translate = &add_to_batch();
		    $batch_state = "read";
		    }
	        if( ! $text_batched_to_translate{"${langfrom}:$phrase"}++ )
		    {
		    print STDERR __LINE__, ": We need something translated.\n";
		    &register_cleanup(\&cleanup_translator)
			if( $batch_state ne "modified" );
		    $batch_state = "modified";
		    }
		$mapped_phrase = "{$langfrom-$langto-$phrase}";
		}

	    $cpi_vars::TRANSLATIONS_LIVE if(0);	# Get rid of "only used once" warning
	    $mapped_phrase= &translate($langfrom,$langto,$phrase)
		if( $cpi_vars::TRANSLATIONS_LIVE );

	    if( defined( $mapped_phrase ) )
		{
		if( ! &db_writable( $cpi_vars::TRANSLATIONS_DB ) )
		    {
		    &register_cleanup( \&cleanup_translator );
		    &dbwrite( $cpi_vars::TRANSLATIONS_DB );
		    }
		&dbput($cpi_vars::TRANSLATIONS_DB,
		    $langfrom, $langto, $phrase, $mapped_phrase );
		}
	    }
	return $mapped_phrase;
	}
    }

#########################################################################
#	Return true if two strings are equal (after stripping out	#
#	language information.						#
#########################################################################
sub transeq
    {
    my( $s0, $s1 ) = @_;
    if( $s0 =~ /^(\w+)\|(.*)/s )
        {
	my( $s0lang, $s0phrase ) = ( $1, $2 );
	return ( ($s0lang eq $1) && ($s0phrase eq $2) )
	    if( $s1 =~ /^(\w+)\|(.*)/ );
	return ( $s0phrase ne $s1 );
	}
    return ( $s0 eq $2 ) if( $s1 =~ /^(\w+)\|(.*)/s );
    return ( $s0 eq $s1 );
    }

#########################################################################
#	Translate a string that was input from a user to current	#
#	language.  If string contains xx| notation, use "xx" as the	#
#	source language.  Else use language code written in.		#
#########################################################################
sub trans
    {
    my @res = ();
    my $txt;
    foreach $txt ( @_ )
        {
	push( @res,
	    ( ( $txt =~ /^([a-z][a-z])\|(.*)/s )
	    ? &tran_db($1,$cpi_vars::LANG,$2)
	    : &tran_db($cpi_vars::WRITTEN_IN,$cpi_vars::LANG,$txt)
	    ) );
	}
    return ( wantarray ? @res : $res[0] );
    }

#########################################################################
#	Returns a string appropriate for switching languages.		#
#########################################################################
sub gen_language_params
    {
    &dbread( $cpi_vars::TRANSLATIONS_DB )
	if( ! &db_readable( $cpi_vars::TRANSLATIONS_DB ) );
    my $l;
    my @lanlist = &dbget( $cpi_vars::TRANSLATIONS_DB, "LANGUAGES" );
    if( ! @lanlist )
        {
	my %lmap = &get_full_language_list( $cpi_vars::WRITTEN_IN );
        if( ! &db_writable( $cpi_vars::TRANSLATIONS_DB ) )
	    {
	    &register_cleanup( \&cleanup_translator );
	    &dbwrite( $cpi_vars::TRANSLATIONS_DB );
	    }
	foreach $l ( keys %lmap )
	    {
	    &dbput($cpi_vars::TRANSLATIONS_DB,$cpi_vars::WRITTEN_IN,
	        "prompt_for_$l","Communicate in $lmap{$l}");
	    }
	@lanlist = sort keys %lmap;
	&dbput($cpi_vars::TRANSLATIONS_DB,"LANGUAGES",
	    &dbarr(@lanlist));
	}

    if( ! $cpi_vars::LANG )
	{
	$l = $ENV{HTTP_ACCEPT_LANGUAGE};
	$l =~ s/;.*//g;
	$l =~ s/\s//g;
	my @browser_lans = split(',',$l);
	foreach $l ( grep( s/-.*// || 1, @browser_lans ) )
	    {
	    if( grep( $_ eq $l, @lanlist ) )
	        {
		$cpi_vars::LANG = $l;
		last;
		}
	    }
	$cpi_vars::LANG = $cpi_vars::WRITTEN_IN
	    if( ! $cpi_vars::LANG || ( $cpi_vars::LANG eq "" ) );
	}
    my %selflag = ( $cpi_vars::LANG, " selected" );
    my @options = ();
    foreach $l ( @lanlist )
        {
	my $phrase = &dbget(
			$cpi_vars::TRANSLATIONS_DB,
			$cpi_vars::WRITTEN_IN,
			"prompt_for_$l" );
	my $mapped_phrase =
	    &tran_db( $cpi_vars::WRITTEN_IN, $l, $phrase );
	push( @options, "<option value=$l".($selflag{$l}||"").">$mapped_phrase" );
	}
    if( ! @options )
        { return ""; }
    else
        {
	return
	    "<tr><th colspan=2>" .
	    "<select name=LANG help='COMMON_account_language' onChange='submit();'>\n" .
	    join("\n",@options) . "\n</select></th></tr>";
	}
    }

#########################################################################
#	Actually perform the translation within a XL() or XL{}		#
#	Numbers and things left within <<>> are left untranslated.	#
#########################################################################
sub xlphrase
    {
    my( $phrase ) = @_;

    return $phrase if( $phrase =~ /^\s*$/ );

    my $srclang = $cpi_vars::WRITTEN_IN;
    $cpi_vars::LANG=$cpi_vars::WRITTEN_IN
	if( ! defined($cpi_vars::LANG) || ($cpi_vars::LANG eq "") );

    # Allow embedded numbers by converting them to consistent text
    my $ind = 0;
    my @new_phrase_parts = ();
    my @translate_back = ();
    foreach my $phrase_part ( split(/(\d[\.0-9]*|\[\[.*?\]\])/, $phrase ) )
        {
	if( $phrase_part =~ /^\d/ )
	    {
	    $translate_back[$ind] = $phrase_part;
	    push( @new_phrase_parts, "QLQZ".$ind++ );
	    }
	elsif( $phrase_part =~ /^\[\[(.*)\]\]$/ )
	    {
	    $translate_back[$ind] = $1;
	    push( @new_phrase_parts, "QLQZ".$ind++ );
	    }
	else
	    { push( @new_phrase_parts, $phrase_part ); }
	}
    my $mapped_phrase =
	&tran_db($srclang,$cpi_vars::LANG,join("",@new_phrase_parts));
    return "[3:$phrase]" if( !defined($mapped_phrase) );
    return $mapped_phrase if( $mapped_phrase !~ /\d/ );
    @new_phrase_parts = ();
    foreach my $phrase_part ( split(/(QLQZ\d+)/, $mapped_phrase ) )
        {
	push( @new_phrase_parts,
	    ( ($phrase_part =~ /^QLQZ(\d*)/ )
	    ? $translate_back[$1]
	    : $phrase_part ) );
	}
    return join("",@new_phrase_parts);
    }

#########################################################################
#	Sift through text, translating things within XL()s.		#
#	Needs to be careful about nested parens.  Allow the use of	#
#	other character pairs.						#
#########################################################################
sub xlate
    {
    my( $txt ) = join("",@_);
    my @return_pieces = ();
    my( $leftc, $rightc );
    my $lvl = 0;
    my @toxl;

    # Pre merge from cruise
    #foreach my $v0 ( split( /(XL\(|\(|\)|XL{|{|}|XL<|<|>|XL\[|\[|\])/, $txt ) )

    foreach my $v0 ( split( /(XL\(|\(|\)|XL\{|\{|\}|XL<|<|>|XL\[|\[|\])/, $txt ) )
        {
	if( $lvl == 0 )
	    {
	    if(    $v0 eq "XL(" )	{ $leftc="("; $rightc=")"; }
	    elsif( $v0 eq "XL{" )	{ $leftc="{"; $rightc="}"; }
	    elsif( $v0 eq "XL<" )	{ $leftc="<"; $rightc=">"; }
	    elsif( $v0 eq "XL[" )	{ $leftc="["; $rightc="]"; }
	    else			{ push( @return_pieces, $v0 ); next; }
	    @toxl = ();
	    $lvl = 1;
	    }
	else
	    {
	    if( $v0 eq $leftc )
	        { $lvl++; }
	    elsif( $v0 eq $rightc )
	        { $lvl--; }
	    if( $lvl > 0 )
	        { push( @toxl, $v0 ); }
	    else
		{ push(@return_pieces, &xlphrase(join("",@toxl)) ); }
	    }
	}
    if( defined( $cpi_vars::TRANSLATIONS_DB ) )
	{
	&dbpop( $cpi_vars::TRANSLATIONS_DB )
	    while( &db_writable( $cpi_vars::TRANSLATIONS_DB ) );
	}
    return join("",@return_pieces);
    }


#########################################################################
#	Send a translated string to STDOUT.				#
#########################################################################
sub xprint
    {
    print &help_strings( &xlate(join("",@_)) );
    }

#########################################################################
#	Clean up databases						#
#########################################################################
sub cleanup_translator
    {
    print STDERR "cleanup_translator called, batch_state=[$batch_state]\n";
    if( $batch_state eq "modified" )
        {
	&lock_file( $cpi_vars::TRANSLATIONS_TODO );
	&add_to_batch();	# Re-read:  The list may have grown!
	&write_file( $cpi_vars::TRANSLATIONS_TODO,
	    map {($_,"####\n")} sort keys %text_batched_to_translate );
	&unlock_file( $cpi_vars::TRANSLATIONS_TODO );
	$batch_state = "unread";
	}
    if( defined( $cpi_vars::TRANSLATIONS_DB ) )
	{
	&dbpop( $cpi_vars::TRANSLATIONS_DB )
	    while( &db_writable( $cpi_vars::TRANSLATIONS_DB ) );
	}
    }

#########################################################################
#	We can translate this error message.				#
#########################################################################
sub xlfatal
    {
    &autopsy( &xlate( @_ ) );
    }
1;
