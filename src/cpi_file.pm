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

package cpi_file;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw();
use lib ".";

use cpi_log;
use cpi_vars;
#__END__
1;

#########################################################################
#       Return contents of entire file specified in arguments.          #
#########################################################################
sub read_file
    {
    my( $fname, $ret ) = @_;
    &fatal("read_file called with no filename.") if( ! defined($fname) );
    if( open( INF, $fname ) )
	{
	binmode INF;
	$ret = join("",<INF>);
	close( INF );
	}
    elsif( ! defined($ret) )
	{ &fatal("Cannot read_file($fname):  $!"); }
    return $ret;
    }

sub slurp_file { return &read_file(@_); }	# Backward compatibility

#########################################################################
#	Parse a file into lines removing trailing spacing and comments	#
#########################################################################
sub read_lines
    {
    my @ret;
    foreach my $ln ( split(/\n/,&read_file( @_ ) ) )
        {
	chomp( $ln );
	$ln =~ s/#.*//;
	$ln =~ s/\s+$//;
	push( @ret, $ln ) if( $ln ne "" );
	}
    return @ret;
    }


#########################################################################
#       Write entire contents of arguments to specified file.           #
#########################################################################
sub write_file
    {
    my( $fn, $contents ) = @_;

    open( OUT, ">$fn" ) || &fatal("Cannot write $fn:  $!");
    binmode OUT;
    print OUT $contents;
    close( OUT );
    }

#########################################################################
#	Change mode, uid and gid of files.				#
#########################################################################
sub chmog
    {
    my( $mode, $uid, $gid, @files ) = @_;
    chmod( $mode, @files ) ||
	&fatal("chmod($mode,".join(",",@files).") failed:  $!");
    chown( $uid, $gid, @files ) ||
	&fatal("chown($uid,$gid,".join(",",@files).") failed:  $!");
    return 0;
    }

#########################################################################
#	Create all directories necessary to create specified directory.	#
#	Similar to "mkdir -p".						#
#	NOTE:  The mask comes first since it can handle multiple dirs.	#
#########################################################################
sub mkdirp
    {
    my( $mask, @filenames ) = @_;
    foreach my $dn ( @filenames )
	{
	my( $sofar ) = "";
	$sofar = "." if( $dn =~ m+^[^/]+ );
	foreach $_ ( split(/\//,$dn) )
	    {
	    next if( $_ eq "" );
	    $sofar .= "/$_";
	    mkdir($sofar,$mask) || &fatal("Cannot create $sofar:  $!")
	        if( ! -d $sofar );
	    }
	}
    return 1;
    }


#########################################################################
#	Return a list of filenames in the specified directory that	#
#	match the supplied regular expression.  If no regular		#
#	expression is supplied, return only non-hidden files (files	#
#	that don't start with a ".").					#
#########################################################################
sub files_in
    {
    my( $dname, $pat ) = @_;
    opendir(D,$dname) || &fatal("Cannot opendir($dname):  $!");
    $pat = "^[^\\.]" if( ! defined($pat) );
    my( @ret ) = grep( /$pat/, readdir( D ) );
    closedir( D );
    return @ret;
    }

#########################################################################
#	Return a new temp file name.					%
#########################################################################
my $tempfileind = 0;
sub tempfile
    {
    my( $suffix ) = @_;
    if( ! $cpi_vars::TEMP_DIR )
        {
	$cpi_vars::TEMP_DIR = "/tmp/$cpi_vars::PROG-$$/";
	mkdir( $cpi_vars::TEMP_DIR, 0700 );
	}
    return sprintf("%s%d%s",
        $cpi_vars::TEMP_DIR,
	$tempfileind++,
	(defined($suffix)?$suffix:"")
	);
    }

#########################################################################
#	Add to the list of things to call when we're shutting down.	#
#########################################################################
my @cleanups;
my $in_cleanup = 0;
sub register_cleanup
    {
    push( @cleanups, @_ );
    }

#########################################################################
#	Cleanup by saving phrases and exiting.				#
#########################################################################
sub cleanup
    {
    my( $excode ) = @_;
    grep( &{$_}(), @cleanups ) if( ! $in_cleanup++ );
    system("rm -rf $cpi_vars::TEMP_DIR") if( $cpi_vars::TEMP_DIR );
    exit($excode);
    }

#########################################################################
#	Print a command and then execute it.				#
#########################################################################
sub echodo
    {
    my( $cmd ) = @_;
    if( $ENV{SCRIPT_NAME} )
	{ print "<pre>+ $cmd</pre>\n"; }
    else
        { print "+ $cmd\n"; }
    return system( $cmd );
    }

#########################################################################
#	Print out a list of error messages and then exit.		#
#		Note that due to the low level last resort nature	#
#		of this code, some CGI stuff is here rather than in	#
#		the CGI module.  CGI lib wants to be able to call fatal	#
#		so fatal should not call CGI lib.			#
#########################################################################
sub fatal
    {
    my( $msg, $do_trace ) = @_;
    $do_trace = 1 if( !defined($do_trace) || $msg eq "" );

    print "Content-type:  text/html; charset=\"utf-8\"\n\n"
	if( $ENV{SCRIPT_NAME} && ! $cpi_vars::CGIheader_has_been_printed );

    if( !defined($cpi_vars::THIS) || $cpi_vars::THIS eq "" )
        { print( $msg, "\n" ); }
    else
        {
	print(
	    "<h2>Fatal error:</h2><dd><font style='background-color:black;color:red'>$msg</font>\n" );
	}
    if( $do_trace )
	{
	print("<hr>") if( $ENV{SCRIPT_NAME} );
	my $i = 0;
	my($pack,$file,$line,$subname,$hasargs,$wantarray);
	while( ($pack,$file,$line,$subname,$hasargs,$wantarray) = caller($i++) )
	    {
	    if( $ENV{SCRIPT_NAME} )
	        { print("<li>${file}:$line $subname\n"); }
	    else
		{ print STDOUT "    ${file}:$line $subname\n"; }
	    }
	}
    &cpi_log::log( ($cpi_vars::REALUSER||"?") ."(". ($cpi_vars::SID||"?") . ")"
	. " had fatal error:  $msg");
    &cleanup(1);
    }
1;
