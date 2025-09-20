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

package cpi_cache;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw();
use lib ".";

use cpi_file;
use cpi_filename;
use cpi_hash;
use cpi_magic_http;
use cpi_vars;
use Data::Dumper;
use MIME::Base64 qw( encode_base64 );

#__END__
1;

#########################################################################
#	Do an expensive command and store results to prevent having	#
#	to do it again.							#
#########################################################################
sub cache
    {
    my( $arg, $result_file ) = @_;
    #print "CMC cache($result_file) called.<br>\n";
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

    my $hash_of_request = &cpi_hash::hashof( $request );
    $result_file = sprintf( $result_file, $hash_of_request )
	if( $result_file =~ /%s/ );
    my $regen = ! -r $result_file;

    my $query_file = $argp->{query};
    $query_file = sprintf( $query_file, $hash_of_request )
	if( $query_file =~ /%s/ );
    $regen = 1 if( $query_file && (&cpi_file::read_file($query_file,"") ne $request) );

    print STDERR "rf=$result_file qf=$query_file regen=$regen.\n";
    system("mv $query_file $query_file.old.$$") if( $regen );

    my $contents;
    if( $regen )
	{
	print STDERR "About to call dirname($result_file).\n";
	system("mkdir -p $_") if( ! -d ($_=&cpi_filename::dirname($result_file)) );
	print STDERR "Done dirname($result_file).\n";
	if( $argp->{pipe} )
	    { $contents = &cpi_file::read_file($argp->{pipe}); }
	elsif( $argp->{routine} )
	    { $contents = &{ $argp->{routine} }; }
        elsif( $argp->{eval_string} )
	    { $contents = eval($argp->{eval_string}); }
	elsif( $argp->{http} )
	    { $contents = &cpi_magic_http::magic_http( $argp ); }
	if( defined($_=$argp->{check}) && $contents !~ /$_/ )
	    {
	    &cpi_file::write_file("$query_file.failed.$$",$request) if( $query_file );
	    return undef;
	    }
	$contents = encode_base64( $contents ) if( $result_file =~ /\.b64$/ );
	&cpi_file::write_file($result_file,$contents);
	#print "Contents(", length($contents), ") written to $result_file.\n";
	&cpi_file::write_file($query_file,$request) if( $query_file );
	}

    if( ! $argp->{return} )
	{ return $contents || &cpi_file::read_file($result_file); }
    elsif( $argp->{return} eq "result_file" )
	{ return $result_file; }
    elsif( $argp->{return} eq "contents" )
	{ return $contents || &cpi_file::read_file($result_file); }
    else
	{ &cpi_file::fatal("cache cannot return ".$argp->{return}); }
    }

1;
