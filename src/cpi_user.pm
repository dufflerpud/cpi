use Captcha::reCAPTCHA;
#__END__
1;
#########################################################################
#	Return if user has a particular attribute			#
#########################################################################
sub user_can
    { return &dbget($ACCOUNTDB,"users",$REALUSER,@_); }

sub can_cuser	{ return &user_can("create_user"); }
sub can_suser	{ return &user_can("create_user"); }
sub can_cgroup	{ return &user_can("create_group"); }

#########################################################################
#	Turn text into a token that can be used as a group.		#
#########################################################################
sub name_to_group
    {
    my( $str ) = @_;
    $str = lc($str);
    $str =~ s/'s/s/g;
    $str =~ s/[^a-z0-9]+/_/g;
    $str = $1 if( $str =~ /^_*(.*?)_*$/ );
    return $str;
    }

#########################################################################
#	Remove a session's credentials.					#
#########################################################################
sub logout
    {
    unlink( "$SIDDIR/$SID" );
    &log("$REALUSER logs out from SID $SID.");
    }

#########################################################################
#	Handle invitations						#
#########################################################################
sub handle_invitations
    {
    my( @msgs ) = ();
    my $written = 0;
    if( $FORM{activation_code} )
	{
	foreach my $activation_code ( split(/,/,$FORM{activation_code}) )
	    {
	    my $found_activation_code = 0;
	    foreach my $fld ( @CONFIRM_FIELDS )
		{
		my $ccode = &dbget($ACCOUNTDB,
		    "users",$REALUSER,"confirm$fld");
		if( $ccode eq $activation_code )
		    {
		    my $val = &dbget($ACCOUNTDB,"users",$REALUSER,$fld);
		    &dbwrite( $ACCOUNTDB ) if( $written++ == 0 );
		    &dbput($ACCOUNTDB,"users",$REALUSER,
		        "last".$fld,$val);
		    $found_activation_code = 1;
		    push( @msgs, "XL($fld confirmed as) $val." );
		    last;
		    }
		}
	    next if( $found_activation_code );
	    my $action_string =
		&dbget($ACCOUNTDB,
		    "invitations",$activation_code);
	    if( !defined($action_string) || $action_string eq "" )
		{
		push( @msgs,  "XL(No such invitation as [[$activation_code]])." );
		}
	    elsif( $action_string eq "used" )
		{
		push( @msgs, "XL(Invitation [[$activation_code]] already accepted.)" );
		}
	    else
		{
		&dbwrite( $ACCOUNTDB ) if( $written++ == 0 );
		&dbput($ACCOUNTDB,
		    "invitations",$activation_code,"used");
		&invitation_handler( split($DBSEP,$action_string) );
		}
	    }
	}
    &dbpop( $ACCOUNTDB ) if( $written );
    if( @msgs )
	{
	&xprint( join("<br>",@msgs) );
	&cleanup(0);
	}
    }

#########################################################################
#	Read the variables in from a SID file.				#
#########################################################################
sub read_sid
    {
    my( $fname ) = @_;
    open( IN, $fname ) || &fatal("Cannot open SID file $fname:  $!");
    $REALUSER = <IN>;
    $REALUSER =~ s/[\r\n]//g;
    $LANG = <IN>;
    $LANG =~ s/[\r\n]//g;
    close( IN );
    }

