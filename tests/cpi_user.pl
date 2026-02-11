#!/usr/bin/perl -w
#
#indx#	cpi_user.pl - Software for testing web user routines
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
#doc#	cpi_user.pl - Software for testing web user routines
########################################################################

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
#	"can_csv"		=> "Can generate CSV files",
#	"can_e_mail"		=> "Can send E-mail",
#	"can_fax"		=> "Can send Faxes",
#	"can_file"		=> "Can create files",
#	"can_ftp"		=> "Can send via FTP",
#	"can_html"		=> "Can generate HTML",
#	"can_json"		=> "Can generate JSON",
#	"can_pdf"		=> "Can generate PDF files",
#	"can_sql"		=> "Can generate SQL",
#	"can_sql_server"	=> "Can send to SQL_server",
#	"can_text"		=> "Can generate text",
#	"can_tfs"		=> "Can generate TFS",
#	"can_xml"		=> "Can generate XML",
	"create_group"		=> "Can create groups",
	"create_user"		=> "Can create users",
	"user_user"		=> "User user"
    );
my @ADMINISTRATOR_GROUPS = sort keys %STANDARD_GROUPS;

#########################################################################
#	Print a usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_,
	"",
	"Usage:  $cpi_vars::PROG { <argument> }",
	"where <argument> is one or more of:",
	"-list <what>      'users' or 'groups'",
	"",
	"-administrator <username>",
	"    or",
	"-user <username>",
	"",
	"-group <groupname>",
	"-full <full name>",
	"",
	"-password <password to encrypt>",
	"    or",
	"-askpassword",
	"",
	"-merge or -overwrite or -init" );
    }

#########################################################################
#	Convert to an id.						#
#########################################################################
sub text_to_id
    {
    return lc( &text_to_filename( @_ ) );
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
    my( $dbname ) = @_;
    if( $ARGS{mode} eq "init" )
	{
	unlink( $dbname );
        &dbnew( $dbname );
	}
    &dbwrite( $dbname );
    foreach my $group ( keys %STANDARD_GROUPS )
	{
	&dbadd( $dbname, "groups", $group );
	&dbput( $dbname, "groups", $group, "inuse", 1 );
	&mergeput( $dbname, "groups", $group, "fullname", $STANDARD_GROUPS{$group} );
	}
    &dbpop( $dbname );
    system("chmod 666 $dbname");
    }

#########################################################################
#	Get rid of a user or group.  Remove stranded records.		#
#########################################################################
sub delete_thing
    {
    my( $dbname, $class, $rec_to_delete ) = @_;
    $rec_to_delete = &id_to_text( $rec_to_delete );
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
#	Only overwrite values that aren't set if merge set.		#
#########################################################################
sub mergeput
    {
    &dbput( @_ ) if( $ARGS{mode} ne "merge" || ! &dbget( @_[0..($#_-1)] ) );
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
	{ &mergeput( $dbname, $class, $thing, $fld, $ARGS{$fld} ); }
    my @groups =
    	( $ARGS{administrator}
	? grep( &dbget($dbname,"groups",$_,"inuse"), &dbget($dbname,"groups") )
	: "user_user" );
    foreach my $group ( @groups )
        { &dbadd( $dbname, $class, $thing, "groups", $group ); }
    if( $ARGS{groups} )
	{
	my $fnc = "+";
	foreach my $groupfnc ( split(/([+\-])/,$ARGS{groups}) )
	    {
	    $groupfnc = &text_to_id( $groupfnc );
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
    my $thing = &text_to_id( $suggested_name );
    &dbwrite( $dbname );
    &dbadd( $dbname, $class, $thing );
    &dbput( $dbname, $class, $thing, "inuse", 1 );
    &mergeput( $dbname, $class, $thing, "fullname",
	$ARGS{full_name} || $suggested_name );
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
    flags		=>	[ "delete", "yes", "ask_password" ],
    switches=>
	{
	"list"		=>	[ "", "users", "groups" ],
	"mode"		=>	[ "overwrite", "init", "merge" ],
	"init"		=>	{ alias=>[ "-mode", "init" ] },
	"merge"		=>	{ alias=>[ "-mode", "merge" ] },
	"overwrite"	=>	{ alias=>[ "-mode", "overwrite" ] },
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

$ARGS{user} ||= $ARGS{administrator};

if( $ARGS{ask_password} )
    {
    my $ask = 1;
    if( $ARGS{mode} eq "merge" )	# Don't ask if not going to use info
	{
	&dbread( $ARGS{database} );
	$ask = ! &dbget( $ARGS{database}, "users", &text_to_id($ARGS{user}), "password" );
	&dbpop( $ARGS{database} );
	}
    if( $ask )
        { $ARGS{password} = &prompt_password("Password:  "); }
    else
        {
	print "Not asking for password as it is already set.";
	$ARGS{password} = "Who cares?";
	}
    &fatal("Premature EOF") if( ! defined($ARGS{password}) );
    }
$ARGS{password} = &salted_password( $ARGS{password} )
    if( defined($ARGS{password}) && $ARGS{password} ne "" );

if( $ARGS{mode} eq "init" || $ARGS{mode} eq "setup" )
    { &setup_account_database( $ARGS{database} ); }

if( $ARGS{delete} )
    {
    if( $ARGS{user} )		{ &delete_thing( $ARGS{database}, "users", $ARGS{user} ); }
    elsif( $ARGS{groups} )	{ &delete_thing( $ARGS{database}, "groups", $ARGS{groups} ); }
    else
	{ &fatal("You must specify either a user or group to delete."); }
    }
elsif( $ARGS{list} )		{ &do_list( $ARGS{database}, $ARGS{list} ); }
elsif( $ARGS{user} )		{ &add_thing( $ARGS{database}, "users", $ARGS{user} ); }
elsif( $ARGS{groups} )		{ &add_thing( $ARGS{database}, "groups", $ARGS{groups} ); }
else
    {
    &usage("No command (-user, -group, -list, or -delete) specified.");
    }
&cleanup(0);
