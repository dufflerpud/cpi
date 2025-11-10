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

package cpi_template;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( subst_list template );
use lib ".";

use cpi_file qw( read_file );
use cpi_vars;
#__END__
1;

#########################################################################
#	Apply a list of substitutions to a string.			#
#########################################################################
sub subst_list
    {
    my( $contents, @substs ) = @_;
    my $varname;

    push( @substs,
	"%%BODY_TAGS%%",	$cpi_vars::BODY_TAGS,
	"%%TABLE_TAGS%%",	$cpi_vars::TABLE_TAGS,
	"%%SID%%",		$cpi_vars::SID,
	"%%USER%%",		$cpi_vars::USER,
	"%%PROG%%",		$cpi_vars::PROG
	);
    while( defined($varname = shift(@substs) ) )
	{
	my $val = shift(@substs);
	$contents =~ s/$varname/$val/gms;
	}
    return $contents;
    }

#########################################################################
#	Apply substitutions to a file.					#
#########################################################################
sub template
    {
    my( $filename, @substs ) = @_;
    return &subst_list( &read_file($filename), @substs );
    }

1;
