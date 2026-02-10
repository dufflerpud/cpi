#!/usr/bin/perl -w
#
#indx#	cpi_magic_http.pm - Front end to wget or curl
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
#doc#	cpi_magic_http.pm - Front end to wget or curl
########################################################################

use strict;

package cpi_magic_http;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( magic_http );
use lib ".";

use cpi_cgi qw( safe_url );
use cpi_file qw( autopsy read_file write_file );
#__END__
1;

#########################################################################
#	Get a URL referred to from argp.				#
#########################################################################
sub magic_http
    {
    my( $argp ) = @_;
    #print STDERR "magic_http called...\n";
    my $USING = ( -x "/usr/bin/curl" ? "curl" : "wget" );
    my $USING_FILE = $argp->{contents};
    my $USING_CURL_D = 0;
    my $USING_CURL_F = 0;

    my @cmd;
    my $tmpfile;

    push( @cmd,
	{	wget=>"wget -q -O -",
		curl=>"curl -s"		} -> {$USING} );

    $argp->{method} = ( $argp->{method} ? uc($argp->{method}) : "GET" );

    push( @cmd,
	{	wget=>"",
		curl=>" -X $argp->{method}"		} -> {$USING} );

    my $postname = $argp->{http};
    $postname =~ s:.*/::;
    $postname =~ s/[^A-Za-z0-9]+/_/g;
    &autopsy("cpi_vars::CACHEDIR not defined.") if( !defined($cpi_vars::CACHEDIR) );
    $postname = "$cpi_vars::CACHEDIR/$postname.post";

    if( $argp->{args} )
	{
	my $datastring = join('&',@{$argp->{args}});
	my @fixedargs;
	foreach my $arg ( @{ $argp->{args} } )
	    {
	    push( @fixedargs, &safe_url($1).'='.&safe_url($2) )
		if( $arg =~ /(.*?)=(.*)/ );
	    }
	my $fixeddatastring = join("&",@fixedargs);
	#my $fixeddatastring = &safe_url( join("&",@{$argp->{args}}) );
	if( $USING_FILE )
	    {
	    my $piece = $argp->{http};
	    $piece =~ s:.*/::;
	    $piece =~ s/[^A-Za-z0-9]+/_/g;
	    &write_file( $tmpfile=$postname, $fixeddatastring );
	    push( @cmd,
		{	wget=>" --post-file=$tmpfile",
			curl=>" -d \@$tmpfile"		} -> { $USING } );
	    push( @cmd, " '$argp->{http}'" );
	    }
	else
	    {
	    if( $USING eq "curl" && $USING_CURL_F )
		{
		push( @cmd,
		    ( map { " --form '$_'" } @fixedargs ),
		    " '",$argp->{http},"'" );
		}
	    else
	        {
		if( $USING eq "curl" && $USING_CURL_D )
		    { push( @cmd, " -H 'Content-Type: application/x-www-form-urlencoded' -d '$fixeddatastring' '$argp->{http}'" ); }
		else
		    { push( @cmd, " '$argp->{http}?$fixeddatastring'" ); }
		}
	    }
	}
    elsif( $argp->{contents} )
	{
	if( ! $USING_FILE )
	    {
	    push( @cmd,
		{	wget=>" --post-data=$argp->{contents}",
			curl=>" -d '$argp->{contents}'"	} -> { $USING } );
	    }
	else
	    {
	    &write_file( $tmpfile=$postname, $argp->{contents} );
	    push( @cmd,
		{	wget=>" --post-file=$tmpfile",
			curl=>" -d \@$tmpfile"		} -> { $USING } );
	    }
	push( @cmd, " '$argp->{http}'" );
	}
    else
	{ push( @cmd, " '$argp->{http}'" ); }
    my $cmd_string = join("",@cmd,"|");
    my $contents = &read_file( $cmd_string );
#   print "cmd=[ $cmd_string ]<br>\n";
#	    #unlink( $tmpfile ) if( $tmpfile );
    return $contents;
    }

1;
