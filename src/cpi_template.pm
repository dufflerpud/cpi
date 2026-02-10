#!/usr/bin/perl -w
#
#indx#	cpi_template.pm - Routines to search and substitute in template files
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2025-2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
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
#doc#	cpi_template.pm - Routines to search and substitute in template files
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