#########################################################################
#	Make sure user is legitimate					#
#	Note:  This requires READ-ONLY access to the accounts database.	#
#	It keeps track of sessions by writing to a SID directory.	#
#	This should simplify/eliminate database locking issues.		#
#########################################################################
sub login
    {
    my( $form_login ) = @_;
    $form_login ||= $DEFAULT_FORM;
    my $msg = "";
    my $fname;
    my @toprint;
    my $check_group = &name_to_group( "can_run_" . $PROG );

    if( ! -d $SIDDIR )
        {
        system("mkdir -p $SIDDIR");
	chmod( 0777, $BASEDIR, $SIDDIR );
	}

    $ANONYMOUS =
        (   $anonymous_user			&&
	    defined($FORM{user})		&&
	    $FORM{user} eq $anonymous_user	);

    $FORM{func}="" if( ! defined( $FORM{func} ) );

    if( $FORM{func} ne "dologin" )
	{
	my ( $primary_func ) = split(/,/,$FORM{func});
	if( $anonymous_funcs
	 && grep( $_ eq $primary_func, split(/,/,$anonymous_funcs) ) )
	    {
	    $SID = ( $anonymous_user || "anonymous" );
	    $USER = $SID;
	    $ANONYMOUS = 1;
	    &CGIheader();
	    return;
	    }
	$SID = ($FORM{SID} || "");
	$SID = $1
	    if( ($SID eq "")
		&& $ENV{HTTP_COOKIE}
		&& defined( $SIDNAME )
		&& ($ENV{HTTP_COOKIE} =~ /$SIDNAME=(\w+)/ ));
	if( $SID )
	    {
	    if( $SID =~ /RT_/ )
		{
		&CGIheader();
		return;
		}
	    elsif( ! -r "$SIDDIR/$SID" )
	        {
		&log("$SIDDIR/$SID removed.");
		undef $SID;
		}
	    }
	}

    if( defined($SID) && $SID ne "" )
        {	# Form claims user already logged in.  We'll see ...
	if( exists &app_dependent_login && &app_dependent_login() )
	    {	# For hat.cgi, probably should get rid of this.
	    &CGIheader();
	    return;
	    }
	elsif( $SID !~ /^[A-Za-z0-9]+$/ )	# SID correct format?
	    { $msg = "XL(Corrupt SID [[$SID]].  Please identify yourself definitively.)"; }
	elsif( ! -r "$SIDDIR/$SID" )	# SID actually exist?
	    { $msg = "XL(User session has timed out and been removed.  Please identify yourself definitively again.)"; }
	elsif( $FORM{func} eq "logout" )	# Oops, he's actually
	    {						# logging out.  Nuke
	    if( !defined($FORM{new_prog})
		|| $FORM{new_prog} eq "logout" )
		{
		&read_sid( "$SIDDIR/$SID" );
		&logout();
		$msg = "XL(Please identify yourself definitively.)";
		}
	    else
	        {
		my $newprog = $ENV{REQUEST_URI};
		#$newprog =~ s+/$PROG.cgi.*+/$FORM{new_prog}.cgi+;
		$newprog =~ s+/$PROG\b+/$FORM{new_prog}+;
		&CGIheader();
		print "<meta http-equiv=\"refresh\" content=\"0;url=$newprog?SID=$SID\">";
		&cleanup(0);
		}
	    }
	else	# If we're here, we have a legitimate SID.
	    {	# Check if it's not too old.
	    $fname = "$SIDDIR/$SID";
	    my( $st_ino, $st_dev, $st_mode, $st_nlink,
		$st_uid, $st_gid, $st_rdev, $st_size, $st_atime, $st_mtime,
		$st_ctime, $st_blksize, $st_blocks) = lstat( $fname );
	    if( (time - $st_mtime) > $LOGIN_TIMEOUT )
	        { $msg="XL(User session has timed out.  Please identify yourself definitively again.)"; }
	    else	# Wow a real live logged in user.  Read user info from
		{	# SID file.
		&read_sid( $fname );
		$ANONYMOUS = ( $anonymous_user && $REALUSER eq $anonymous_user );
		if( ! $anonymous_user &&
		    ! $allow_account_creation &&
		    ! &in_group($REALUSER,$check_group)	)
		    {	# Verify group still exists...
		    $msg="XL(User [[{$REALUSER}]] is not a member of group [[".
			&group_to_name($check_group)."]].)";
		    }
		}
	    }
	}
    else	# If we're here, we're actually in the login process.
        {	# We'll check his answers and if they aren't sufficient
		# Prompt him again.
	my $captresult = "";
	if( $require_captcha					&&
	    (	! $FORM{create_account} || $FORM{emailcode} ) )
	    {
	    if( $FORM{recaptcha_challenge_field}	&&
	        $FORM{recaptcha_response_field}		)
		{
		my $captchaptr = Captcha::reCAPTCHA->new;
		$KEY_CAPTCHA_PRIVATE if(0);	# Get rid of "only used once" warning
		my $captresultptr = $captchaptr->check_answer
		    (
		    $KEY_CAPTCHA_PRIVATE,
		    $ENV{'REMOTE_ADDR'},
		    $FORM{recaptcha_challenge_field},
		    $FORM{recaptcha_response_field}
		    );
		if( ! $captresultptr )
		    { $captresult = "result value"; }
		elsif( $captresultptr->{is_valid} )
		    { $captresult = ""; }
		else
		    { $captresult = $captresultptr->{error}; }
		}
	    else
		{ $msg = "XL(Please identify yourself definitively.)"; }
	    }
	$FORM{user} = lc($FORM{user}||"");	# Tokenize the account name
#	$FORM{user} = "chris"
#	    if( $FORM{user} eq "chris.interim\@gmail.com" );
	$FORM{user} =~ s/[^\w]+/_/g;
	$FORM{user} =~ s/^_+//;
	$FORM{user} =~ s/_+$//;
	if( $captresult )
	    {
	    $msg = "XL(Problem verifying text of picture:  [[$captresult]].)";
	    #$msg .= "<br>Challenge:  $FORM{recaptcha_challenge_field}";
	    #$msg .= "<br>Response:  $FORM{recaptcha_response_field}";
	    }
	elsif( $FORM{user} eq "" )
	    {
	    if( $FORM{create_account} )
	        { $msg = "XL(Please enter information for new account.)"; }
	    else
	        { $msg = "XL(Please identify yourself definitively.)"; }
	    }
	elsif( !$ANONYMOUS && ($FORM{password}||"") eq "" )
	    { $msg = "XL(Must specify password.)"; }
	else
	    {
	    my $let_him_in = $ANONYMOUS;
	    if( ! $let_him_in )
		{
		my $oldp = &dbget($ACCOUNTDB,"users",
				$FORM{user},"password");
		print STDERR "Checking A=$ACCOUNTDB U=$FORM{user} o=[$oldp]\n";
		if( $oldp eq "" )
		    {
		    if( ! $FORM{create_account} )
			{ $msg = "XL(There are problems with these credentials.  Please identify yourself definitively again.)"; }
		    elsif( $FORM{password} ne $FORM{password1} )
			{ $msg = "XL(Both specified passwords must be the same.)"; }
#		    elsif( $FORM{user} !~ /^[a-z][a-z0-9]*$/ )
#		        { $msg = "XL(Account must be all lower case or digits and start with a letter.)"; }
		    elsif( $FORM{user} !~ /[a-z].*[a-z]/ )
			{ $msg = "XL(Account must have two letters.)"; }
		    else
			{
			&dbwrite( $ACCOUNTDB );
			&dbadd( $ACCOUNTDB,
			    "users", $FORM{user} );
			&dbput( $ACCOUNTDB,
			    "users", $FORM{user},
			    "password", $FORM{password} );
			&dbput( $ACCOUNTDB,
			    "users", $FORM{user}, "inuse", 1 );
			&dbput($ACCOUNTDB,"users",$FORM{user},
			    "fullname",$FORM{fullname})
			    if( $require_fullname );
			&dbput( $ACCOUNTDB,
			    "users", $FORM{user}, "groups", $check_group );
			foreach my $fld ( @CONFIRM_FIELDS )
			    {
			    &check_com_field($FORM{user},$fld)
			        if( $FLDESC{$fld}{ask} );
			    }
			&dbpop( $ACCOUNTDB );
			&log("Creating user $FORM{user} in group $check_group.");
			$let_him_in = 1;
			}
		    }
		elsif( $oldp ne $FORM{password} )
		    { $msg = "XL(There are problems with these credentials.  Please identify yourself definitively again.)"; }
		elsif( ! $allow_account_creation &&
		    ! &in_group($FORM{user},$check_group) )
		    {
		    $msg="XL(User [[$FORM{user}]] is not a member of group [[".
			&group_to_name($check_group). "]].)";
		    }
		else
		    { $let_him_in = 1; }
		}
	    if( $let_him_in )
		{
		$SID = &compress_integer( rand() );
		$fname = "$SIDDIR/$SID";
		open( OUT, "> $fname") ||
		    &fatal("XL(Cannot write [[SID]] file [[$fname]]):  $!");
		print OUT "$FORM{user}\n$LANG\n";
		close( OUT );
		$REALUSER = $FORM{user};
		&CGIheader( $SIDNAME, $SID );
		&log("$REALUSER logs in in $LANG with SID $SID.");
		}
	    }
	}

    &CGIheader();

    if( $msg )
        {
	&log( ($FORM{user}||"?") . ":  $msg" );
	my $langstring=($preset_language ? "" : &gen_language_params());
	push( @toprint, <<EOF );
<title>$msg</title><body $BODY_TAGS><center>
<form name=$form_login method=post>
<input type=hidden name=func value=dologin>
<table border=1 $TABLE_TAGS><tr><th colspan=2>$msg</th></tr>
EOF
	push( @toprint,
	    ( $ANONYMOUS
	    ? <<EOF
<input type=hidden name=user value="$FORM{user}">
<input type=hidden name=password value="$FORM{user}">
EOF
	    : <<EOF ) );
$HELP_IFRAME
<tr help='COMMON_account_name'><th align=left>XL(Account name:)</th>
    <td><input type=text name=user autocapitalize=none value="$FORM{user}" autocapitalize=none></td></tr>
<tr help='COMMON_account_password'><th align=left>XL(Password:)</th>
    <td><input type=password name=password></td></tr>
EOF
	if( $FORM{create_account} )
	    {
	    push( @toprint, <<EOF );
<tr help='COMMON_account_password_retyped'><th align=left>XL(Retype password:)</th>
    <td><input type=password name=password1></td></tr>
EOF
	    push( @toprint, <<EOF ) if( $require_fullname );
<tr><th align=left>XL(Full name:)</th>
    <td><input type=text help='COMMON_account_fullname' name=fullname autocapitalize=words value="$FORM{fullname}"></td></tr>
EOF
	    foreach my $fld ( @CONFIRM_FIELDS )
	        {
		push( @toprint, "<tr><th align=left valign=top>XL(Enter valid $FLDESC{$fld}{prompt}:)</th><td>",
		    ( ( $FLDESC{$fld}{rows} && $FLDESC{$fld}{rows}>1 )
		    ? "<textarea help='COMMON_account_$fld' cols=$FLDESC{$fld}{cols} rows=$FLDESC{$fld}{rows} name=$fld >".$FORM{$fld}."</textarea>"
		    : "<input type=text autocapitalize=none help='COMMON_account_$fld' name=$fld size=$FLDESC{$fld}{cols} value='".$FORM{$fld}."'>"
		    ), "</td></tr>" )
		    if( $FLDESC{$fld}{req} );
		}
	    }
	push( @toprint, $langstring );
	if( $require_captcha )
	    {
	    push( @toprint, "<tr help='COMMON_account_captcha'><th colspan=2><center>" );
	    my $captchaptr = Captcha::reCAPTCHA->new;
	    $KEY_CAPTCHA_PUBLIC if(0);		# Get rid of "only used once" warning
	    push( @toprint, $captchaptr->get_html( $KEY_CAPTCHA_PUBLIC ) );
	    push( @toprint, "</center></th></tr>" );
	    }
	push( @toprint, <<EOF );
<tr help='COMMON_account_session'><th colspan=2><input type=submit value="XL(Begin session)"></th></tr>
EOF
	if( $allow_account_creation &&
	    (!defined($FORM{user}) ||
		$FORM{user} ne "anonymous") )
	    {
	    if( ! $FORM{create_account} )
	        { push( @toprint, "<tr help='COMMON_account_create'><th colspan=2><input type=submit name=create_account value=\"XL(Create account)\"></th></tr>" ); }
	    }
	push( @toprint, "</table>\n" );
	my $vn;
	foreach $vn ( keys %FORM )
	    {
	    push(@toprint,"<input type=hidden name=$vn value=\"$FORM{$vn}\">\n")
	        if( ! grep( $_ eq $vn,
		    "USER","user","password","password1","SID","LANG","func",
		    "recaptcha_challenge_field", "recaptcha_response_field",
		    "confirmemail") );
	    }
	push( @toprint, <<EOF );
<script>
window.document.$form_login.user.focus();
</script>
</form>
EOF
	&xprint( @toprint );
	&cleanup(0);
	}

    &handle_invitations();
    system("touch $fname");
    $USER = $REALUSER;
    $FORM{USER} = $USER
	if( !defined($FORM{USER}) || $FORM{USER} eq "" );
    if( $FORM{USER} ne $REALUSER )
        {
	$FORM{USER} = lc($FORM{USER});
	if( $FORM{USER} !~ /^[a-z0-9\.\@]+$/ )
	    { &fatal("$FORM{USER} contains illegal characters."); }
	elsif( ! &dbget($ACCOUNTDB,"users",$FORM{USER},"inuse") )
	    { &fatal("$FORM{USER} does not exist"); }
	elsif( ! &can_suser() )
	    { &fatal("$REALUSER cannot switch users from [$REALUSER] to [$FORM{USER}]."); }
	else
	    {
#	    my %seen = ();
#	    grep( $seen{$_}++, &dbget($ACCOUNTDB,"users",$REALUSER,"groups") );
#	    if(! grep($seen{$_} > 0, &dbget($ACCOUNTDB,"users",$FORM{USER},"groups")))
#	        { &fatal("$FORM{USER} is not in any of your groups."); }
#	    else
		{ $USER=$FORM{USER}; }
	    }
	}
    $FULLNAME = &dbget($ACCOUNTDB,"users",$USER,"fullname");
    }

