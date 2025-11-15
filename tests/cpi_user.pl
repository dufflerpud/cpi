#!/usr/bin/perl -w

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( fatal cleanup );
use cpi_arguments qw( parse_arguments );
use cpi_reorder qw( orderer );
use cpi_inlist qw( inlist );
use cpi_db qw( dbnew dbwrite dbclose dbread dbget dbput dbadd dbdel dbpop dbisin );
use cpi_hash qw( salted_password );
use cpi_filename qw( text_to_filename );
use cpi_vars;

our @problems;
our %ARGS;

my %STANDARD_GROUPS =
    (
	"administrators"	=> "Administrators",
	"can_csv"		=> "Can generate CSV files",
	"can_e_mail"		=> "Can send E-mail",
	"can_fax"		=> "Can send Faxes",
	"can_file"		=> "Can create files",
	"can_ftp"		=> "Can send via FTP",
	"can_html"		=> "Can generate HTML",
	"can_json"		=> "Can generate JSON",
	"can_pdf"		=> "Can generate PDF files",
	"can_run_transdaemon"	=> "Can run translation daemon",
	"can_sql"		=> "Can generate SQL",
	"can_sql_server"	=> "Can send to SQL_server",
	"can_text"		=> "Can generate text",
	"can_tfs"		=> "Can generate TFS",
	"can_xml"		=> "Can generate XML",
	"create_group"		=> "Can create groups",
	"create_user"		=> "Can create users",
	"user"			=> "User"
    );
my @ADMINISTRATOR_GROUPS = sort keys %STANDARD_GROUPS;
my @USER_GROUPS = "user";

#########################################################################
#	Print a usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_,
	"",
	"Usage:  $cpi_vars::PROG { <argument> }",
	"where <argument> is one or more of:",
	"-list users",
	"-list groups" );
    }

