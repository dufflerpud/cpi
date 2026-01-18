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

package cpi_vars;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( );
use lib ".";


#########################################################################
# cpi_cache:
our $CACHEDIR;

#########################################################################
# cpi_cgi:
our $SAME_RELATIVE	= <<EOF;
	table				{font-size:inherit;}
	h1                      	{font-size:2em;}
	h2                      	{font-size:1.6em;}
	h3                      	{font-size:1.4em;}
	td                      	{font-size:1em;valign:top;}
	th                      	{font-size:1em;valign:top;}
	input[type=button]      	{font-size:1em;}
	input[type=submit]      	{font-size:1em;}
	input[type=number]        	{font-size:0.9em;}
	input[type=email]        	{font-size:0.9em;}
	input[type=tel] 	       	{font-size:0.9em;}
	input[type=text]        	{font-size:0.9em;}
	input[type=datetime]		{font-size:0.9em;}
	input[type=datetime-local]	{font-size:0.9em;}
	input[type=checkbox]    	{height:1em; width:1em;}
	input[type=radio]       	{height:1em; width:1em;}
	textarea                	{font-size:0.8em;}
	select                  	{font-size:1em;}
EOF

our @CSS_PER_DEVICE_TYPE	=
    (					# Set base font sizes
    "iPhone"		=> <<EOF,	# for devices we know about
	body				{font-size:45px;}
	input.fixed_width_button	{width:700px;}
$SAME_RELATIVE
	input[type=checkbox]		{width:50px;height:50px;}
	input[type=radio]		{width:50px;height:50px;}
EOF
    "iPad"		=> <<EOF,
	body                    	{font-size:10px;}
	input.fixed_width_button	{width:700px;}
$SAME_RELATIVE
EOF
    "."			=> <<EOF
    	input.fixed_width_button	{width:300px;}
	td input.fixed_width_button	{width:300px;}
EOF
    );

our %FORM;
our $DEFAULT_FORM = "form";
our $CGIheader_has_been_printed = 0;

#########################################################################
# cpi_db:

our @DB_EXTS		= (".db",".sql",".po");
our $DBSEP		= "\377";
our $SQLSEP;
our %DBSTATUS;
our %DBWRITTEN;
our %databases;
our %db_fh;
our %db_type;
our %db_stati;

#########################################################################
# cpi_file:
our $TEMP_DIR;
our $VERBOSITY = 0;

#########################################################################
# cpi_help:
#my @HELP_EVENTS = ( "contextmenu", "touchstart", "touchend" );
our @HELP_EVENTS = ( "contextmenu" );       # Help stuff sucks on iPhone
our $HELPDIR;
our $HELP_IFRAME;

#########################################################################
# cpi_log:
our $ACCOUNTING_LOG = "/var/log/common.log";

#########################################################################
# cpi_mime:
our %EXT_TO_MIME_TYPE;
our %EXT_TO_BASE_TYPE;
our %MIME_TYPE_TO_EXTS;
our %MIME_TYPE_TO_BASE_TYPE;
our %BASE_TYPE_TO_EXTS;
our %BASE_TYPE_TO_MIME_TYPES;

#########################################################################
# cpi_send_file:
our $HTML2PDF = "wkhtmltopdf";
our $HTML2PS = "html2ps";
our $PS2PDF = "ps2pdf";
our $SENDMAIL =
    ( -x "/usr/lib/sendmail"
    ? "/usr/lib/sendmail"
    : "sendmail" );
our $FAX_SERVER;
our $BASE_SERVER;
our $BASE_URL;
our $BASES_URL;

#########################################################################
# cpi_lock:
our $LOCK_DEBUG = 1;
our $LOCK_BREAK_STALE = 1;

#########################################################################
# cpi_setup:
our $STDERR_LOG_DIR = "/var/log/stderr";
our $PROJECTSDIR = "/usr/local/projects";
our $DAEMON_EMAIL;
our $DOMAIN;
our $THIS;
our $BASEFILE;
our $OFFSET = "/sto";
our $WEBSITE;
our $PROG;
if ( defined($ENV{SCRIPT_FILENAME})
    && $ENV{SCRIPT_FILENAME} =~ m~/([^/]*)/index.cgi$~ )
    { $PROG = $1; }
elsif( $0 =~ m~([^/]*)\.\w+$~ )
    { $PROG = $1; }
elsif( $0 =~ m~([^/]*)$~ )
    { $PROG = $1; }
else
    { $PROG = $0; }

our $BASEDIR = "$PROJECTSDIR/$PROG";	$BASEDIR =~ s:\.\w+$::;
our $COMMONDIR;
our $COMMONLIB;
our $COMMONJS;
our $CSS_URL;
our $PROG_CSS_URL;
our $ICON_URL;
our $IOS_ICON_URL;
our $BODY_TAGS;
our $HIGHLIGHT_COLOR;
our $LOWLIGHT_COLOR;
our $TABLE_TAGS;
our $URL;
our $NOW;
our $TODAY;

#########################################################################
# cpi_translate:
our $TRANSLATIONS_BATCH		= 1;
our $TRANSLATIONS_LIVE		= 0;
our $TRANSLATIONS_DB;
our $TRANSLATIONS_TODO;
our $TRANSLATIONS_BASE;

our $LANG;
our $LANG_TRAN;
our $WRITTEN_IN;

#########################################################################
# cpi_translate:
our $KEY_CAPTCHA_PUBLIC	= "6LfWBgUAAAAAAGBpRAxhZTUixDVWVVRJBqnq-4_Q";
our $KEY_CAPTCHA_PRIVATE	= "6LfWBgUAAAAAAH6d5yLV3pGUsxaruuh8JGfz0W2X";

our @CONFIRM_FIELDS =
    (
    "email"			=> { prompt=>"E-mail address",  cols=>20,rows=>1,ask=>1,req=>0 },
    "phone"			=> { prompt=>"Phone number",    cols=>14,rows=>1,ask=>1,req=>0 },
    "text"			=> { prompt=>"Text number",     cols=>14,rows=>1,ask=>1,req=>0 },
    "fax"			=> { prompt=>"Fax number",      cols=>14,rows=>1,ask=>1,req=>0 },
    "address"			=> { prompt=>"Mailing address", cols=>40,rows=>5,ask=>1,req=>0 },
    "shipping"			=> { prompt=>"Shipping address",cols=>40,rows=>5,ask=>1,req=>0 }
    );
our %FLDESC = @CONFIRM_FIELDS;
@CONFIRM_FIELDS = grep( defined($FLDESC{$_}{prompt}), @CONFIRM_FIELDS );

our $anonymous_user;
our $anonymous_funcs;
our $allow_account_creation = 1;
our $preset_language;
our $require_captcha;
our $require_fullname;

our $REALUSER;
our $SID;
our $ACCOUNTDB;
our $ANONYMOUS;
our $LOGIN_TIMEOUT;
our $SIDDIR;
our $SIDNAME;
our $USER;
our $FULLNAME;
our $DB;
our $PAYMENT_SYSTEM;

do "/etc/cpi_cfg.pl" if( -r "/etc/cpi_cfg.pl" );

#__END__
1;