#########################################################################
#	Determine if the current user is a member of the specified	#
#########################################################################
sub can
    {
    my( $priv ) = @_;
    return grep( $priv eq $_, &dbget($ACCOUNTDB,"users",$REALUSER,"groups") );
    }

#########################################################################
#	Return full name of a user					#
#########################################################################
sub user_name
    {
    my( $u ) = @_;
    return (&dbget($ACCOUNTDB,"users",$u,"fullname") || $u);
    }

#########################################################################
#	Return full name of a group					#
#########################################################################
sub group_to_name
    {
    my( $g ) = @_;
    return (&dbget($ACCOUNTDB,"groups",$g,"fullname") || $g);
    }

#########################################################################
#	Returns list of all non deleted users.				#
#########################################################################
sub all_users
    {
    my @ret = ();
    foreach my $u ( &dbget($ACCOUNTDB,"users") )
	{
	&dbget($ACCOUNTDB,"users",$u,"inuse") && push(@ret,$u);
	}
    return sort @ret;
    }

#########################################################################
#	Return a list of all the users who can run this program.	#
#########################################################################
sub all_prog_users
    {
    my $check_group = &name_to_group( "can_run_" . $PROG );
    return
	grep(
	    &dbget($ACCOUNTDB,"users",$_,"inuse")
	    && &in_group($_,$check_group),
	    &all_users() );
    }

