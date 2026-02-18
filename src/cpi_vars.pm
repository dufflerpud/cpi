#!/usr/bin/perl -w
#
#indx#	cpi_vars.pm - Variables shared with CPI interface
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2025-2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
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
#hist#	2026-02-09 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	cpi_vars.pm - Variables shared with CPI interface
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
	button				{font-size:1em;}
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
# cpi_user:
our $KEY_CAPTCHA_PUBLIC		= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
our $KEY_CAPTCHA_PRIVATE	= "YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY";

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
