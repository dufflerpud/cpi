#!/usr/bin/perl -w
#indx#	cpi_cache.pm - Create cache for expensive commands
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
#doc#	cpi_cache.pm - Create cache for expensive commands
########################################################################

use strict;

package cpi_cache;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( cache );
use lib ".";

use cpi_file qw( autopsy read_file write_file );
use cpi_filename qw( dirname );
use cpi_hash qw( hashof );
use cpi_magic_http qw( magic_http );
use cpi_vars;
use Data::Dumper;
use MIME::Base64 qw( encode_base64 );

#__END__
1;

#########################################################################
#	Do an expensive command and store results to prevent having	#
#	to do it again.							#
#									#
#	We check to see if there is a file corresponding to the hash	#
#	of the expensive command.  If that file exists and it has the	#
#	same contents we just use the results in the corresponding	#
#	result file (which is why this is "caching").			#
#									#
#	Note:								#
#									#
#	Sadly, this means if the hash process produces the same	string	#
#	for different queries, it means we will re-issue the same	#
#	same expensive command (which is certainly better than		#
#	using the results from the other command with the same hash).	#
#									#
#	Also, there ain't no file locking going on here (though there	#
#	could be).  You can imagine two processes fighting over the	#
#	same hash.  I HIGHLY doubt this will happen over the lifetime	#
#	of this code, but code sometimes lives on long after it		#
#	it should.  If this gets used under very high performance	#
#	situations and breaks randomly, try adding locking.		#
#########################################################################
sub cache
    {
    my( $arg, $result_file ) = @_;
    my $argp;
    my $request = $arg;
    my $typeof = ref($arg);
    if( $typeof eq 'HASH' )
	{
	$argp = $arg;
	$request = Dumper( $argp );
	}
    elsif( $typeof eq 'CODE' )
	{ $argp = { routine=>$arg }; }
    elsif( $arg =~ /\|\s*$/ )
	{ $argp = { pipe=>$arg }; }
    elsif( $arg =~ /^https*:/ )
	{ $argp = { http=>$arg }; }
    else
	{ $argp = { eval_string=>$arg }; }

    if( ! ( $result_file ||= $argp->{result} ) )
	{
        $result_file = "$cpi_vars::PROG/%s";
	$result_file .= (".".$argp->{extension}) if( $argp->{extension} );
	}
    $result_file = "$cpi_vars::CACHEDIR/$result_file"
	if( $result_file !~ m:^/: );

    my $hash_of_request = &hashof( $request );
    $result_file = sprintf( $result_file, $hash_of_request )
	if( $result_file =~ /%s/ );
    my $regen = ! -r $result_file;

    my $query_file = $argp->{query};
    $query_file = sprintf( $query_file, $hash_of_request )
	if( $query_file =~ /%s/ );
    $regen = 1 if( $query_file && (&read_file($query_file,"") ne $request) );

    #print STDERR "rf=$result_file qf=$query_file regen=$regen.\n";
    system("mv $query_file $query_file.old.$$") if( $regen );

    my $contents;
    if( $regen )
	{
	system("mkdir -p $_") if( ! -d ($_=&dirname($result_file)) );
	if( $argp->{pipe} )
	    { $contents = &read_file($argp->{pipe}); }
	elsif( $argp->{routine} )
	    { $contents = &{ $argp->{routine} }; }
        elsif( $argp->{eval_string} )
	    { $contents = eval($argp->{eval_string}); }
	elsif( $argp->{http} )
	    { $contents = &magic_http( $argp ); }
	if( defined($_=$argp->{check}) && $contents !~ /$_/ )
	    {
	    &write_file("$query_file.failed.$$",$request) if( $query_file );
	    return undef;
	    }
	$contents = encode_base64( $contents ) if( $result_file =~ /\.b64$/ );
	&write_file($result_file,$contents);
	#print "Contents(", length($contents), ") written to $result_file.\n";
	&write_file($query_file,$request) if( $query_file );
	}

    if( ! $argp->{return} )
	{ return $contents || &read_file($result_file); }
    elsif( $argp->{return} eq "result_file" )
	{ return $result_file; }
    elsif( $argp->{return} eq "contents" )
	{ return $contents || &read_file($result_file); }
    else
	{ &autopsy("cache cannot return ".$argp->{return}); }
    }

1;
