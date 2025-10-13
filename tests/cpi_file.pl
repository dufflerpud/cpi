#!/usr/bin/perl -w

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( autopsy fatal );

our %ONLY_ONE_DEFAULT =
    (
    "v"	=> 0,
    "i"	=> "/dev/stdin",
    "o"	=> "/dev/stdout"
    );

sub usage
    {
    &fatal(join("\t\n","This is a usage message:",@_));
    }

&autopsy("This is a bad thing.  I'm dying now.");
