#!/usr/local/bin/perl -w

use strict;

use lib "/usr/local/lib/perl";

use cpi_vars;
use cpi_file qw( fatal read_file write_file );
use cpi_arguments qw( parse_arguments );

# Put constants here

my $TMP = "/tmp/$cpi_vars::PROG";

our %ONLY_ONE_DEFAULTS =
    (
    "i"	=>	"",
    "o"	=>	"",
    "d"	=>	"/usr/local/lib/perl",
    "D"	=>	"",
    "v"	=>	"",
    "m"	=>	"",
    "e"	=>	0,
    "h"	=>	"fix_common.hdr"
    );

# Put variables here.

our %ARGS;
our @files;
our @problems;
our @warnings;
my $exit_stat = 0;

my $makefile_string;

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "",
	"Usage:  $cpi_vars::PROG <possible arguments>","",
	"where <possible arguments> are:",
	"    -d <old modules directory>",
	"    -i <input file>",
	"    -o <output file>",
	"    -D <new modules directory>"
	);
    }

#########################################################################
#	Read in all of the modules looking for subs and variables	#
#########################################################################
my @OTYPES = ( "\&", "\@", "\%", "\$" );
sub dump
    {
    my( $outname, $modulesp, $found_inp ) = @_;
    open( OUT, "> $outname" ) || &fatal("Cannot write ${outname}:  $!");
    print OUT "Modules:\n";
    foreach my $module_name ( sort keys %{$modulesp} )
        {
	my $mp = $modulesp->{$module_name};
	print OUT "\t", $module_name, "\n";
	foreach my $otype ( @OTYPES )
	    {
	    printf OUT ("  %-5 %s\n",$otype.":",join(",",@{$mp->{$otype}}))
	        if( $mp->{$otype} );
	    }
	}
    foreach my $otype ( @OTYPES )
        {
	next if( ! $found_inp->{$otype} );
	print OUT $otype, ":\n";
	foreach my $vname ( sort keys %{$found_inp->{$otype}} )
	    {
	    printf OUT ("  %-30s %s\n",
	        $vname.":",
		join(",",@{$found_inp->{$otype}{$vname}}) );
	    }
	}
    close( OUT );
    }

#########################################################################
#	Check if any errors have accumulated				#
#########################################################################
sub check_errors
    {
    if( @problems )
	{
	if( ! @warnings )
	    { &fatal( join("\n  ","Fatal error, giving up:", @problems ) ); }
	else
	    {
	    &fatal(
		join("\n  ","Warnings:", @warnings),
		join("\n  ","Fatal errors:", @problems ) );
	    }
	}
    elsif( @warnings )
	{
	if( $ARGS{e} )
	    { &fatal(join("\n  ","Warnings (now considered fatal):", @warnings)); }
	else
	    { print join("\n  ","Warnings:",@warnings), "\n"; }
	@warnings = ();
	}
    }

#########################################################################
#	Read all modules in directory and return hash pointers to their	#
#	symbols.							#
#########################################################################
sub read_module_dir
    {
    my( $dir_name ) = @_;
    my $prefix = ( $dir_name eq "./" ? "" : $dir_name."/" );
    my %modules;
    my %found_in;

    opendir( D, $dir_name ) || &fatal("Cannot opendir($dir_name):  $!");
    foreach my $filename ( readdir(D) )
        {
	next if( $filename !~ /^(cpi_[^\.]*)\.pm$/ );
	my $mp = { name=>$1, file=>$prefix.$filename };
	$modules{$mp->{name}} = $mp;

	my $contents = &read_file($mp->{file});

	my %my_subs;
	foreach my $pc ( split(/\b(sub\s+\w+)\b/, $contents ) )
	    {
	    next if( $pc !~ /^sub\s+([\w]+)$/ );
	    $my_subs{$1}++;
	    push( @{$found_in{"&"}{$1}}, $mp->{name} );
	    }
	#@{$mp->{"&"}} = sort keys %my_subs;

	foreach my $scope ( "my", "our" )
	    {
	    foreach my $pc ( split(/\n($scope\s+[@\%\$]\w+)\b/, $contents ) )
		{
		#print "FOUND [$pc] in $filename.\n" if( $pc =~ /COMMONDIR/ );
		next if( $pc !~ /^$scope ([@\%\$])(\w+)/ );
		next if( grep($_ eq $2, "ISA", "EXPORT", "EXPORT_OK" ) );
		#push( @{$mp->{$1}}, { scope=>$1, type=>$2, name=>$3 } );
		push( @problems,
		    "$mp->{name} ${1}${2} conflicts with ".$found_in{$1}{$2}."." )
		    if( $found_in{$1}{2} );
		push( @{$found_in{$1}{$2}}, $mp->{name} );
		}
	    }
	}
    closedir( D );

    foreach my $otype ( @OTYPES )
	{
	foreach my $sym ( keys %{$found_in{$otype}} )
	    {
	    push( @warnings,
		"$otype$sym found in: " .
		join(",",@{$found_in{$otype}{$sym}}). "." )
		if( scalar( @{ $found_in{$otype}{$sym} } ) != 1 );
	    }
	}

    &check_errors();

    return ( \%modules, \%found_in );
    }