#########################################################################
#	Return list of non deleted groups.				#
#########################################################################
sub groups()
    {
    my( @ret ) = ();
    foreach my $g ( &dbget($ACCOUNTDB,"groups" ) )
	{
        &dbget($ACCOUNTDB,"groups",$g,"inuse") &&
	    push( @ret, $g );
	}
    return sort @ret;
    }

#########################################################################
#	Return non deleted groups user is in.				#
#########################################################################
sub groups_of_user
    {
    my( $u ) = @_;
    my( @ret );
    foreach my $g ( &dbget($ACCOUNTDB,"users",$u,"groups" ) )
	{
        &dbget($ACCOUNTDB,"groups",$g,"inuse") &&
	    push( @ret, $g );
	}
    return sort @ret;
    }

#########################################################################
#	Returns true if specified user is in specified group.		#
#########################################################################
sub in_group
    {
    my( $uname, $gname ) = @_;
    #print "Checking to see if [$uname] is a member of [$gname]<br>\n";
    return grep($_ eq $gname,
	&dbget($ACCOUNTDB,"users",$uname,"groups"));
    }

#########################################################################
#	Returns list of all non-deleted users in group.			#
#	If no group specified, assume group of people who can use this	#
#	application.							#
#########################################################################
sub users_in_group
    {
    my( $l4 ) = @_;
    $l4 = &name_to_group("can_run_$PROG")
	if( ! defined($l4) );
    my @ret = ();
    foreach my $u ( &all_users() )
	{ &in_group( $u, $l4 ) && push( @ret, $u ); }
    return @ret;
    }

1;

#########################################################################
#	Return an HTML table of who's used the system recently.		#
#########################################################################
sub who
    {
    my @dirs = grep(/^[^\.]/,&files_in( $SIDDIR ) );
    my %results = ();
    foreach my $sidfile ( @dirs )
        {
	my $fname = "$SIDDIR/$sidfile";
	my( $st_ino, $st_dev, $st_mode, $st_nlink,
	    $st_uid, $st_gid, $st_rdev, $st_size, $st_atime, $st_mtime,
	    $st_ctime, $st_blksize, $st_blocks) = lstat( $fname );
	my $inactivity = time - $st_mtime;
	if( $inactivity <= $LOGIN_TIMEOUT )
	    {
	    open( INF, $fname ) || &fatal("Cannot read ${fname}:  $!");
	    my( $user, $lang ) = <INF>;
	    close( INF );
	    chomp( $user );
	    chomp( $lang );
	    $results{$sidfile} =
		sprintf(
		    "<tr><td>%s</td><td>%2s</td><td>%02d:%02d:%02d</td></tr>\n",
		    $user, $lang,
		    $inactivity/3600, ($inactivity/60)%60, $inactivity % 60 );
	    }
	}
    my @toprint = ( <<EOF );
<table><tr><th>XL(User)</th><th>XL(Language)</th><th>XL(Inactive)</th></tr>
EOF
    foreach my $sidfile ( sort {$results{$a} cmp $results{$b}} keys %results )
        { push( @toprint, $results{$sidfile} ); }
    push( @toprint, "</table>" );
    return join("",@toprint);
    }

#########################################################################
#	Invite a user to join a group.					#
#########################################################################
sub invite
    {
    my ( $means, $address, $msg, @parts ) = @_;
    my $new_code = "i" . &compress_integer( rand() );
    &dbwrite( $ACCOUNTDB );
    &dbput( $ACCOUNTDB, "invitations",
	$new_code, &dbarr(@parts) );
    &dbpop( $ACCOUNTDB );
    &send_via( $means, $DAEMON_EMAIL, $address,
        &xlate("XL(Invitation)"),
	"$msg\n$URL?func=admin&activation_code=$new_code"
	);
    }

