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

package cpi_file;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( chmog cleanup echodo fatal autopsy death_requested
 files_in fqfiles_in mkdirp read_file read_lines register_cleanup slurp_file
 tempfile write_file write_lines append_file first_in_path new_stderr
 undf);
use lib ".";

use cpi_log qw( log );
use cpi_vars;
use Devel::StackTrace;
#__END__
1;

#########################################################################
#	Really helpful for printing variables that might not be		#
#	defined.  In this module because this is the most commonly	#
#	included module and it really doesn't seem to be owned by	#
#	a concept held by another module.  Dept of miscellaneous.	#
#########################################################################
sub undf
    {
    return ( defined($_[0]) ? $_[0] : defined($_[1]) ? $_[1] : "undef" );
    }

#########################################################################
#       Return contents of entire file specified in arguments.          #
#########################################################################
sub read_file
    {
    my( $fname, $ret ) = @_;
    &autopsy("read_file called with no filename.") if( ! defined($fname) );
    if( open( INF, $fname ) )
	{
	binmode INF;
	$ret = join("",<INF>);
	close( INF );
	}
    elsif( ! defined($ret) )
	{ &autopsy("Cannot read_file($fname):  $!"); }
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
    my( $fn, @contents ) = @_;

    open( OUT, ">$fn" ) || &autopsy("Cannot write $fn:  $!");
    binmode OUT;
    print OUT @contents;
    close( OUT );
    }

#########################################################################
#	Bunch lines separated by newlines.				#
#########################################################################
sub write_lines
    {
    my( $filename, @lines ) = @_;
    return &write_file( $filename, map{$_,"\n"} @lines );
    }

#########################################################################
#       Write entire contents of arguments to specified file.           #
#########################################################################
sub append_file
    {
    my( $fn, @contents ) = @_;

    open( OUT, ">>$fn" ) || &autopsy("Cannot append to $fn:  $!");
    binmode OUT;
    print OUT @contents;
    close( OUT );
    }

#########################################################################
#	Change mode, uid and gid of files.				#
#########################################################################
sub chmog
    {
    my( $mode, $uid, $gid, @files ) = @_;
    chmod( $mode, @files ) ||
	&autopsy("chmod($mode,".join(",",@files).") failed:  $!");
    chown( $uid, $gid, @files ) ||
	&autopsy("chown($uid,$gid,".join(",",@files).") failed:  $!");
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
	    mkdir($sofar,$mask) || &autopsy("Cannot create $sofar:  $!")
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
    opendir(D,$dname) || &autopsy("Cannot opendir($dname):  $!");
    $pat = "^[^\\.]" if( ! defined($pat) );
    my( @ret ) = grep( /$pat/, readdir( D ) );
    closedir( D );
    return @ret;
    }

#########################################################################
#	Like files_in but return something that can be used by open	#
#	or unlink.							#
#########################################################################
sub fqfiles_in
    {
    my( $dname, $path ) = @_;
    my @ret = &files_in( $dname, $path );
    return @ret if( $dname eq "." );
    return map{"${dname}/$_"} @ret;
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
    if( $cpi_vars::VERBOSITY )
	{
	if( $ENV{SCRIPT_NAME} )
	    { print "<pre>+ $cmd</pre>\n"; }
	else
	    { print "+ $cmd\n"; }
	}
    return system( $cmd );
    }

#########################################################################
#	Print out a list of error messages and then exit.		#
#		Note that due to the low level last resort nature	#
#		of this code, some CGI stuff is here rather than in	#
#		the CGI module.  CGI lib wants to be able to call	#
#		death_requested	so death_requested should not call CGI	#
#		lib.							#
#########################################################################
sub death_requested
    {
    my( $argp, @msgs ) = @_;

    print "Content-type:  text/html; charset=\"utf-8\"\n\n"
	if( $ENV{SCRIPT_NAME} && ! $cpi_vars::CGIheader_has_been_printed );

    if( ! $ENV{SCRIPT_NAME} )
	{ print STDERR join("\n",@msgs,""); }
    else
        {
	print "<h2>Fatal error(s):</h2>\n",
	    (
	    map { "<dd><font style='background-color:black;color:red'>$_</font></dd>\n" }
		@msgs
	    );
	}
    if( $argp->{trace} )
	{
	print("<hr>") if( $ENV{SCRIPT_NAME} );
#	my $i = 0;
#	my($pack,$file,$line,$subname,$hasargs,$wantarray);
#	while( ($pack,$file,$line,$subname,$hasargs,$wantarray) = caller($i++) )
#	   {
#	    if( $ENV{SCRIPT_NAME} )
#	        { print("<li>${file}:$line $subname\n"); }
#	    else
#		{ print STDOUT "    ${file}:$line $subname\n"; }
#	    } 
	my $trace_obj = Devel::StackTrace->new();
	foreach my $ln ( split(/\n/,$trace_obj->as_string) )
	    {
	    print "\n", ( $ENV{SCRIPT_NAME} ? "<li>$ln" : "\t$ln" );
	    }
	print "\n";
	}
    if( $argp->{log} )
	{
	foreach my $msg ( @msgs )
	    {
	    &log( ($cpi_vars::REALUSER||"?") ."(". ($cpi_vars::SID||"?") . ")"
		. " had fatal error:  $msg");
	    }
	}
    &cleanup(1);
    }

sub fatal	{ &death_requested( {trace=>0,log=>1}, @_ ); }
sub autopsy	{ &death_requested( {trace=>1,log=>1}, @_ ); }

#########################################################################
#	Return the full path for the first prog in argument list.	#
#########################################################################
sub first_in_path
    {
    my( @progs ) = @_;
    my @path_dirs = split(/:/,$ENV{PATH});
    foreach my $prog ( @progs )
	{
	my $check = $prog;
	$check =~ s/ .*//g;
	foreach my $dir ( @path_dirs )
	    { return "$dir/$prog" if( -x "$dir/$check" ); }
	}
    return undef;
    }

#########################################################################
#	We're going to open something else on stderr but if that fails	#
#	we'll revert to what was there before.				#
#########################################################################
sub new_stderr
    {
    my( $to_open ) = @_;
    my $ret;
    open( OLD_STDERR, ">&STDERR" )||&fatal("Cannot dup STDERR:  $!");
    close( STDERR );
    if( open( STDERR, $to_open ) )
	{ $ret = 1; }
    else
	{
	$ret = 0;
	my $old_perror = $!;
	open(STDERR,">&OLD_STDERR") || &fatal("Cannot re-dup STDERR:  $!");
	$! = $old_perror;
	}
    close( OLD_STDERR );

    my $old_fh = select(STDERR);
    $| = 1;
    select($old_fh);

    return $ret;
    }
1;
