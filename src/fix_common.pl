#!/usr/local/bin/perl -w

use strict;

# Put constants here

my $PROJECT = "replace_with_real_name";
my $PROG = ( $_ = $0, s+.*/++, s/\.[^\.]*$//, $_ );
my $TMP = "/tmp/$PROG.$$";
#my $TMP = "/tmp/$PROG";

my $BASEDIR = "%%PROJECTDIR%%";
$BASEDIR = "/usr/local/projects/$PROG" if( ! -d $BASEDIR );

my %ONLY_ONE_DEFAULTS =
    (
    "i"	=>	"",
    "o"	=>	"",
    "d"	=>	".",
    "D"	=>	"",
    "v"	=>	"",
    "m"	=>	"",
    "h"	=>	"fix_common.hdr"
    );

# Put variables here.

my @problems;
my %ARGS;
my @files;
my $exit_stat = 0;

my $makefile_string;

# Put interesting subroutines here

#=======================================================================#
#	Verbatim from prototype.pl					#
#=======================================================================#

#########################################################################
#	Print a header if need be.					#
#########################################################################
my $hdrcount = 0;
sub CGIheader
    {
    print "Content-type:  text/html\n\n" if( $hdrcount++ == 0 );
    }

#########################################################################
#	Print out a list of error messages and then exit.		#
#########################################################################
sub fatal
    {
    if( $ENV{SCRIPT_NAME} )
        {
	&CGIheader();
	print "<h2>Fatal error:</h2>\n",
	    map { "<dd><font color=red>$_</font>\n" } @_;
	}
    print STDERR join("\n",@_,"");
    exit(1);
    }


#########################################################################
#	Put <form> information into %FORM (from STDIN or ENV).		#
#########################################################################
my %FORM;
sub CGIreceive
    {
    my ( $name, $value );
    my ( @fields, @ignorefields, @requirefields );
    my ( @parts );
    my $incoming = "";
    return if ! defined( $ENV{'REQUEST_METHOD'} );
    if ($ENV{'REQUEST_METHOD'} eq "POST")
	{ read(STDIN, $incoming, $ENV{'CONTENT_LENGTH'}); }
    else
	{ $incoming = $ENV{'QUERY_STRING'}; }
    
    if( defined($ENV{"CONTENT_TYPE"}) &&
        $ENV{"CONTENT_TYPE"} =~ m#^multipart/form-data# )
	{
	my $bnd = $ENV{"CONTENT_TYPE"};
	$bnd =~ s/.*boundary=//;
	foreach $_ ( split(/--$bnd/s,$incoming) )
	    {
	    if( /^[\r\n]*[^\r\n]* name="([^"]*)"[^\r\n]*\r*\nContent-[^\r\n]*\r*\n\r*\n(.*)[\r]\n/s )
		{
		#### Skip generally blank fields
		next if ($2 eq "");

		#### Allow for multiple values of a single name
		$FORM{$1} .= "," if ($FORM{$1} ne "");

		$FORM{$1} .= $2;

		#### Add to ordered list if not on list already
		push (@fields, $1) unless (grep(/^$1$/, @fields));
		}
	    elsif( /^[\r\n]*[^\r\n]* name="([^"]*)"[^\r\n]*\r*\n\r*\n(.*)[\r]\n/s )
		{
		#### Skip generally blank fields
		next if ($2 eq "");

		#### Allow for multiple values of a single name
		$FORM{$1} .= "," if (defined($FORM{$1}) && $FORM{$1} ne "");

		$FORM{$1} .= $2;

		#### Add to ordered list if not on list already
		push (@fields, $1) unless (grep(/^$1$/, @fields));
		}
	    }
	}
    else
	{
	foreach ( split(/&/, $incoming) )
	    {
	    ($name, $value) = split(/=/, $_);

	    $name  =~ tr/+/ /;
	    $value =~ tr/+/ /;
	    $name  =~ s/%([A-F0-9][A-F0-9])/pack("C", hex($1))/gie;
	    $value =~ s/%([A-F0-9][A-F0-9])/pack("C", hex($1))/gie;

	    #### Strip out semicolons unless for special character
	    $value =~ s/;/$$/g;
	    $value =~ s/&(\S{1,6})$$/&$1;/g;
	    $value =~ s/$$/ /g;

	    #$value =~ s/\|/ /g;
	    $value =~ s/^!/ /g; ## Allow exclamation points in sentences

	    #### Split apart any directive prefixes
	    #### NOTE: colons are reserved to delimit these prefixes
	    @parts = split(/:/, $name);
	    $name = $parts[$#parts];
	    if (grep(/^require$/, @parts))
		{
		push (@requirefields, $name);
		}
	    if (grep(/^ignore$/, @parts))
		{
		push (@ignorefields, $name);
		}
	    if (grep(/^dynamic$/, @parts))
		{
		#### For simulating a checkbox
		#### It may be dynamic, but useless if nothing entered
		next if ($value eq "");
		$name = $value;
		$value = "on";
		}

	    #### Skip generally blank fields
	    next if ($value eq "");

	    #### Allow for multiple values of a single name
	    $FORM{$name} .= "," if( defined($FORM{$name}) && $FORM{$name} ne "");
	    $FORM{$name} .= $value;

	    #### Add to ordered list if not on list already
	    push (@fields, $name) unless (grep(/^$name$/, @fields));
	    }
	}
    }

#########################################################################
#	Print a command and then execute it.				#
#########################################################################
sub echodo
    {
    my $cmd = join(" ",@_);
    if( ! $ARGS{v} )
	{ }	# No need to print commands
    elsif( $ENV{SCRIPT_NAME} )
	{ print "<pre>+ $cmd</pre>\n"; }
    else
        { print "+ $cmd\n"; }
    return system( $cmd );
    }

#########################################################################
#	Read an entire file and return the contents.			#
#	If open fails and a return value is not specified, fail.	#
#########################################################################
sub read_file
    {
    my( $fname, $ret ) = @_;
    if( open(COM_INF,$fname) )
        {
	$ret = do { local $/; <COM_INF> };
	close( COM_INF );
	}
    elsif( scalar(@_) < 2 )
        { &fatal("Cannot open ${fname}:  $!"); }
    return $ret;
    }

#########################################################################
#	Write an entire file.						#
#########################################################################
sub write_file
    {
    my( $fname, @contents ) = @_;
    open( COM_OUT, "> $fname" ) || &fatal("Cannot write ${fname}:  $!");
    print COM_OUT @contents;
    close( COM_OUT );
    }

#########################################################################
#	Very useful for sorting strings with numbers in them.		#
#		sort { &numcmp($a,$b) } qw( a10 b1 a1 b30 )		#
#	returns				qw( a1 a10 b1 b30 )		#
#########################################################################
sub numcmp
    {
    my( $a, $b ) = @_;
    $a  =~ s/(\d+)/sprintf("%010d",$1)/gie;
    $b  =~ s/(\d+)/sprintf("%010d",$1)/gie;
    return $a cmp $b;
    }

#=======================================================================#
#	New code not from prototype.pl					#
#		Should at least include:				#
#			parse_arguments()				#
#			CGI_arguments()					#
#			usage()						#
#=======================================================================#

#########################################################################
#	Setup arguments if CGI.						#
#########################################################################
sub CGI_arguments
    {
    &CGIreceive();
    }

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "",
	"Usage:  $PROG <possible arguments>","",
	"where <possible arguments> are:",
	"    -d <old modules directory>",
	"    -i <input file>",
	"    -o <output file>",
	"    -D <new modules directory>"
	);
    }