#########################################################################
#	Translate one file (either module or source)			#
#########################################################################
my $header_contents;
sub one_file
    {
    my( $old_file, $new_file, $modulesp, $found_inp, $module_name ) = @_;

    $new_file = $old_file if( ! defined($new_file) );
    my @changes;
    my $contents;
    if( ! $module_name )
	{ $contents = ""; }
    else
    	{
	$header_contents ||= &read_file( $ARGS{h} );
	$contents = $header_contents;
	$contents =~ s/PACKAGE/$module_name/g;
	}
    $contents .= &read_file( $old_file );
    my $modsrc = join("|",(map{$_."::"} keys %{$modulesp}),"COMMON::","");
    my %used;
    #foreach my $otype ( $ARGS{i} ? ('&') : @OTYPES )
    foreach my $otype ( @OTYPES )
	{
	foreach my $sym ( keys %{$found_inp->{$otype}} )
	    {
	    my $located_in = $found_inp->{$otype}{$sym}[0];
	    #next if( $located_in eq $module_name );

	    my $old_contents = $contents;
	    my $search_to =
		( ($module_name && $module_name eq $located_in)
		? $otype.$sym
		: $otype eq '&'
		? $otype.$sym
		: $otype.${located_in}."::".$sym );
	    my $search_from = "\\$otype($modsrc)$sym\\b";
	    $contents =~ s/$search_from/$search_to/gms;
	    if( $contents ne $old_contents )
	        {
		push( @changes, $search_to );
		$used{ $located_in }{ $sym }++ if( $otype eq '&' );
		}

	    if( $otype eq '%' || $otype eq '@' )
		{
		my $old_contents = $contents;
		my $search_to =
		    ( ($module_name && $module_name eq $located_in)
		    ? '$'.$sym
		    : '$'.${located_in}."::".$sym );
		my $search_from = "\\\$($modsrc)$sym\\b";
		$contents =~ s/$search_from/$search_to/gms;
		if( $contents ne $old_contents )
		    {
		    push( @changes, $search_to );
		    $used{ $located_in }{ $sym }++ if( $otype eq '&' );
		    }
		}
	    }
	}

    my @use_strings;
    foreach my $u ( keys %used )
	{
	push( @use_strings, "use $u qw("
	    . join(" ",sort keys %{$used{$u}})
	    . ");" );
	}
    $makefile_string .= join("\\\n\t","auto/$module_name/autosplit.ix:",
        ( map{"auto/$_/autosplit.ix"} sort keys %used ) )."\n".
	"\tperl $module_name.pm\n".
	"\t[ -d auto/$module_name ] || mkdir -p auto/$module_name\n".
	"\tmv $module_name.pm $module_name.compiling\n".
	"\tsed -e 's/^#*__END__/__END__/' < $module_name.compiling > $module_name.pm\n".
	"\tperl -MAutoSplit -e 'autosplit($module_name,auto,0,1,1)' || excode=$?\n".
	"\tmv $module_name.compiling $module_name.pm\n"
	if( $ARGS{m} );

    $contents =~ s/^use cpi_.*?\n//gms;
    $contents =~ s/^use COMMON.*?\n//ms;
    $contents =~ s/^my %ARGS;/our %ARGS;/ms;
    $contents =~ s/^my @files;/our @files;/ms;
    $contents =~ s/^my @problems;/our @problems;/ms;
    $contents =~ s/^my %ONLY_ONE_DEFAULTS/our %ONLY_ONE_DEFAULTS/ms;
    my $use_string = join("\n",@use_strings);
    $contents =~ s/use strict;/use strict;\nuse lib "$ARGS{d}";\n/ms
	if( $contents !~ m:$ARGS{d}: );
    $contents =~ s/(.*\nuse [^\n]*)$/$1\n$use_string\n/ms;

    &write_file( $new_file, $contents );
    print "$new_file contains: ",join(" ",@changes),"\n";
    }

#########################################################################
#	Fix up references in all the modules.				#
#########################################################################
sub write_module_dir
    {
    my( $outdir, $modulesp, $found_inp ) = @_;
    
    if( $ARGS{m} )
        {
	$makefile_string = join("\\\n\t","all_modules:",
	    ( map{"auto/$_/autosplit.ix"} keys %{$modulesp} ) ) . "\n";
	}
    foreach my $module_name ( sort keys %{$modulesp} )
        {
	my $mp = $modulesp->{$module_name};
	my $old_file = $mp->{file};
	my $new_file = "$outdir/$module_name.pm";
	$new_file .= ".new" if( -e $new_file );
	&one_file( $old_file, $new_file, $modulesp, $found_inp, $module_name );
	}
    &write_file( $ARGS{m}, $makefile_string ) if( $ARGS{m} );
    }

#########################################################################
#	Main								#
#########################################################################

if( 0 && $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    { %ARGS = &parse_arguments( {switches=>\%ONLY_ONE_DEFAULTS} ); }

my($modulesp,$found_inp) = &read_module_dir( $ARGS{d} );

if( $ARGS{i} eq "" && $ARGS{D} eq "" )
    {
    $ARGS{o} = "/dev/stdout" if( $ARGS{o} eq "" );
    &dump( $ARGS{o}, $modulesp, $found_inp );
    }

&one_file( $ARGS{i}, $ARGS{o}, $modulesp, $found_inp  )
    if( $ARGS{i} );

&write_module_dir( $ARGS{D}, $modulesp, $found_inp )
    if( $ARGS{D} );

exec("rm -rf $TMP");
