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

package cpi_english;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( match_case nword plural conjoin );
use lib ".";

#__END__
1;

my %plural_cache =
	(
	"addendum"	=>	"addenda",
	"aircraft"	=>	"aircraft",
	"alumna"	=>	"alumnae",
	"alumnus"	=>	"alumni",
	"analysis"	=>	"analyses",
	"antenna"	=>	"antennae",
	"antithesis"	=>	"antitheses",
	"apex"		=>	"apices",
	"appendix"	=>	"appendices",
	"axis"		=>	"axes",
	"bacillus"	=>	"bacilli",
	"bacterium"	=>	"bacteria",
	"basis"		=>	"bases",
	"beau"		=>	"beaux",
	"bison"		=>	"bison",
	"bureau"	=>	"bureaux",
	"cactus"	=>	"cacti",
	"château"	=>	"châteaux",
	"codex"		=>	"codices",
	"concerto"	=>	"concerti",
	"corpus"	=>	"corpora",
	"crisis"	=>	"crises",
	"criterion"	=>	"criteria",
	"curriculum"	=>	"curricula",
	"datum"		=>	"data",
	"deer"		=>	"deer",
	"diagnosis"	=>	"diagnoses",
	"die"		=>	"dice",
	"ellipsis"	=>	"ellipses",
	"erratum"	=>	"errata",
	"faux pas"	=>	"faux pas",
	"fez"		=>	"fezzes",
	"fish"		=>	"fish",
	"focus"		=>	"foci",
	"foot"		=>	"feet",
	"formula"	=>	"formulae",
	"fungus"	=>	"fungi",
	"genus"		=>	"genera",
	"goose"		=>	"geese",
	"graffito"	=>	"graffiti",
	"grouse"	=>	"grouse",
	"hypothesis"	=>	"hypotheses",
	"index"		=>	"indices",
	"larva"		=>	"larvae",
	"libretto"	=>	"libretti",
	"locus"		=>	"loci",
	"louse"		=>	"lice",
	"man"		=>	"men",
	"matrix"	=>	"matrices",
	"medium"	=>	"media",
	"memorandum"	=>	"memoranda",
	"minutia"	=>	"minutiae",
	"moose"		=>	"moose",
	"mouse"		=>	"mice",
	"nebula"	=>	"nebulae",
	"nucleus"	=>	"nuclei",
	"oasis"		=>	"oases",
	"offspring"	=>	"offspring",
	"opus"		=>	"opera",
	"ovum"		=>	"ova",
	"ox"		=>	"oxen",
	"parenthesis"	=>	"parentheses",
	"phenomenon"	=>	"phenomena",
	"phylum"	=>	"phyla",
	"quiz"		=>	"quizzes",
	"radius"	=>	"radii",
	"referendum"	=>	"referenda",
	"salmon"	=>	"salmon",
	"series"	=>	"series",
	"sheep"		=>	"sheep",
	"shrimp"	=>	"shrimp",
	"species"	=>	"species",
	"staff"		=>	"staff",
	"stimulus"	=>	"stimuli",
	"stratum"	=>	"strata",
	"swine"		=>	"swine",
	"syllabus"	=>	"syllabi",
	"symposium"	=>	"symposia",
	"synopsis"	=>	"synopses",
	"tableau"	=>	"tableaux",
	"thesis"	=>	"theses",
	"tooth"		=>	"teeth",
	"trout"		=>	"trout",
	"tuna"		=>	"tuna",
	"vertebra"	=>	"vertebrae",
	"vertex"	=>	"vertices",
	"vita"		=>	"vitae",
	"vortex"	=>	"vortices",
	"photo"		=>	"photos",
	"piano"		=>	"pianos",
	"roof"		=>	"roofs"
	);

#########################################################################
#	Return first arg capitalized with same scheme as second arg	#
#########################################################################
sub match_case
    {
    my( $word, $ref ) = @_;
    return lc( $word )			if( lc($ref) eq $ref );
    return uc( $word )			if( uc($ref) eq $ref );
    return ucfirst( lc( $word ) );
    }

#########################################################################
#	You generally pluralize words in English by adding "s", but	#
#	not all words.  Cache starts out with results we would get	#
#	wrong if we used our ruleset (English is full of exceptions)	#
#	so we never try to compute it (and get it wrong).  We'll also	#
#	stick stuff we generate in as well for performance reasons.	#
#	Note that this assumes the cache primer is totally lower case.	#
#########################################################################
sub plural
    {
    my( $word ) = @_;
    my $ret;

    if( ! ( $ret = $plural_cache{$word} ) )
	{
	my $lcword = lc( $word );

	if( $ret = $plural_cache{$lcword} )	{ }
	elsif( $lcword =~ /.(s|x|z|ch|sh|o)$/ )	{ $ret = $word."es"; }
	elsif( $lcword =~ /(.*)y$/ )		{ $ret = $1."ies"; }
	elsif( $lcword =~ /(.*)(f|fe)$/ )	{ $ret = $1."ves"; }
	elsif( $lcword =~ /(.*)man$/ )		{ $ret = $1."men"; }
	elsif( $lcword =~ /(.*)child$/ )	{ $ret = $1."children"; }
	elsif( $lcword =~ /(.*)person$/ )	{ $ret = $1."people"; }
	else					{ $ret = $lcword."s"; }

	$plural_cache{$lcword}			= $ret;
	$plural_cache{uc($lcword)}		= uc( $ret );
	$plural_cache{ucfirst($lcword)}		= ucfirst( $ret );
	$ret = &match_case( $ret, $word );
	}
    return $ret;
    }

#########################################################################
#	I've written this so many times I gave up and put it in a	#
#	library.							#
#########################################################################
sub nword
    {
    my( $a0, $a1 ) = @_;
    my( $n, $word ) = ( $a0=~/\d/ ? ($a0,$a1) : ($a1,$a0) );
    return join(" ",$n, ($n==1 || $n==-1) ? $word : &plural($word) );
    }

#########################################################################
#	Stupid but handy routine to create readable lists.  First arg	#
#	is the joining word (either "and" or "or".  Some day, maybe	#
#	even "but"!).							#
#	Typically called with:						#
#	    &conjoin( "and", @items );					#
#	    &conjoin( "or", @items );					#
#########################################################################
sub conjoin
    {
    my( $word, @itemlist ) = @_;
    my( $listsize ) = scalar( @itemlist );
    return join(" $word ",@itemlist) if( $listsize <= 2 );
    return join(", ",@itemlist[0..$#itemlist-1])." $word $itemlist[$#itemlist]";
    }
1;