#########################################################################
#	Parse the arguments						#
#########################################################################
sub parse_arguments
    {
    my $arg;
    while( defined($arg = shift(@ARGV) ) )
	{
	# Put better argument parsing here.

	if( $arg =~ /^-(.)(.*)$/ && defined($ONLY_ONE_DEFAULTS{$1}) )
	    {
	    if( defined($ARGS{$1}) )
		{ push( @problems, "-$1 specified multiple times." ); }
	    else
		{ $ARGS{$1} = ( $2 ne "" ? $2 : shift(@ARGV) ); }
	    }
	elsif( $arg =~ /^-(t)(.*)$/ )
	    {
	    my $val = ( $2 ? $2 : shift(@ARGV) );
	    if( $#files <= 0 )
	        {
		if( defined($files[$#files]->{$1}) )
		    {
		    push( @problems,
			$files[$#files]->{name} .
			    " -$1 specified multiple times." );
		    }
		else
		    { $files[$#files]->{$1} = $val; }
		}
	    elsif( defined( $ARGS{$1} ) )
		{ push( @problems, "-$1 specified multiple times." ); }
	    else
		{ $ARGS{$1} = $val; }
	    }
	elsif( $arg =~ /^-.*/ )
	    { push( @problems, "Unknown argument [$arg]" ); }
	else
	    { push( @files, $arg ); }
	}

    #push( @problems, "No files specified" ) if( ! @files );
    &usage( @problems ) if( @problems );

    # Put interesting code here.

    grep( $ARGS{$_}=(defined($ARGS{$_})?$ARGS{$_}:$ONLY_ONE_DEFAULTS{$_}),
	keys %ONLY_ONE_DEFAULTS );
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
	next if( $filename !~ /^([^\.]*)\.pm$/ );
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
	    push( @problems,
		"$otype$sym found in: " .
		join(",",@{$found_in{$otype}{$sym}}). "." )
		if( scalar( @{ $found_in{$otype}{$sym} } ) != 1 );
	    }
	}
    &fatal( @problems ) if( @problems );
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
		: $otype.${located_in}."::".$sym );
	    my $search_from = "\\$otype($modsrc)$sym\\b";
	    $contents =~ s/$search_from/$search_to/gms;
	    if( $contents ne $old_contents )
	        {
		push( @changes, $search_to );
		$used{ $located_in }++;
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
		    $used{ $located_in }++;
		    }
		}
	    }
	}

    my $uses = join( "\n", map {"use $_;"} sort keys %used );
    $makefile_string .= join("\\\n\t","auto/$module_name/autosplit.ix:",
        ( map{"auto/$_/autosplit.ix"} sort keys %used ) )."\n".
	"\tperl $module_name.pm\n".
	"\t[ -d auto/$module_name ] || mkdir -p auto/$module_name\n".
	"\tmv $module_name.pm $module_name.compiling\n".
	"\tsed -e 's/^#*__END__/__END__/' < $module_name.compiling > $module_name.pm\n".
	"\tperl -MAutoSplit -e 'autosplit($module_name,auto,0,1,1)' || excode=$?\n".
	"\tmv $module_name.compiling $module_name.pm\n"
	if( $ARGS{m} );

    $contents =~ s/use COMMON;/$uses/;

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
    { &parse_arguments(); }

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
