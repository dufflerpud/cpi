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

package cpi_magic_http;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw();
use lib ".";

use cpi_cgi;
use cpi_file;
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
    &cpi_file::fatal("cpi_vars::CACHEDIR not defined.") if( !defined($cpi_vars::CACHEDIR) );
    $postname = "$cpi_vars::CACHEDIR/$postname.post";

    if( $argp->{args} )
	{
	my $datastring = join('&',@{$argp->{args}});
	my @fixedargs;
	foreach my $arg ( @{ $argp->{args} } )
	    {
	    push( @fixedargs, &cpi_cgi::safe_url($1).'='.&cpi_cgi::safe_url($2) )
		if( $arg =~ /(.*?)=(.*)/ );
	    }
	my $fixeddatastring = join("&",@fixedargs);
	#my $fixeddatastring = &cpi_cgi::safe_url( join("&",@{$argp->{args}}) );
	if( $USING_FILE )
	    {
	    my $piece = $argp->{http};
	    $piece =~ s:.*/::;
	    $piece =~ s/[^A-Za-z0-9]+/_/g;
	    &cpi_file::write_file( $tmpfile=$postname, $fixeddatastring );
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
	    &cpi_file::write_file( $tmpfile=$postname, $argp->{contents} );
	    push( @cmd,
		{	wget=>" --post-file=$tmpfile",
			curl=>" -d \@$tmpfile"		} -> { $USING } );
	    }
	push( @cmd, " '$argp->{http}'" );
	}
    else
	{ push( @cmd, " '$argp->{http}'" ); }
    my $cmd_string = join("",@cmd,"|");
    my $contents = &cpi_file::read_file( $cmd_string );
#   print "cmd=[ $cmd_string ]<br>\n";
#	    #unlink( $tmpfile ) if( $tmpfile );
    return $contents;
    }

1;
