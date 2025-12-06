#!/usr/bin/perl -w
########################################################################
#@HDR@	$Id$
#@HDR@		Copyright 2025 by
#@HDR@		Christopher Caldwell
#@HDR@		P.O. Box 401, Bailey Island, ME 04003
#@HDR@		All Rights Reserved
#@HDR@
#@HDR@	This software comprises unpublished confidential information
#@HDR@	of the copyright holder and may not be used, copied or made
#@HDR@	available to anyone, except in accordance with the license
#@HDR@	under which it is furnished.
########################################################################

use strict;

package cpi_setup;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( setup );
use lib ".";

use cpi_file qw( cleanup );
use cpi_cgi qw( CGIreceive );
use cpi_copy_db qw( copydb dumpdb undumpdb );
use cpi_db qw( dbread find_db new_sql_table dbnew );
use cpi_time qw( timestr );
use cpi_translate qw( init_phrases );
use cpi_user qw( login );
use cpi_vars;
#__END__
1;

#########################################################################
#	Called at the top of your app.cgi.  Takes care of logging in.	#
#########################################################################
sub setup
    {
    my( %args ) = @_;

    if( $args{stderr} )		# Do early to make error checking easier
        {
	my $stderr_fname =
	    ( $args{stderr} =~ /^\//
	    ? $args{stderr}
	    : join("/",$cpi_vars::STDERR_LOG_DIR,$args{stderr}) );
	close( STDERR );
	if( -f "$stderr_fname.truncated" )
	    {
	    open( STDERR, "> $stderr_fname.truncated" )
		|| die("Cannot write to ${stderr_fname}.truncated:  $!");
	    }
	else
	    {
	    open( STDERR, ">> $stderr_fname" )
		|| die("Cannot append to ${stderr_fname}:  $!");
	    }
	chmod( 0666, $stderr_fname );
	my $old_fh = select(STDERR);
	$| = 1;
	select($old_fh);
	}

    $cpi_vars::require_captcha		= $args{require_captcha};
    $cpi_vars::require_fullname		= $args{require_fullname};
    $cpi_vars::preset_language		= $args{preset_language};
    foreach my $fld ( @cpi_vars::CONFIRM_FIELDS )
        {
	$cpi_vars::FLDESC{$fld}{req} = $args{"require_valid_$fld"}
	    if( defined($args{"require_valid_$fld"}) );
	$cpi_vars::FLDESC{$fld}{ask} = $args{"ask_for_$fld"}
	    if( defined($args{"ask_for_$fld"}) );
	}
    $cpi_vars::anonymous_user	= $args{anonymous_user};
    $cpi_vars::anonymous_funcs
				= $args{anonymous_funcs};
    $cpi_vars::allow_account_creation
				= $args{allow_account_creation};
    $cpi_vars::LANG			= $cpi_vars::preset_language if( $cpi_vars::preset_language );

    #$cpi_vars::PROG=$0;
    #$cpi_vars::PROG =~ s+.*/++;
    #$cpi_vars::PROG =~ s+\.[^\.]*$++;

    #print STDERR __LINE__,": SCRIPT_FILENAME=[$ENV{SCRIPT_FILENAME}]\n";
    if( $ENV{SCRIPT_FILENAME} )
	{ $cpi_vars::BASEFILE=$ENV{SCRIPT_FILENAME}; }
    elsif( $0 =~ /^\// )
	{ $cpi_vars::BASEFILE=$0; }
    else
	{ chomp($cpi_vars::BASEFILE=`pwd`); $cpi_vars::BASEFILE .= "/$0"; }

    $cpi_vars::BASEFILE=~s+/\./+/+g;
    $cpi_vars::BASEFILE=~s+-test\.+.+g;
    $cpi_vars::BASEDIR=$cpi_vars::BASEFILE;
    $cpi_vars::BASEDIR=~s+$cpi_vars::OFFSET/+/+;
    $cpi_vars::BASEDIR=~s+/index\.cgi$++;
    $cpi_vars::BASEDIR=~s+/app\.cgi$++;
    $cpi_vars::BASEDIR=~s+\.cgi$++;
    $cpi_vars::BASEDIR=~s+/usr/local/bin+$cpi_vars::PROJECTSDIR+g;
    $cpi_vars::PROG=$cpi_vars::BASEDIR;
    $cpi_vars::PROG=~s+.*/++;
    $cpi_vars::WEBSITE="unknown";
    if( $cpi_vars::BASEDIR =~ m:/var/www/([^/]*): )
	{
	$cpi_vars::WEBSITE = $1;		# html, ns, linear-air, etc.
	$cpi_vars::BASEDIR = "$cpi_vars::PROJECTSDIR/$cpi_vars::PROG";
	}
    elsif( $cpi_vars::BASEDIR =~ m+$cpi_vars::PROJECTSDIR/([^/]*)/(.*)+ )
	{
	$cpi_vars::WEBSITE = $1;		# html, ns, linear-air, etc.
	$cpi_vars::BASEDIR = "$cpi_vars::PROJECTSDIR/$1";
	}

    # These just should not happen.  Probably should delete
    $cpi_vars::BASEDIR=~s+var/www/html+usr/local+g;
    $cpi_vars::BASEDIR=~s+public_html/+projects/+;
    $cpi_vars::BASEDIR=~s+/app/+/+;
    #$cpi_vars::BASEDIR=~s:/var/www/html/([^/]+)/:/home/$1/projects/:;
    $cpi_vars::BASEDIR=~s+Sites/+projects/+;
    $cpi_vars::HELPDIR = "$cpi_vars::BASEDIR/help";
    $cpi_vars::HELP_IFRAME = "<iframe style='width:80%;height:80%;border: 4px solid #000;-moz-border-radius: 15px; border-radius: 15px;z-index:100;position:fixed;top:5%;right:10%;display:none' id=help_id>iframes do not seem to work.</iframe>";

#    print STDERR __LINE__, " --------------\n";
#    print STDERR __LINE__, " PROG=",$cpi_vars::PROG,"\n";
#    print STDERR __LINE__, " BASEDIR=",$cpi_vars::BASEDIR,"\n";
#    print STDERR __LINE__, " BASEFILE=",$cpi_vars::BASEFILE,"\n";
#    print STDERR __LINE__, " WEBSITE=",$cpi_vars::WEBSITE,"\n";
#    print STDERR __LINE__, " --------------\n";
    
    #$cpi_vars::PROG = $cpi_vars::BASEDIR;
    #$cpi_vars::PROG =~ s+^.*/++;
    $cpi_vars::COMMONDIR="$cpi_vars::PROJECTSDIR/common";
    $cpi_vars::COMMONDIR=$cpi_vars::BASEDIR if( ! -d $cpi_vars::COMMONDIR );
    $cpi_vars::COMMONLIB="$cpi_vars::COMMONDIR/lib";
    $cpi_vars::COMMONJS="$cpi_vars::COMMONLIB/common.js";
    $cpi_vars::TRANSLATIONS_BASE="$cpi_vars::COMMONDIR/db/xl";
    $cpi_vars::TRANSLATIONS_DB=&find_db("$cpi_vars::TRANSLATIONS_BASE");
    $cpi_vars::TRANSLATIONS_TODO="$cpi_vars::TRANSLATIONS_BASE.todo";
    $cpi_vars::ACCOUNTDB=&find_db("$cpi_vars::COMMONDIR/db/accounts");
    $cpi_vars::WRITTEN_IN="en";
    $cpi_vars::LANG_TRAN="tran";
    $cpi_vars::DB=&find_db("$cpi_vars::BASEDIR/db/app");
    #$cpi_vars::DBSEP="\377";
    $cpi_vars::SQLSEP="__";
    %cpi_vars::DBSTATUS = ();
    %cpi_vars::DBWRITTEN = ();
    %cpi_vars::db_stati = ();
    %cpi_vars::databases = ();
    #$cpi_vars::LOGIN_TIMEOUT = 7200;
    $cpi_vars::LOGIN_TIMEOUT = 86400;
    $cpi_vars::NOW = time();
    $cpi_vars::PAYMENT_SYSTEM = $args{payment_system};
    $cpi_vars::DOMAIN||="Unknown";
    $cpi_vars::CSS_URL="/default.css";
    $cpi_vars::PROG_CSS_URL="$cpi_vars::OFFSET/$cpi_vars::PROG/$cpi_vars::PROG.css";
    $cpi_vars::ICON_URL="$cpi_vars::OFFSET/$cpi_vars::PROG/".$cpi_vars::PROG."_icon.ico";
    $cpi_vars::IOS_ICON_URL="$cpi_vars::OFFSET/$cpi_vars::PROG/".$cpi_vars::PROG."_icon.png";
    $cpi_vars::ANONYMOUS = 0;
    $cpi_vars::DAEMON_EMAIL="$cpi_vars::PROG\@$cpi_vars::DOMAIN";
    $cpi_vars::FAX_SERVER ||= "Unknown";

    if( $ENV{SCRIPT_NAME} && $ENV{SCRIPT_NAME} ne "" )
	{
	$cpi_vars::THIS=$ENV{SCRIPT_NAME};
	$cpi_vars::URL=($ENV{REQUEST_SCHEME}||"http")."://$ENV{SERVER_NAME}"
	    . ( ( $ENV{SERVER_PORT} == 80) ? "" : ":$ENV{SERVER_PORT}" )
	    . $cpi_vars::THIS;
	$cpi_vars::SIDDIR="$cpi_vars::COMMONDIR/SIDS";
	if( 1 || $cpi_vars::BASEDIR ne $cpi_vars::COMMONDIR )
	    { $cpi_vars::SIDNAME = "cpi_sid"; }
	else
	    { $cpi_vars::SIDNAME = $cpi_vars::PROG."_SID"; }
	    
	$cpi_vars::BODY_TAGS		||= "bgcolor=#d0e0f0 link=#c02030 vlink=#10e030 ";
	$cpi_vars::HIGHLIGHT_COLOR	||= "#ff6060";
	$cpi_vars::LOWLIGHT_COLOR	||= "#808080";
	$cpi_vars::TABLE_TAGS		||= "bgcolor=#c0e0f0";
	$cpi_vars::TODAY		= &timestr( time() );
	&CGIreceive();
	$cpi_vars::LANG			||= $cpi_vars::FORM{LANG};
	&init_phrases();

	&dbread( $cpi_vars::ACCOUNTDB );

	&login();
	&dbread( $cpi_vars::DB ) if( $cpi_vars::DB && -f $cpi_vars::DB );
	}
    # This should be handled by parse_arguments but history is long and evil.
    elsif( scalar(@ARGV)==2 && ($ARGV[0] eq "initdb" || $ARGV[0] eq "-initdb" ) )
	{
	&dbnew( $ARGV[1] );
	&cleanup( 0 );
	}
    elsif( scalar(@ARGV)==3 && ($ARGV[0] eq "copydb" || $ARGV[0] eq "-copydb" ) )
	{
	&copydb( $ARGV[1], $ARGV[2] );
	&cleanup( 0 );
	}
#    elsif( scalar(@ARGV)==3 && ($ARGV[0] eq "table" || $ARGV[0] eq "-table" ) )
#	{
#	&new_sql_table( $ARGV[1], $ARGV[2] );
#	&cleanup( 0 );
#	}
    $cpi_vars::CACHEDIR = ($ENV{HOME}||$cpi_vars::BASEDIR)."/.cache";
    $cpi_vars::DEFAULT_FORM = "form";
    }
1;
