#!/usr/bin/perl -w

use strict;

use lib "/usr/local/lib/perl";
use cpi_mime qw( read_mime_types );
use cpi_file qw( fatal cleanup );
use cpi_arguments qw( parse_arguments );
use cpi_english qw( nword );
use cpi_vars;

use Data::Dumper;

our %ARGS;
our @problems;
our @to_lookup;

sub usage
    {
    &fatal( @_, "", "Usage:  $cpi_vars::PROG <argument>",
	"  Where <argument> is:",
	"\t-ext_to_mime <ext>",
	"\t-ext_to_type <ext>",
	"\t-mime_to_exts <mime>",
	"\t-mime_to_type <mime>",
	"\t-ext <ext>",
	"\t-mime <mime>",
	"\t-type <type>");
    }

%ARGS = &parse_arguments( {
    flags			=> ["extensions","mime_types","types"],
    non_switches		=> \@to_lookup,
    switches=>
	{
	"ext_to_mime"		=> "",
	"em"			=> { alias=>["-ext_to_mime"] },
	"ext_to_type"		=> "",
	"et"			=> { alias=>["-ext_to_type"] },
	"mime_to_exts"		=> "",
	"me"			=> { alias=>["-mime_to_exts"] },
	"mime_to_type"		=> "",
	"mt"			=> { alias=>["-mime_to_type"] },
	"ext"			=> "",
	"mime"			=> "",
	"type"			=> "",
	} } );

#print "ARGS=((",Dumper(\%ARGS),"))\n";

&read_mime_types();

#print "EXT_TO_MIME_TYPE=((", Dumper(\%cpi_vars::EXT_TO_MIME_TYPE), "))\n";
#print "EXT_TO_BASE_TYPE=((", Dumper(\%cpi_vars::EXT_TO_BASE_TYPE), "))\n";
#print "MIME_TYPE_TO_EXTS=((", Dumper(\%cpi_vars::MIME_TYPE_TO_EXTS), "))\n";
#print "MIME_TYPE_TO_BASE_TYPE=((", Dumper(\%cpi_vars::MIME_TYPE_TO_BASE_TYPE), "))\n";

($_=$ARGS{ext_to_mime}) &&
    print $cpi_vars::EXT_TO_MIME_TYPE{$_}||"?", "\n";
($_=$ARGS{ext_to_type}) &&
    print $cpi_vars::EXT_TO_BASE_TYPE{$_}||"?", "\n";
($_=$ARGS{mime_to_exts}) &&
    print "",
        ( $cpi_vars::MIME_TYPE_TO_EXTS{$_}
	? join(",",sort keys %{$cpi_vars::MIME_TYPE_TO_EXTS{$_}})
	: "?" ), "\n";
($_=$ARGS{mime_to_type}) &&
    print $cpi_vars::MIME_TYPE_TO_BASE_TYPE{$_}||"?", "\n";
$ARGS{extensions} &&
    print $_,"\n" foreach sort keys %cpi_vars::EXT_TO_MIME_TYPE;
$ARGS{mime_types} &&
    print $_,"\n" foreach sort keys %cpi_vars::MIME_TYPE_TO_EXTS;
$ARGS{types} &&
    print $_,"\n" foreach sort keys %cpi_vars::BASE_TYPE_TO_EXTS;

foreach my $l ( @to_lookup )
    {
    my $matches = 0;
    foreach my $e ( sort keys %cpi_vars::EXT_TO_MIME_TYPE )
        {
	if( $l eq $e
	 || $l eq ($cpi_vars::EXT_TO_MIME_TYPE{$e}||"")
	 || $l eq ($cpi_vars::EXT_TO_BASE_TYPE{$e}||"") )
	    {
	    printf("%-5s %-30s %s\n","Ext","Type","Mime")
	        if( ++$matches == 0 );
	    printf("%-5s %-30s %s\n",
	        $e,
		$cpi_vars::EXT_TO_MIME_TYPE{$e}||"?",
		$cpi_vars::EXT_TO_BASE_TYPE{$e}||"?" );
	    }
	}
    print &nword($matches,"match"), " for \"$l\" found.\n";
    }
&cleanup(0);