#########################################################################
#	Check to see if field from form is different than user's	#
#	field.  If so, send out missive and update database.		#
#	Returns listof progress messages (or errors).			#
#########################################################################
sub check_com_field
    {
    my( $user, $fld ) = @_;
    my ( @changed_list ) = ();
    my $lastval=&dbget($ACCOUNTDB,"users",$user,$fld)||"";
    if( $lastval ne ($FORM{$fld}||"") )
	{
	&dbput($ACCOUNTDB,
	    "users",$user,$fld,$FORM{$fld});
	my $new_code = "c" . &compress_integer( rand() );
	&dbput($ACCOUNTDB,
	    "users",$user,"confirm$fld",$new_code);
	my $conmsg = &xlate(<<EOF);
XL(This message was sent to you by the $PROG server to verify that
the $fld information you gave it was correct.)

XL(To confirm that it is, login to the $PROG server as
[[$user]], enter the "Administration" mode and enter the value
'[[$new_code]]' where it asks for an activition code.)
EOF
	if( $fld eq "email" )
	    {
	    $conmsg .= &xlate(<<EOF);

XL(If your e-mail reader supports it, you can click here:

[[$URL?user=$user&activation_code=$new_code]]
)
EOF
	    }
	print STDERR $conmsg;
	if( $FORM{$fld} )
	    {
	    &send_via( $fld,
		$DAEMON_EMAIL, $FORM{$fld},
		&xlate("XL(Action required)"), $conmsg );
	    push( @changed_list,
		"XL(Confirmation sent to [[$fld $FORM{$fld}]].)");
	    }
	}
    return @changed_list;
    }

