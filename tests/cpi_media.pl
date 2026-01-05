#!/usr/bin/perl -w

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( fatal read_file cleanup tempfile );
use cpi_arguments qw( parse_arguments );
use cpi_media qw( player media_info );
use cpi_vars;

our @files;
our %ARGS;
our @problems;

sub usage
    {
    &fatal( @_, "Usage:  $cpi_vars::PROG <argument>",
	"Where <argument> is:",
	"	<file>"
	);
    }

%ARGS = &parse_arguments( {
    flags		=> [ "information" ],
    non_switches	=> \@files,
    switches=>
	{
	"verbosity"	=> 0,
	"btop"		=> "",
	"bleft"		=> "",
	"bright"	=> "",
	"bbottom"	=> "",
	"bwidth"	=> "",
	"bheight"	=> "",
	"geometry"	=> ""
	} } );

$cpi_vars::VERBOSITY = $ARGS{verbosity};

if( $ARGS{"information"} )
    {
    my $infop = &media_info( $files[0] );
    foreach my $k ( sort keys %{$infop} )
	{
	printf("%-20s%s\n",${k}.":",$infop->{$k});
	}
    }
else
    {
    my %args;
    foreach my $dim ( "top", "bottom", "left", "right", "width", "height" )
        { $args{$dim} = $ARGS{"b$dim"} if( $ARGS{"b$dim"} ); }
    &player( \%args, @files );
    }

&cleanup( 0 );
