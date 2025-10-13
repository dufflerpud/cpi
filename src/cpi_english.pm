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
our @EXPORT = qw( match_case nword plural );
use lib ".";

#__END__
1;

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
#	not all words.							#
#########################################################################
sub plural
    {
    my( $word ) = @_;
    my $lcword = lc( $word );
    my $ret =
    	{
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
	"child"		=>	"children",
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
	"person"	=>	"people",
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
	"woman"		=>	"women",
	"photo"		=>	"photos",
	"piano"		=>	"pianos",
	"roof"		=>	"roofs"
	} -> { $lcword };
    if( $ret )
	{}
    elsif( $lcword =~ /.(s|x|z|ch|sh|o)$/ )
	{ $ret = $word."es"; }
    elsif( $lcword =~ /(.*)y$/ )
	{ $ret = $1."ies"; }
    elsif( $lcword =~ /(.*)(f|fe)$/ )
	{ $ret = $1."ves"; }
    elsif( $lcword =~ /(.*)man$/ )
    	{ $ret = $1."men"; }
    else
	{ $ret = $lcword."s"; }
    return &match_case( $ret, $word );
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

1;
