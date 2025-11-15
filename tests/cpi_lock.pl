#!/usr/bin/perl -w

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( fatal read_file cleanup );
use cpi_arguments qw( parse_arguments );
use cpi_lock qw( lock_file unlock_file );
use cpi_vars;

our %ARGS;
our @problems;

sub usage
    {
    &fatal( @_, "Usage:  $cpi_vars::PROG <argument>",
	"Where <argument> is:",
	"-lock            Lock the file",
	"-unlock          Unlock the file",
	"-file <file>     Specify file to lock",
        "-debug 0         Turn tracing off",
        "-debug 1         Turn tracing on",
	"-break_stale 0   Hang even with stale locks",
	"-break_stale 1   Break stale locks");
    }

sub test_lock
    {
    &lock_file( @_ );
    system("ls -ld $ARGS{file}*");
    }

sub test_unlock
    {
    &unlock_file( @_ );
    system("ls -ld $ARGS{file}*");
    }

%ARGS = &parse_arguments( {
    switches=>
	{
	"verbosity"	=> 0,
	"file"		=> "test_file",
	"mode"		=> ["wait","lock","unlock"],
	"wait"		=> { alias => [ "-mode", "wait" ] },
	"lock"		=> { alias => [ "-mode", "lock" ] },
	"unlock"	=> { alias => [ "-mode", "unlock" ] },
	"debug"		=> 1,
	"break_stale"	=> 1,
	} } );

$cpi_vars::LOCK_DEBUG		= $ARGS{debug};
$cpi_vars::LOCK_BREAK_STALE	= $ARGS{break_stale};

if( $ARGS{mode} eq "wait" )
    {
    &test_lock( $ARGS{file} );
    print "Hit return when done:  ";
    $_ = <STDIN>;
    &test_unlock( $ARGS{file} );
    }
elsif( $ARGS{mode} eq "lock" )
    { &test_lock( $ARGS{file} ); }
elsif( $ARGS{mode} eq "unlock" )
    { &test_unlock( $ARGS{file} ); }
else
    { &fatal("Mode [$ARGS{mode}] unsupported."); }