#########################################################################
#	Allow user to change settings about his account.  Normal users	#
#	can only change their password.					#
#########################################################################
sub admin_page
    {
    my( $form_admin ) = @_;
    $form_admin ||= $DEFAULT_FORM;
    my $msg = "";
    my %mygroups = ();
    my ( $u, $g );
    my ( @problems ) = ();
    my @toprint;
    my( @startlist ) =
	( &can_cgroup
	? &dbget($ACCOUNTDB,"groups")
	: &dbget($ACCOUNTDB,"users",$REALUSER,"groups")
	);
    foreach $g ( @startlist )
        {
	&dbget($ACCOUNTDB,"groups",$g,"inuse")
	    && $mygroups{$g}++;
	}

    $FORM{modrequest} ||= "";
    $FORM{switchuser} ||= "";

    if( $FORM{modrequest} eq "delete_user" )
	{
	&dbwrite( $ACCOUNTDB );
	&dbdel( $ACCOUNTDB, "users", $USER );
	&dbput( $ACCOUNTDB, "users", $USER, "inuse",0);
	&dbpop( $ACCOUNTDB );
	}
    elsif( $FORM{modrequest} eq "modify_user" )
	{
	my @changed_list = ();
	my $usertobe = $USER;
	if( &can_cuser() && $FORM{newuser} )
	    {
	    $usertobe = lc( $FORM{newuser} );
	    if( $usertobe !~ /^[a-z0-9\.\@_]+$/ )
		{ push( @changed_list, "Bad characters in new user name." ); }
	    }
	if( $FORM{newuser} ne "" && $FORM{password0} eq "" )
	    { push( @changed_list, "No password specified." ); }
	elsif( ($FORM{password0}||"")
	    ne ($FORM{password1}||"") )
	    { push( @changed_list, "XL(Password mismatch.)" ); }

	my @glist = split(',',$FORM{groups});

	if( &can_cuser() )
	    {
	    if( ! @glist )
		{ push( @changed_list, "No groups specified." ); }
	    elsif( grep( $mygroups{$_} eq "", @glist ) )
		{ push( @changed_list, "Bad group specified." ); }
	    }

	if( ! @changed_list )
	    {
	    $USER = $usertobe;
	    &dbwrite($ACCOUNTDB);
	    if( ! &can_cuser() )
		{
		if( $FORM{fullname} ne
		    &dbget($ACCOUNTDB,"users",$USER,"fullname") )
		    {
		    &dbput($ACCOUNTDB,"users",$USER,
			"fullname",$FORM{fullname});
		    push( @changed_list, "Full name updated." );
		    }
		if( $FORM{password0} ne "" )
		    {
		    &dbput( $ACCOUNTDB, "users", $USER,
			"password", $FORM{password0} );
		    push( @changed_list, "Password updated." );
		    }
		}
	    else
		{
		&dbadd($ACCOUNTDB,"users",$USER);
		&dbput($ACCOUNTDB,"users",$USER,
		    "inuse",1);
		&dbput($ACCOUNTDB,"users",$USER,
		    "password",$FORM{password0})
		    if( $FORM{password0} ne "" );
		&dbput($ACCOUNTDB,"users",$USER,
		    "groups",&dbarr(@glist));
		&dbput($ACCOUNTDB,"users",$USER,
		    "fullname",$FORM{fullname});
		push( @changed_list, "XL(User [[$USER]] updated)" );
		}

	    foreach my $fld ( @CONFIRM_FIELDS )
		{
		push( @changed_list,
		    &check_com_field( $USER, $fld ) );
		}
	    &dbpop( $ACCOUNTDB );
	    }
	$msg = join("<br>",@changed_list);
	}
    elsif( $FORM{modrequest} eq "add_group" )
	{
	if( ($FORM{groupname} ne "") && &can_cgroup )
	    {
	    my $g = &name_to_group( $FORM{groupname} );
	    if( &dbget($ACCOUNTDB,"groups",$g,"inuse") )
		{ $msg = "Group $g already in use.  Try another."; }
	    else
		{
		&dbwrite($ACCOUNTDB);
		&dbadd($ACCOUNTDB,"groups",$g);
		&dbput($ACCOUNTDB,"groups",$g,"inuse",1);
		&dbput($ACCOUNTDB,"groups",$g,"fullname",
		    $FORM{groupname});
		&dbpop( $ACCOUNTDB );
		}
	    }
	}
    elsif( $FORM{modrequest} eq "change_group" )
	{
	if( ($FORM{group} ne "") && &can_cgroup )
	    {
	    my $g = $FORM{group};
	    if( ! &dbget($ACCOUNTDB,"groups",$g,"inuse") )
		{ $msg = "Group $g not in use.  Try another."; }
	    else
		{
		&dbwrite($ACCOUNTDB);
		&dbadd($ACCOUNTDB,"groups",$g);
		&dbput($ACCOUNTDB,"groups",$g,"inuse",1);
		&dbput($ACCOUNTDB,"groups",$g,"fullname",
		    $FORM{groupname});
		&dbpop( $ACCOUNTDB );
		}
	    }
	}
    elsif( $FORM{modrequest} eq "delete_group" )
	{
	if( ($FORM{group} ne "") && &can_cgroup )
	    {
	    my $g = $FORM{group};
	    if( ! &dbget($ACCOUNTDB,"groups",$g,"inuse") )
		{ $msg = "No group called '$g'.  Try another."; }
	    else
		{
		&dbwrite($ACCOUNTDB);
		&dbdel($ACCOUNTDB,"groups",$g);
		&dbput($ACCOUNTDB,"groups",$g,"inuse","");
		&dbpop( $ACCOUNTDB );
		}
	    }
	}
    elsif( $FORM{modrequest} eq "payment"
	    && $FORM{topay} ne "" )
	{
	my $note;
	push( @problems, "XL(Illegal payment amount specified.)" )
	    if( $FORM{topay} !~ /^[ \$]*(\d+\.\d\d)$/ );
	my $paid = $1;
	$paid =~ s/^[ \$]*//g;
	if( $FORM{cardname} )
	    {
	    $_ = $FORM{cardnum};
	    if( /\*/ )
		{
		$FORM{cardnum} =
		    &dbget($ACCOUNTDB,"users",$USER,
		    "cardnum");
		$FORM{cardname} =
		    &dbget($ACCOUNTDB,"users",$USER,
		    "cardname");
		$FORM{cardexp} =
		    &dbget($ACCOUNTDB,"users",$USER,
		    "cardexp");
		$_ = $FORM{cardnum};
		}
	    s/[ \-]*//g;
	    if( /^\d\d\d\d\d\d\d\d\d\d\d\d(\d\d\d\d)$/ )
		{ $note="CC$1"; }
	    elsif( /^\d\d\d\d\d\d\d\d\d\d\d\d\d(\d\d\d\d)$/ )
		{ $note="CC$1"; }
	    else
		{
		push( @problems, "XL(Illegal card of credit number: [[$_]]" );
		}
	    $_ = $FORM{cardexp};
	    push( @problems,
		"XL(Illegal expiration date: [[$_]] [[1=$1, 2=$2]])." )
		if( ! /^(\d\d)\/(\d\d\d\d)$/			||
		    $1<1 || $1>12 || $2<2000 || $2>2100		);
	    push( @problems, "XL(Multiple methods of payment specified.)" )
		if( $FORM{checknum}
		    || $FORM{certnum}
		    || $FORM{usecash} );
	    }
	elsif( $FORM{checknum} )
	    {
	    push( @problems, "XL(Illegal check number.)" )
		if( $FORM{checknum} !~ /^\d[\d\-]*$/ );
	    push( @problems, "XL(Multiple methods of payment specified.)" )
		if( $FORM{certnum} || $FORM{usecash} );
	    $note = "CK$FORM{checknum}";
	    }
	elsif( $FORM{certnum} )
	    {
	    push( @problems, "XL(Illegal certificate number.)" )
		if( $FORM{certnum} !~ /^\d[\d\-]*$/ );
	    push( @problems, "XL(Multiple methods of payment specified.)" )
		if( $FORM{usecash} );
	    $note = "CN$FORM{certnum}";
	    }
	elsif( $FORM{usecash} )
	    { $note = "Cash"; }
	else
	    { push( @problems, "XL(No payment method specified.)" ); }
	if( @problems )
	    {
	    push( @toprint, "<h1>XL(Problems with your form:)</h1>\n" );
	    foreach $_ ( @problems )
		{ push(@toprint, "<dd><font color=red>$_</font>\n" ); }
	    push( @toprint, "<p>XL(Go back and correct these problems.)\n" );
	    &xprint( @toprint );
	    exit(0);
	    }
	my( $ind ) = $TODAY;
	&dbwrite($DB);
	&dbadd($DB,"users",$USER,"days",
	    $TODAY,"payments",$ind);
	&dbput($DB,"users",$USER,"days",
	    $TODAY,"payments",$ind,"note",$note);
	&dbput($DB,"users",$USER,"days",
	    $TODAY,"payments",$ind,"paid",$paid);
	&dbpop($DB);
	if( $FORM{cardonfile} )
	    {
	    &dbwrite($ACCOUNTDB);
	    &dbput($ACCOUNTDB,"users",$USER,
	        "cardnum",$FORM{cardnum});
	    &dbput($ACCOUNTDB,"users",$USER,
	        "cardexp",$FORM{cardexp});
	    &dbput($ACCOUNTDB,"users",$USER,
	        "cardname",$FORM{cardname});
	    &dbpop($ACCOUNTDB);
	    }
	}

    @startlist =
	( &can_cgroup
	? &dbget($ACCOUNTDB,"groups")
	: &dbget($ACCOUNTDB,"users",$REALUSER,"groups")
	);
    %mygroups = ();
    foreach $g ( @startlist )
        {
	&dbget($ACCOUNTDB,"groups",$g,"inuse")
	    && $mygroups{$g}++;
	}
    my $pname = $FULLNAME || $USER;

    my %thisusergroup = ();
    grep( $thisusergroup{$_}="selected",
	&dbget($ACCOUNTDB,"users",$USER,"groups") );

    push( @toprint, <<EOF );
<script>
function switchuserfnc()
    {
    with ( window.document.$form_admin )
        {
	if( switchuser.options[ switchuser.selectedIndex ].value != "*" )
	    {
	    USER.value = switchuser.options[ switchuser.selectedIndex ].value;
	    }
	modrequest.value = "";
	submit();
	}
    }
</script>
<title>${pname}'s $PROG XL(Administration Page)</title>
<body $BODY_TAGS>
$HELP_IFRAME
<center><form name=$form_admin method=post>
<h1>$msg</h1>
<input type=hidden name=SID value=$SID>
<input type=hidden name=USER value=$FORM{USER}>
<input type=hidden name=func value=$FORM{func}>
<input type=hidden name=modrequest value="">
<input type=hidden name=group value="">
<input type=hidden name=groupname value="">
<table border=1 $TABLE_TAGS><tr>
<th valign=top><table border=0>
EOF
    my $fullname =
	&dbget($ACCOUNTDB,"users",
	    $USER,"fullname");
    if( $FORM{switchuser} eq "*" )
        {
	push( @toprint, <<EOF );
<tr><th align=left>XL(New user ID:)</th>
    <td><input type=text autocapitalize=none name=newuser size=10></td></tr>
<tr><th align=left>XL(Entire name:)</th>
    <td><input type=text autocapitalize=words name=fullname size=30></td></tr>
EOF
	}
    elsif( &can_suser() )
	{
	push( @toprint, <<EOF );
<tr><th align=left>XL(User ID:)</th>
    <td><select name=switchuser onChange='switchuserfnc();'>
EOF
	push( @toprint, "<option value=*>XL(Create new user)\n" )
	    if( &can_cuser() );
	my %selflag = ( $USER, " selected" );
	my $cgprivs = &can_cgroup();
	foreach $u ( &all_users() )
	    {
	    next if( ! &dbget($ACCOUNTDB,"users",$u,"inuse") );
	    my $found_group = $cgprivs;
	    if( ! $found_group )
		{
		$found_group++
		    if( grep($mygroups{$_},
		        &dbget($ACCOUNTDB,
			    "users",$u,"groups")) );
		}
	    if( $found_group )
		{
		$_ = &dbget($ACCOUNTDB,"users",$u,"fullname");
		push( @toprint,
		    "<option",
		        ($selflag{$u}||""),
			" value=\"$u\">$u - $_</option>\n" );
		}
	    }
    	push( @toprint, <<EOF );
    </select></td></tr>
<tr><th align=left>XL(Entire name:)</th>
    <td><input type=text autocapitalize=words name=fullname value="$fullname" size=30></td></tr>
EOF
	}
    else
        {
    	push( @toprint, <<EOF );
<tr><th align=left>XL(User ID:)</th><td>$USER</td></tr>
<tr><th align=left>XL(Entire name:)</th><td><input type=text autocapitalize=words name=fullname value="$fullname" size=30></td></tr>
EOF
	}
#<tr><th align=left>XL(Entire name:)</th><td>$FULLNAME</td></tr>
    my %current = ();
    my %confirmed = ();
    foreach my $fld ( @CONFIRM_FIELDS )
        {
	$current{$fld} = &dbget($ACCOUNTDB,"users",$USER,$fld);
	my $lf = &dbget($ACCOUNTDB,"users",$USER,"last".$fld) || "";
	if( ! $current{$fld} )
	    { $confirmed{$fld} = ""; }
	elsif( ($current{$fld}||"") eq $lf )
	    { $confirmed{$fld} = "(Confirmed)"; }
	else
	    { $confirmed{$fld} = "(Unconfirmed)"; }
	}
    push( @toprint, <<EOF );
<tr><th align=left>XL(Password:)</th>
    <td><input type=password name=password0 size=12></td>
    </th></tr>
<tr><th align=left>XL(Password repeated:)</th>
    <td><input type=password name=password1 size=12></td></tr>
EOF
    foreach my $fld ( @CONFIRM_FIELDS )
        {
	push( @toprint, "<tr><th align=left valign=top>XL($FLDESC{$fld}{prompt}:)</th><td>",
	    ( ( $FLDESC{$fld}{rows} && $FLDESC{$fld}{rows}>1 )
	    ? "<textarea cols=$FLDESC{$fld}{cols} rows=$FLDESC{$fld}{rows} name=$fld >$current{$fld}</textarea>"
	    : "<input type=text name=$fld autocapitalize=none size=$FLDESC{$fld}{cols} value='$current{$fld}'>"
	    ),
	    "XL($confirmed{$fld})</td></tr>" )
	    if( $FLDESC{$fld}{ask} );
	}
    if( &can_cuser )
	{
	push( @toprint, "<tr><th align=left>XL(Groups:)</th>\n" );
	$_ = 10 if( ($_ = scalar( keys %mygroups )) > 10 );
	push( @toprint, "<td><select name=groups multiple size=$_>\n" );
	foreach $g ( sort keys %mygroups )
	    {
	    push( @toprint,
		"<option value=\"$g\" ".($thisusergroup{$g}||"").">",
	        &group_to_name($g) . "\n" );
	    }
	push( @toprint, <<EOF );
</select></td></tr>
EOF
	}
    $_ = (  ( $FORM{switchuser} eq "*" )
	    ? "XL(Create new user)"
	    : "XL(Modify) $USER" );
    push( @toprint, <<EOF );
<tr><th colspan=2><input type=button value="$_" onClick='document.$form_admin.modrequest.value="modify_user";submit();'>
EOF
    push( @toprint, <<EOF ) if( ( $FORM{switchuser} ne "*" ) && &can_cuser );
<input type=button value="XL(Delete [[$USER]])" onClick='document.$form_admin.modrequest.value="delete_user";submit();'>
EOF
    push( @toprint, <<EOF );
    </th></tr>
<tr><th colspan=2>&nbsp;</th></tr>
<tr><th align=left>XL(Enter activation code:)</th>
    <td><input type=text autocapitalize=none name=activation_code onChange='submit();'></td></tr>
</table></th>
EOF

    if( $PAYMENT_SYSTEM )
        {
	my($sec,$min,$hour,$mday,$month,$year) = localtime(time);
	my( $topay, $weight, $cardname, $cardnum, $cardonfile, $checknum, $certnum, $usecash );
	my $expselect = "";

	$cardname = &dbget($ACCOUNTDB,"users",$USER,
			"cardname");
	$cardnum = &dbget($ACCOUNTDB,"users",$USER,
			"cardnum");
	$_ = length( $cardnum );
	$cardnum = "************".substr($cardnum,$_-4,4);
	my %selflag = ( &dbget($ACCOUNTDB,"users",
			    $USER,"cardexp"), " selected" );

	for( $_=0; $_<48; $_++ )
	    {
	    my $dstr = sprintf("%02d/%d",$month,$year+1900);
	    $expselect .= "<option".($selflag{$dstr}||"")." value=$dstr>$dstr\n";
	    if( ++$month > 12 )
	        {
		$month = 1;
		$year++;
		}
	    }
	push( @toprint, <<EOF );
<th valign=top><table>
<tr><th align=left>XL(To pay:)</th>
    <td><input type=text name=topay autocapitalize=none value="$topay" size=6></td></tr>
<tr><th colspan=2>&nbsp;</th></tr>
<tr><th align=left>XL(Name on credit card:)</th>
    <td><input type=text name=cardname autocapitalize=words value="$cardname" size=20></td></tr>
<tr><th align=left>XL(Credit card number:)</th>
    <td><input type=text name=cardnum value="$cardnum">
    </td></tr>
<tr><th align=left>XL(Expiration:)</th><td><select name=cardexp>
$expselect
</select>
&nbsp;&nbsp;<b>Save:</b>
<input type=checkbox name=cardonfile $cardonfile></td></tr>
<tr><th colspan=2>XL(OR)</th></tr>
<tr><th align=left>XL(Number on the Cheque:)</th>
    <td><input type=text name=checknum value="" size=10></td></tr>
<tr><th colspan=2>XL(OR)</th></tr>
<tr><th align=left>XL(Number on the Certificate:)</th>
    <td><input type=text name=certnum value="" size=10></td></tr>
<tr><th colspan=2>XL(OR)</th></tr>
<tr><th align=left>XL(Cash:)</th>
    <td><input type=checkbox name=usecash $usecash></td></tr>
<tr><th colspan=2><input type=button
    onClick='document.$form_admin.modrequest.value="payment";submit();'
    value="XL(Complete the payment)"></th></tr>
</table></th>
EOF
	}

    if( &can_cgroup )
        {
	push( @toprint, <<EOF );
<th valign=top><table>
<tr><th align=left>XL(Create group:)</th>
    <td><input type=text autocapitalize=words value="" size=10
	onChange='document.$form_admin.groupname.value=this.value;document.$form_admin.modrequest.value="add_group";submit();'></td>
	<td></td>
</tr>
EOF
	foreach my $g ( &groups() )
	    {
	    push( @toprint,
		"<tr><th align=left>$g</th><td>",
		"<input type=text autocapitalize=words size=10 value=\"",
	        &group_to_name( $g ),
	        "\" onChange='document.$form_admin.group.value=\"$g\";document.$form_admin.groupname.value=this.value;document.$form_admin.modrequest.value=\"change_group\";submit();'>",
	        "</td><td><input type=button value=\"XL(Delete)\" ",
	        "onClick='document.$form_admin.modrequest.value=\"delete_group\";document.$form_admin.group.value=\"$g\";submit();'>",
	        "</td></tr>\n" );
	    }
	push( @toprint, "</table></th>" );
	}

    push( @toprint, "<td valign=top>" . &who() . "</td>" );

    push( @toprint, "</tr></table></form>\n" );
    &xprint( @toprint );
    &main::footer("admin") if( exists(&main::footer) );;
    &cleanup(0);
    }

