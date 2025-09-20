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
	    : join("/",$STDERR_LOG_DIR,$args{stderr}) );
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

    $cpi_user::require_captcha		= $args{require_captcha};
    $cpi_user::require_fullname		= $args{require_fullname};
    $cpi_user::preset_language		= $args{preset_language};
    foreach my $fld ( @CONFIRM_FIELDS )
        {
	$FLDESC{$fld}{req} = $args{"require_valid_$fld"}
	    if( defined($args{"require_valid_$fld"}) );
	$FLDESC{$fld}{ask} = $args{"ask_for_$fld"}
	    if( defined($args{"ask_for_$fld"}) );
	}
    $cpi_user::anonymous_user	= $args{anonymous_user};
    $cpi_user::anonymous_funcs
				= $args{anonymous_funcs};
    $cpi_user::allow_account_creation
				= $args{allow_account_creation};
    $LANG			= $cpi_user::preset_language if( $cpi_user::preset_language );

    #$PROG=$0;
    #$PROG =~ s+.*/++;
    #$PROG =~ s+\.[^\.]*$++;

    #print STDERR __LINE__,": SCRIPT_FILENAME=[$ENV{SCRIPT_FILENAME}]\n";
    if( $ENV{SCRIPT_FILENAME} )
	{ $BASEFILE=$ENV{SCRIPT_FILENAME}; }
    elsif( $0 =~ /^\// )
	{ $BASEFILE=$0; }
    else
	{ chomp($BASEFILE=`pwd`); $BASEFILE .= "/$0"; }

    $BASEFILE=~s+/\./+/+g;
    $BASEFILE=~s+-test\.+.+g;
    $BASEDIR=$BASEFILE;
    $BASEDIR=~s+$OFFSET/+/+;
    $BASEDIR=~s+/index\.cgi$++;
    $BASEDIR=~s+/app\.cgi$++;
    $BASEDIR=~s+\.cgi$++;
    $BASEDIR=~s+/usr/local/bin+$PROJECTSDIR+g;
    $PROG=$BASEDIR;
    $PROG=~s+.*/++;
    $WEBSITE="unknown";
    if( $BASEDIR =~ m:/var/www/([^/]*): )
	{
	$WEBSITE = $1;		# html, ns, linear-air, etc.
	$BASEDIR = "$PROJECTSDIR/$PROG";
	}
    elsif( $BASEDIR =~ m+$PROJECTSDIR/([^/]*)/(.*)+ )
	{
	$WEBSITE = $1;		# html, ns, linear-air, etc.
	$BASEDIR = "$PROJECTSDIR/$1";
	}

    # These just should not happen.  Probably should delete
    $BASEDIR=~s+var/www/html+usr/local+g;
    $BASEDIR=~s+public_html/+projects/+;
    $BASEDIR=~s+/app/+/+;
    #$BASEDIR=~s:/var/www/html/([^/]+)/:/home/$1/projects/:;
    $BASEDIR=~s+Sites/+projects/+;
    $HELPDIR = "$BASEDIR/help";
    $HELP_IFRAME = "<iframe style='width:80%;height:80%;border: 4px solid #000;-moz-border-radius: 15px; border-radius: 15px;z-index:100;position:fixed;top:5%;right:10%;display:none' id=help_id>iframes do not seem to work.</iframe>";

#    print STDERR __LINE__, " --------------\n";
#    print STDERR __LINE__, " PROG=",$PROG,"\n";
#    print STDERR __LINE__, " BASEDIR=",$BASEDIR,"\n";
#    print STDERR __LINE__, " BASEFILE=",$BASEFILE,"\n";
#    print STDERR __LINE__, " WEBSITE=",$WEBSITE,"\n";
#    print STDERR __LINE__, " --------------\n";
    
    #$PROG = $BASEDIR;
    #$PROG =~ s+^.*/++;
    $COMMONDIR="$PROJECTSDIR/common";
    $COMMONDIR=$BASEDIR if( ! -d $COMMONDIR );
    $COMMONLIB="$COMMONDIR/lib";
    $COMMONJS="$COMMONLIB/common.js";
    $TRANSLATIONS_BASE="$PROJECTSDIR/transdaemon/db/app";
    $TRANSLATIONS_DB=&find_db("$TRANSLATIONS_BASE");
    $TRANSLATIONS_TODO="$TRANSLATIONS_BASE.todo";
    $ACCOUNTDB=&find_db("$COMMONDIR/db/accounts");
    $WRITTEN_IN="en";
    $LANG_TRAN="tran";
    $DB=&find_db("$BASEDIR/db/app");
    $DBSEP="\377";
    $SQLSEP="__";
    %DBSTATUS = ();
    %DBWRITTEN = ();
    %db_stati = ();
    %databases = ();
    #$LOGIN_TIMEOUT = 7200;
    $LOGIN_TIMEOUT = 86400;
    $NOW = time();
    $PAYMENT_SYSTEM = $args{payment_system};
    $DOMAIN="Brightsands.COM";
    $CSS_URL="/Brightsands.css";
    $PROG_CSS_URL="$OFFSET/$PROG/$PROG.css";
    $ICON_URL="$OFFSET/$PROG/".$PROG."_icon.ico";
    $IOS_ICON_URL="$OFFSET/$PROG/".$PROG."_icon.png";
    $ANONYMOUS = 0;
    $DAEMON_EMAIL="$PROG\@$DOMAIN";
    #$DAEMON_EMAIL="c.m.caldwell\@alumni.unh.edu";
    $FAX_SERVER = "Officejet_Pro_8500_A909a_fax";

    if( $ENV{SCRIPT_NAME} && $ENV{SCRIPT_NAME} ne "" )
	{
	$THIS=$ENV{SCRIPT_NAME};
	$URL=($ENV{REQUEST_SCHEME}||"http")."://$ENV{SERVER_NAME}"
	    . ( ( $ENV{SERVER_PORT} == 80) ? "" : ":$ENV{SERVER_PORT}" )
	    . $THIS;
	$cpi_user::SIDDIR="$COMMONDIR/SIDS";
	if( $BASEDIR ne $COMMONDIR )
	    { $SIDNAME = "cmc_sid"; }
	else
	    { $SIDNAME = $PROG."_SID"; }
	    
	$BODY_TAGS		||= "bgcolor=#d0e0f0 link=#c02030 vlink=#10e030 ";
	$HIGHLIGHT_COLOR	||= "#ff6060";
	$LOWLIGHT_COLOR		||= "#808080";
	$TABLE_TAGS		||= "bgcolor=#c0e0f0";
	$TODAY			= &timestr( time() );
	&CGIreceive();
	$LANG			||= $FORM{LANG};
	&init_phrases();

	&dbread( $ACCOUNTDB );

	&login();
	&dbread( $DB ) if( $DB && -f $DB );
	}
    elsif( defined($ARGV[0]) )
	{
	if( $ARGV[0] eq "copydb" )
	    { &copydb( $ARGV[1], $ARGV[2] ); }
	elsif( $ARGV[0] eq "table" )
	    { &new_sql_table( $ARGV[1], $ARGV[2] ); }
#	elsif( $ARGV[0] eq "dumpapp" || $ARGV[0] eq "dump" )
#	    { &dumpdb($DB,$ARGV[1]); }
#	elsif( $ARGV[0] eq "dumpaccounts" )
#	    { &dumpdb($ACCOUNTDB,$ARGV[1]); }
#	elsif( $ARGV[0] eq "dumptranslations" )
#	    { &dumpdb($TRANSLATIONS_DB,$ARGV[1]); }
#	elsif( $ARGV[0] eq "undumpapp" || $ARGV[0] eq "undump" )
#	    { &undumpdb($DB,$ARGV[1]); }
#	elsif( $ARGV[0] eq "undumpaccounts" )
#	    { &undumpdb($ACCOUNTDB,$ARGV[1]); }
#	elsif( $ARGV[0] eq "undumptranslations" )
#	    { &undumpdb($TRANSLATIONS_DB,$ARGV[1]); }
	}
    $CACHEDIR = ($ENV{HOME}||$BASEDIR)."/.cache";
    $DEFAULT_FORM = "form";
    }
1;