#########################################################################
#	Print out users or groups as a table				#
#########################################################################
sub do_list
    {
    my( $dbname, $class ) = @_;

    &dbread( $dbname );
    my %widths = ( $class => length($class) );
    foreach my $k ( keys %{ $cpi_vars::databases{$dbname} } )
	{
	my( $tbl, $rec, $fld ) = split( $cpi_vars::DBSEP, $k );
	if( ($tbl eq $class) && $rec )
	    {
	    my $l = length($rec);
	    $widths{$class}=$l if( $l > $widths{$class} );
	    $widths{$fld} ||= length($fld);
	    my $v = &dbget( $dbname, $tbl, $rec, $fld );
	    next if( ! defined($v) );
	    $l = length($v);
	    $widths{$fld} = $l if( $l > $widths{$fld} );
	    }
	}

    my @objs = sort grep( &dbget($dbname,$class,$_,"inuse"), &dbget( $dbname, $class ) );
    my @fields = &orderer( { first=>[ $class ], exclude=> ["inuse"] }, keys %widths );
    
    foreach my $f ( @fields )
	{
	printf(
	    ( $f eq $fields[$#fields]
	    ? "%s\n"
	    : "%-$widths{$f}s " ), ucfirst($f) );
	}
    foreach my $rec ( @objs )
	{
	foreach my $f ( @fields )
	    {
	    my $v = $f eq $class ? $rec : &dbget( $dbname, $class, $rec, $f );
	    $v = "?" if( ! defined($v) );
	    $v = join(",",split(/$cpi_vars::DBSEP/,$v));
	    printf(
		( $f eq $fields[$#fields]
		? "%s\n"
		: "%-$widths{$f}s " ), $v );
	    }
	}
    }

#########################################################################
#	Create standard entries for any database (useful for init).	#
#########################################################################
sub setup_account_database
    {
    my( $dbname, $init_flag ) = @_;
    if( $init_flag )
	{
	unlink( $dbname );
        &dbnew( $dbname );
	}
    &dbwrite( $dbname );
    foreach my $group ( keys %STANDARD_GROUPS )
	{
	&dbadd( $dbname, "groups", $group );
	&dbput( $dbname, "groups", $group, "inuse", 1 );
	&dbput( $dbname, "groups", $group, "fullname", $STANDARD_GROUPS{$group} );
	}
    &dbpop( $dbname );
    }

#########################################################################
#	Get rid of a user or group.  Remove stranded records.		#
#########################################################################
sub delete_thing
    {
    my( $dbname, $class, $rec_to_delete ) = @_;
    print STDERR "delete_thing(",join(",",@_),")\n";
    &dbwrite( $dbname );
    if( ! &dbisin($dbname,$class,$rec_to_delete) )
	{ print STDERR "$rec_to_delete is not in $class.\n"; }
    else
	{
	foreach my $k ( keys %{ $cpi_vars::databases{$dbname} } )
	    {
	    my( $tbl, $rec, @fieldnames ) = split(/$cpi_vars::DBSEP/,$k);
	    if( ($tbl eq $class) && $rec && ($rec eq $rec_to_delete) )
		{
		delete( $cpi_vars::databases{$dbname}{$k} );
		print STDERR "Removing [",join(",",split(/$cpi_vars::DBSEP/,$k)),"]\n";
		}
	    }
	print STDERR "$rec_to_delete removed from $class.\n";
	&dbdel( $dbname, $class, $rec_to_delete );

	if( $dbname eq "groups" )
	    {
	    # If we're deleting the group, let's remove the group from all of
	    # the user's grouplists.
	    foreach my $rec ( &dbget($dbname,"users") )
		{
		if( &dbisin( &dbget( $dbname, "users", $rec, "groups", $rec_to_delete ) ) )
		    {
		    print STDERR "Removing $rec_to_delete from $rec groups.\n";
		    &dbdel( $dbname, "users", $rec, "groups", $rec_to_delete );
		    }
		}
	    }
	}
    &dbpop( $dbname );
    }

#########################################################################
#	Specific user based attributes.					#
#########################################################################
sub add_user
    {
    my( $dbname, $thing ) = @_;
    my $class = "users";

    foreach my $fld (
	grep( $ARGS{$_},
	    "password", "email", "fax", "phone", "address", "cardnum", "cardname", "cardexp" ) )
	{ &dbput( $dbname, $class, $thing, $fld, $ARGS{$fld} ); }
    my @groups =
    	( $ARGS{administrator}
	? @ADMINISTRATOR_GROUPS
	: @USER_GROUPS );
    foreach my $group ( @groups )
        { &dbadd( $dbname, $class, $thing, "groups", $group ); }
    if( $ARGS{groups} )
	{
	my $fnc = "+";
	foreach my $groupfnc ( split(/([+\-])/,$ARGS{groups}) )
	    {
	    if( $groupfnc eq "" )
		{}
	    elsif( $groupfnc eq "+" || $groupfnc eq "-" )
		{ $fnc = $groupfnc; }
	    elsif( $fnc eq "+" )
		{
		print "Adding $groupfnc to ${thing}'s groups.\n";
		&dbadd( $dbname, $class, $thing, "groups", $groupfnc );
		}
	    elsif( $fnc eq "-" )
		{
		print "Removing $groupfnc from ${thing}'s groups.\n";
		&dbadd( $dbname, $class, $thing, "groups", $groupfnc );
		}
	    else
		{
		print STDERR "Unknown function [$fnc]\n";
		}
	    }
	}
    }

#########################################################################
#	Figure out group name based on full name.			#
#	(or over-write info about it if already exists)			#
#########################################################################
sub add_thing
    {
    my( $dbname, $class, $suggested_name ) = @_;
    my $thing = lc( &text_to_filename( $suggested_name ) );
    &dbwrite( $dbname );
    &dbadd( $dbname, $class, $thing );
    &dbput( $dbname, $class, $thing, "inuse", 1 );
    if( $ARGS{full_name} )
        { &dbput( $dbname, $class, $thing, "fullname", $ARGS{full_name} ); }
    elsif( ! &dbget( $dbname, $class, $thing, "fullname" ) )
        { &dbput( $dbname, $class, $thing, "fullname", $suggested_name ); }
    &add_user( $dbname, $thing ) if( $class eq "users" );
    &dbpop( $dbname );
    }

#########################################################################
#	Prompt for a password and return in clear text.  Handle echo.	#
#########################################################################
sub prompt_password
    {
    my( $prompt_text ) = @_;
    system("stty -echo");
    my $password;
    do  {
	print $prompt_text;
	$password = <STDIN>;
	print "\n";
	chomp($password) if( defined( $password ) );
	} while( defined($password) && $password eq "" );
    system("stty echo");
    return $password;
    }

#########################################################################
#	Main								#
#########################################################################
%ARGS = &parse_arguments(
    {
    flags		=>	[ "init", "setup", "delete", "yes", "ask_password" ],
    switches=>
	{
	"list"		=>	[ "", "users", "groups" ],
	"administrator"	=>	"",
	"user"		=>	"",
	"password"	=>	"",
	"full_name"	=>	"",
	"groups"	=>	"",
	"email"		=>	"",
	"fax"		=>	"",
	"phone"		=>	"",
	"address"	=>	"",
	"cardnum"	=>	"",
	"cardname"	=>	"",
	"cardexp"	=>	"",
	#"database"	=>	"/usr/local/projects/common/db/accounts.db",
	"database"	=>	"new.db",
	"run"		=>	"",
	}
    } );

if( $ARGS{ask_password} )
    {
    $ARGS{password} = &prompt_password("Password:  ");
    &fatal("Premature EOF") if( ! defined($ARGS{password}) );
    }
$ARGS{password} = &salted_password( $ARGS{password} )
    if( defined($ARGS{password}) && $ARGS{password} ne "" );

if(    $ARGS{init} )		{ &setup_account_database( $ARGS{database}, 1 ); }
elsif( $ARGS{setup} )		{ &setup_account_database( $ARGS{database}, 0 ); }

if( $ARGS{list} )		{ &do_list( $ARGS{database}, $ARGS{list} ); }
elsif( $ARGS{delete} )
    {
    if( $ARGS{user} )
	{ &delete_thing( $ARGS{database}, "users", $ARGS{user} ); }
    elsif( $ARGS{administrator} )
	{ &delete_thing( $ARGS{database}, "users", $ARGS{administrator} ); }
    elsif( $ARGS{groups} )
	{ &delete_thing( $ARGS{database}, "groups", $ARGS{groups} ); }
    else
	{ &fatal("You must specify either a user or group to delete."); }
    }
elsif( $ARGS{administrator} )	{ &add_thing( $ARGS{database}, "users", $ARGS{administrator} ); }
elsif( $ARGS{user} )		{ &add_thing( $ARGS{database}, "users", $ARGS{user} ); }
elsif( $ARGS{groups} )		{ &add_thing( $ARGS{database}, "groups", $ARGS{groups} ); }
elsif( ! $ARGS{init} && ! $ARGS{setup} )
    {
    &usage("No command (-init, -setup, -list, -user, -group) specified.");
    }
&cleanup(0);