#########################################################################
#	Useful for logout select in footer.				#
#########################################################################
sub logout_select
    {
    my( $form_logout, $submit_func ) = @_;
    $form_logout ||= $DEFAULT_FORM;
    $submit_func ||= "submit_func";
    my $script_prefix = $ENV{SCRIPT_NAME};
    $script_prefix =~ s:\?.*::;
    $script_prefix =~ s:index.cgi::;
    $script_prefix =~ s:[^/]*/$::;
    my $logoutfnc = 
	"if(this.value==\"logout\") {$submit_func(this.value);} else {window.document.$form_logout.action=\"$script_prefix\"+this.value;window.document.$form_logout.submit();}";
    my @s = ("<select name=new_prog help='COMMON_select_program' onChange='$logoutfnc'>\n");

    my %seen_cgs =
        map { $_, 1 }
	    grep( &in_group($USER,&name_to_group("can_run_$_")),
		grep( -x "../$_/index.cgi", &files_in("..","^\\w") ) );
    $seen_cgs{$PROG}=1;

    foreach my $prog ( sort keys %seen_cgs )
	{
        push( @s, "<option value=$prog",
	    ( $prog eq $PROG ? " selected" : "" ),
	    ">$prog</option>\n" );
	}
    push( @s, "<option value=logout>XL(Logout)</option></select>\n" );

    return join("",@s);
    }

1;
