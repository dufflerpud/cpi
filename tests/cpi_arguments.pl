#!/usr/bin/perl -w
#
#indx#	cpi_arguments.pl - Software for testing argument parser
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
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
#hist#	2026-02-10 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	cpi_arguments.pl - Software for testing argument parser
########################################################################

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
    "-loud",
    "-priority",	22,
    "-mode",		"bob",
    "-even",		2,
    "-odd",		69
    );

print "Args:  [",join(" ",@ARGV),"]\n";
%new_args = &parse_arguments(
    {
    switches	=>
	{
	"mode"	=>	[ "fred", "bob", "ralph" ],
	"priority"	=>	{ min=>0, max=>100 },
	"loud"		=>	{ alias=>["-verbosity=5"] },
	"verbosity"	=>	0,
	"even"		=>	sub { my($s,$v)=@_; return( $v%2 ? "-even requires an even number" : undef ); },
	"odd"		=>	{ re=>"\\d*(1|3|5|7|9)" }
	}
    });
print join("\n\t","New args:",
    ( map { "$_=$new_args{$_}" } sort keys %new_args ) ), "\n";
print "non_switches: [",join(",",@{$new_args{non_switches}}),"]\n"
    if( $new_args{non_switches} );

@ARGV =
    (
    "-t",	"fr"
    );

print "Args:  [",join(" ",@ARGV),"]\n";
%new_args = &parse_arguments({
    switches	=>
	{
	"type"	=>	{ oneof=> ["france", "fireball", "ralph" ] }
	}
    } );
print join("\n\t","New args:",
    ( map { "$_=$new_args{$_}" } sort keys %new_args ) ), "\n";

exit(0);
