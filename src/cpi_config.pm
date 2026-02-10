#!/usr/bin/perl -w
#indx#	cpi_config.pm - Read configuration files
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
#doc#	cpi_config.pm - Read configuration files
########################################################################

use strict;

package cpi_config;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( read_config read_map );
use lib ".";

use cpi_file qw( autopsy read_file read_lines );
#__END__
1;
#########################################################################
#	Read in a previously written configuration file.		#
#########################################################################
sub read_config
    {
    my( $fn, $varref ) = @_;
    my( $vtype ) = ref( $varref );

    if( -f $fn )
	{ $_ = &read_file( $fn ); }
    else
        { $_ = "\$VAR1 = {};"; }

    if( /^\$VAR1/ )
        {
	my $VAR1;	# Will be set by evaluating $_
	eval( $_ );
	if( $vtype eq "HASH" )
	    { %{$varref} = %{ $VAR1 }; }
	elsif( $vtype eq "ARRAY" )
	    { @{$varref} = @{ $VAR1 }; }
	return;
	}

    if( $vtype eq "HASH" )
	{
	my %temp;		# Why do I have to create a temporary var?
	eval( "\%temp = $_" );
	%{$varref} = %temp;
	}
    elsif( $vtype eq "ARRAY" )
	{
	my @temp;		# Why do I have to create a temporary var?
	eval( "\@temp = $_" );
	@{$varref} = @temp;
	}
    else
	{&autopsy("read_config refers to unknown variable type:".$vtype);}
    return 1;
    }

#########################################################################
#	Create a map of all different kinds of ways of saying the	#
#	same thing back to the canonical form.				#
#	Returns a search string for all those things plus a map.	#
#########################################################################
sub read_map
    {
    my( $filename ) = @_;
    my %map;
    my @all_items;
    foreach my $ln ( &read_lines( $filename ) )
	{
	my( @items ) = split(/\s*,\s*/,$ln);
	my( @lcitems ) = map { lc($_) } @items;
	grep( $map{ $_ } = $items[0], @lcitems );
	push( @all_items, @lcitems );
	}
    my $search = join("|",@all_items);
    return( $search, %map );
    }
1;
