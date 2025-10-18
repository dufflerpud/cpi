#!/usr/bin/perl -w

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( fatal );
use cpi_arguments qw( parse_arguments );

our %ONLY_ONE_DEFAULTS =
    (
    "v"	=> 0,
    "color"	=>	"blue",
    "i"	=> "/dev/stdin",
    "o"	=> "/dev/stdout"
    );

my @flags = ("b","flag");

our @files;
our %ARGS;

sub usage
    {
    &fatal(join("\t\n","This is a usage message:",@_));
    }

@ARGV =
    (
    "-v",		"2",
    "-color",		"red",
    "-i/dev/myin",
    "-o=/dev/myout",
    "fred",
    "and",
    "bob"
    );

print "Args:  [",join(" ",@ARGV),"]\n";
&parse_arguments();

print join("\n\t","Old args:",
    ( map { "$_=$ARGS{$_}" } sort keys %ARGS ) ), "\n";
print "files=[",join(",",@files),"]\n\n";

@ARGV =
    (
    "-v",		"2",
    "-color",		"red",
    "-flag",
    "-b",
    "-i/dev/myin",
    "-o=/dev/myout",
    "fred",
    "and",
    "bob"
    );

print "Args:  [",join(" ",@ARGV),"]\n";
my %new_args = &parse_arguments({
    "switches"		=> \%ONLY_ONE_DEFAULTS,
    "flags"		=> \@flags,
    "non_switches"	=> []
    });
print join("\n\t","New args:",
    ( map { "$_=$new_args{$_}" } sort keys %new_args ) ), "\n";
print "non_switches: [",join(",",@{$new_args{non_switches}}),"]\n";

@ARGV =
    (
    "-verb5",
    "-priority",	22,
    "-mode",		"bob"
    );

print "Args:  [",join(" ",@ARGV),"]\n";
%new_args = &parse_arguments(
    {
    switches	=>
	{
	"mode"	=>	[ "fred", "bob", "ralph" ],
	"priority"	=>	{ min=>0, max=>100 },
	"verbosity"	=>	0
	}
    });
print join("\n\t","New args:",
    ( map { "$_=$new_args{$_}" } sort keys %new_args ) ), "\n";
print "non_switches: [",join(",",@{$new_args{non_switches}}),"]\n"
    if( $new_args{non_switches} );


exit(0);
