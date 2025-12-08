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

package cpi_user;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( all_prog_users all_users can
 can_cgroup can_cuser can_suser check_com_field group_to_name
 groups groups_of_user handle_invitations in_group invite
 login logout logout_select name_to_group read_sid user_can
 user_name users_in_group who );
use lib ".";

use cpi_cgi qw( CGIheader );
use cpi_compress_integer qw( compress_integer );
use cpi_db qw( dbadd dbarr dbdel dbget dbpop dbput dbwrite dbisin );
use cpi_file qw( cleanup autopsy files_in read_lines write_file
 write_lines );
use cpi_log qw( log );
use cpi_send_file qw( send_via );
use cpi_translate qw( gen_language_params xlate xprint );
use cpi_hash qw( match_password salted_password );
use cpi_vars;
use Captcha::reCAPTCHA;
#__END__
1;
#########################################################################
#	Return if user has a particular attribute			#
#########################################################################
sub user_can
    {
    return &dbisin($cpi_vars::ACCOUNTDB,"users",$cpi_vars::REALUSER,
	"groups",@_);
    }

sub can_cuser	{ return &user_can("create_user"); }
sub can_suser	{ return &user_can("create_user"); }
sub can_cgroup	{ return &user_can("create_group"); }

#########################################################################
#	Turn text into a token that can be used as a group.		#
#	Could ALMOST do this with cpi_filename::text_to_filename	#
#	except it gets rid of more characters and result is always	#
#	lower case.							#
#		lc( &cpi_file::text_to_filename( x ) )			#
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
    unlink( "$cpi_vars::SIDDIR/$cpi_vars::SID" );
    &log("$cpi_vars::REALUSER logs out from SID $cpi_vars::SID.");
    }

#########################################################################
#	Handle invitations						#
#########################################################################
sub handle_invitations
    {
    my( @msgs ) = ();
    my $written = 0;
    if( $cpi_vars::FORM{activation_code} )
	{
	foreach my $activation_code ( split(/,/,$cpi_vars::FORM{activation_code}) )
	    {
	    my $found_activation_code = 0;
	    foreach my $fld ( @cpi_vars::CONFIRM_FIELDS )
		{
		my $ccode = &dbget($cpi_vars::ACCOUNTDB,
		    "users",$cpi_vars::REALUSER,"confirm$fld");
		if( $ccode eq $activation_code )
		    {
		    my $val = &dbget($cpi_vars::ACCOUNTDB,"users",$cpi_vars::REALUSER,$fld);
		    &dbwrite( $cpi_vars::ACCOUNTDB ) if( $written++ == 0 );
		    &dbput($cpi_vars::ACCOUNTDB,"users",$cpi_vars::REALUSER,
		        "last".$fld,$val);
		    $found_activation_code = 1;
		    push( @msgs, "XL($fld confirmed as) $val." );
		    last;
		    }
		}
	    next if( $found_activation_code );
	    my $action_string =
		&dbget($cpi_vars::ACCOUNTDB,
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
		&dbwrite( $cpi_vars::ACCOUNTDB ) if( $written++ == 0 );
		&dbput($cpi_vars::ACCOUNTDB,
		    "invitations",$activation_code,"used");
		&invitation_handler( split($cpi_vars::DBSEP,$action_string) );
		}
	    }
	}
    &dbpop( $cpi_vars::ACCOUNTDB ) if( $written );
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
    ( $cpi_vars::REALUSER, $cpi_vars::LANG ) = &read_lines($fname);
    }

#########################################################################
#	Write the variables into the SID file.				#
#########################################################################
sub write_sid
    {
    my( $fname ) = @_;
    &write_lines( $fname,
	$cpi_vars::REALUSER,
	$cpi_vars::LANG
	);
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
    $form_login ||= $cpi_vars::DEFAULT_FORM;
    my $msg = "";
    my $fname;
    my @toprint;
    my $check_group = &name_to_group( $cpi_vars::PROG . " user" );

    if( ! -d $cpi_vars::SIDDIR )
        {
        system("mkdir -p $cpi_vars::SIDDIR");
	chmod( 0777, $cpi_vars::BASEDIR, $cpi_vars::SIDDIR );
	}

    $cpi_vars::ANONYMOUS =
        (   $cpi_vars::anonymous_user			&&
	    defined($cpi_vars::FORM{user})		&&
	    $cpi_vars::FORM{user} eq $cpi_vars::anonymous_user	);

    $cpi_vars::FORM{func}="" if( ! defined( $cpi_vars::FORM{func} ) );

    if( $cpi_vars::FORM{func} ne "dologin" )
	{
	my ( $primary_func ) = split(/,/,$cpi_vars::FORM{func});
	if( $cpi_vars::anonymous_funcs
	 && grep( $_ eq $primary_func, split(/,/,$cpi_vars::anonymous_funcs) ) )
	    {
	    $cpi_vars::SID = ( $cpi_vars::anonymous_user || "anonymous" );
	    $cpi_vars::USER = $cpi_vars::SID;
	    $cpi_vars::ANONYMOUS = 1;
	    &CGIheader();
	    return;
	    }
	$cpi_vars::SID = ($cpi_vars::FORM{SID} || "");
	$cpi_vars::SID = $1
	    if( ($cpi_vars::SID eq "")
		&& $ENV{HTTP_COOKIE}
		&& defined( $cpi_vars::SIDNAME )
		&& ($ENV{HTTP_COOKIE} =~ /$cpi_vars::SIDNAME=(\w+)/ ));
	if( $cpi_vars::SID )
	    {
	    if( $cpi_vars::SID =~ /RT_/ )
		{
		&CGIheader();
		return;
		}
	    elsif( ! -r "$cpi_vars::SIDDIR/$cpi_vars::SID" )
	        {
		&log("$cpi_vars::SIDDIR/$cpi_vars::SID removed.");
		undef $cpi_vars::SID;
		}
	    }
	}

    if( defined($cpi_vars::SID) && $cpi_vars::SID ne "" )
        {	# Form claims user already logged in.  We'll see ...
	if( exists &app_dependent_login && &app_dependent_login() )
	    {	# For hat.cgi, probably should get rid of this.
	    &CGIheader();
	    return;
	    }
	elsif( $cpi_vars::SID !~ /^[A-Za-z0-9]+$/ )	# SID correct format?
	    { $msg = "XL(Corrupt SID [[$cpi_vars::SID]].  Please identify yourself definitively.)"; }
	elsif( ! -r "$cpi_vars::SIDDIR/$cpi_vars::SID" )	# SID actually exist?
	    { $msg = "XL(User session has timed out and been removed.  Please identify yourself definitively again.)"; }
	elsif( $cpi_vars::FORM{func} eq "logout" )	# Oops, he's actually
	    {						# logging out.  Nuke
	    if( !defined($cpi_vars::FORM{new_prog})
		|| $cpi_vars::FORM{new_prog} eq "logout" )
		{
		&read_sid( "$cpi_vars::SIDDIR/$cpi_vars::SID" );
		&logout();
		$msg = "XL(Please identify yourself definitively.)";
		}
	    else
	        {
		my $newprog = $ENV{REQUEST_URI};
		#$newprog =~ s+/$cpi_vars::PROG.cgi.*+/$cpi_vars::FORM{new_prog}.cgi+;
		$newprog =~ s+/$cpi_vars::PROG\b+/$cpi_vars::FORM{new_prog}+;
		&CGIheader();
		print "<meta http-equiv=\"refresh\" content=\"0;url=$newprog?SID=$cpi_vars::SID\">";
		&cleanup(0);
		}
	    }
	else	# If we're here, we have a legitimate SID.
	    {	# Check if it's not too old.
	    $fname = "$cpi_vars::SIDDIR/$cpi_vars::SID";
	    my( $st_ino, $st_dev, $st_mode, $st_nlink,
		$st_uid, $st_gid, $st_rdev, $st_size, $st_atime, $st_mtime,
		$st_ctime, $st_blksize, $st_blocks) = lstat( $fname );
	    if( (time - $st_mtime) > $cpi_vars::LOGIN_TIMEOUT )
	        { $msg="XL(User session has timed out.  Please identify yourself definitively again.)"; }
	    else	# Wow a real live logged in user.  Read user info from
		{	# SID file.
		&read_sid( $fname );
		$cpi_vars::ANONYMOUS = ( $cpi_vars::anonymous_user && $cpi_vars::REALUSER eq $cpi_vars::anonymous_user );
		if( ! $cpi_vars::anonymous_user &&
		    ! $cpi_vars::allow_account_creation &&
		    ! &in_group($cpi_vars::REALUSER,$check_group)	)
		    {	# Verify group still exists...
		    $msg="XL(User [[{$cpi_vars::REALUSER}]] is not a member of group [[".
			&group_to_name($check_group)."]].)";
		    }
		}
	    }
	}
    else	# If we're here, we're actually in the login process.
        {	# We'll check his answers and if they aren't sufficient
		# Prompt him again.
	my $captresult = "";
	if( $cpi_vars::require_captcha					&&
	    (	! $cpi_vars::FORM{create_account} || $cpi_vars::FORM{emailcode} ) )
	    {
	    if( $cpi_vars::FORM{recaptcha_challenge_field}	&&
	        $cpi_vars::FORM{recaptcha_response_field}		)
		{
		my $captchaptr = Captcha::reCAPTCHA->new;
		$cpi_vars::KEY_CAPTCHA_PRIVATE if(0);	# Get rid of "only used once" warning
		my $captresultptr = $captchaptr->check_answer
		    (
		    $cpi_vars::KEY_CAPTCHA_PRIVATE,
		    $ENV{'REMOTE_ADDR'},
		    $cpi_vars::FORM{recaptcha_challenge_field},
		    $cpi_vars::FORM{recaptcha_response_field}
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
	$cpi_vars::FORM{user} = lc($cpi_vars::FORM{user}||"");	# Tokenize the account name
#	$cpi_vars::FORM{user} = "chris"
#	    if( $cpi_vars::FORM{user} eq "chris.interim\@gmail.com" );
	$cpi_vars::FORM{user} =~ s/[^\w]+/_/g;
	$cpi_vars::FORM{user} =~ s/^_+//;
	$cpi_vars::FORM{user} =~ s/_+$//;
	if( $captresult )
	    {
	    $msg = "XL(Problem verifying text of picture:  [[$captresult]].)";
	    #$msg .= "<br>Challenge:  $cpi_vars::FORM{recaptcha_challenge_field}";
	    #$msg .= "<br>Response:  $cpi_vars::FORM{recaptcha_response_field}";
	    }
	elsif( $cpi_vars::FORM{user} eq "" )
	    {
	    if( $cpi_vars::FORM{create_account} )
	        { $msg = "XL(Please enter information for new account.)"; }
	    else
	        { $msg = "XL(Please identify yourself definitively.)"; }
	    }
	elsif( !$cpi_vars::ANONYMOUS && ($cpi_vars::FORM{password}||"") eq "" )
	    { $msg = "XL(Must specify password.)"; }
	else
	    {
	    my $let_him_in = $cpi_vars::ANONYMOUS;
	    my $new_password_encrypted;
	    if( ! $let_him_in )
		{
		my $oldp = &dbget($cpi_vars::ACCOUNTDB,"users",
				$cpi_vars::FORM{user},"password");
		print STDERR "Checking A=$cpi_vars::ACCOUNTDB U=$cpi_vars::FORM{user} o=[$oldp]\n";
		if( $oldp eq "" )
		    {
		    if( ! $cpi_vars::FORM{create_account} )
			{ $msg = "XL(There are problems with these credentials.  Please identify yourself definitively again.)"; }
		    elsif( $cpi_vars::FORM{password} ne $cpi_vars::FORM{password1} )
			{ $msg = "XL(Both specified passwords must be the same.)"; }
#		    elsif( $cpi_vars::FORM{user} !~ /^[a-z][a-z0-9]*$/ )
#		        { $msg = "XL(Account must be all lower case or digits and start with a letter.)"; }
		    elsif( $cpi_vars::FORM{user} !~ /[a-z].*[a-z]/ )
			{ $msg = "XL(Account must have two letters.)"; }
		    else
			{
			&dbwrite( $cpi_vars::ACCOUNTDB );
			&dbadd( $cpi_vars::ACCOUNTDB,
			    "users", $cpi_vars::FORM{user} );
			&dbput( $cpi_vars::ACCOUNTDB,
			    "users", $cpi_vars::FORM{user},
			    "password", &salted_password( $cpi_vars::FORM{password} ) );
			&dbput( $cpi_vars::ACCOUNTDB,
			    "users", $cpi_vars::FORM{user}, "inuse", 1 );
			&dbput($cpi_vars::ACCOUNTDB,"users",$cpi_vars::FORM{user},
			    "fullname",$cpi_vars::FORM{fullname})
			    if( $cpi_vars::require_fullname );
			&dbput( $cpi_vars::ACCOUNTDB,
			    "users", $cpi_vars::FORM{user}, "groups", $check_group );
			foreach my $fld ( @cpi_vars::CONFIRM_FIELDS )
			    {
			    &check_com_field($cpi_vars::FORM{user},$fld)
			        if( $cpi_vars::FLDESC{$fld}{ask} );
			    }
			&dbpop( $cpi_vars::ACCOUNTDB );
			&log("Creating user $cpi_vars::FORM{user} in group $check_group.");
			$let_him_in = 1;
			}
		    }
		elsif( ! ($new_password_encrypted=&match_password($cpi_vars::FORM{password},$oldp)) )
		    { $msg = "XL(There are problems with these credentials.  Please identify yourself definitively again.)"; }
		elsif( ! $cpi_vars::allow_account_creation &&
		    ! &in_group($cpi_vars::FORM{user},$check_group) )
		    {
		    $msg="XL(User [[$cpi_vars::FORM{user}]] is not a member of group [[".
			&group_to_name($check_group). "]].)";
		    }
		else
		    {
		    $let_him_in = 1;
		    if( $new_password_encrypted && ( $new_password_encrypted ne $oldp ) )
		        {
			# This happens when the password system has a preferred method
			# of encryption, we'll update it.
#			print STDERR "Updating $cpi_vars::FORM{user} password from ",
#			    &dbget( $cpi_vars::ACCOUNTDB, "users",
#				$cpi_vars::FORM{user},"password"), " to ",
#				$new_password_encrypted, ".\n";
			&dbwrite( $cpi_vars::ACCOUNTDB );
			&dbput( $cpi_vars::ACCOUNTDB, "users", 
				$cpi_vars::FORM{user},"password",
				$new_password_encrypted );
			&dbpop( $cpi_vars::ACCOUNTDB );
			}
		    }
		}
	    if( $let_him_in )
		{
		$cpi_vars::SID = &compress_integer( rand() );
		$fname = "$cpi_vars::SIDDIR/$cpi_vars::SID";
		$cpi_vars::REALUSER = $cpi_vars::FORM{user};
		&write_sid( $fname );
		&CGIheader( $cpi_vars::SIDNAME, $cpi_vars::SID );
		&log("$cpi_vars::REALUSER logs in in $cpi_vars::LANG with SID ${cpi_vars::SID}.");
		$msg = "";
		}
	    }
	}

    &CGIheader();

    if( $msg )
        {
	&log( ($cpi_vars::FORM{user}||"?") . ":  $msg" );
	my $langstring=($cpi_vars::preset_language ? "" : &gen_language_params());
	push( @toprint, <<EOF );
<title>$msg</title><body $cpi_vars::BODY_TAGS><center>
<form name=$form_login method=post>
<input type=hidden name=func value=dologin>
<table border=1 $cpi_vars::TABLE_TAGS><tr><th colspan=2>$msg</th></tr>
EOF
	push( @toprint,
	    ( $cpi_vars::ANONYMOUS
	    ? <<EOF
<input type=hidden name=user value="$cpi_vars::FORM{user}">
<input type=hidden name=password value="$cpi_vars::FORM{user}">
EOF
	    : <<EOF ) );
$cpi_vars::HELP_IFRAME
<tr help='COMMON_account_name'><th align=left>XL(Account name:)</th>
    <td><input type=text name=user autocapitalize=none value="$cpi_vars::FORM{user}" autocapitalize=none></td></tr>
<tr help='COMMON_account_password'><th align=left>XL(Password:)</th>
    <td><input type=password name=password></td></tr>
EOF
	if( $cpi_vars::FORM{create_account} )
	    {
	    push( @toprint, <<EOF );
<tr help='COMMON_account_password_retyped'><th align=left>XL(Retype password:)</th>
    <td><input type=password name=password1></td></tr>
EOF
	    push( @toprint, <<EOF ) if( $cpi_vars::require_fullname );
<tr><th align=left>XL(Full name:)</th>
    <td><input type=text help='COMMON_account_fullname' name=fullname autocapitalize=words value="$cpi_vars::FORM{fullname}"></td></tr>
EOF
	    foreach my $fld ( @cpi_vars::CONFIRM_FIELDS )
	        {
		push( @toprint, "<tr><th align=left valign=top>XL(Enter valid $cpi_vars::FLDESC{$fld}{prompt}:)</th><td>",
		    ( ( $cpi_vars::FLDESC{$fld}{rows} && $cpi_vars::FLDESC{$fld}{rows}>1 )
		    ? "<textarea help='COMMON_account_$fld' cols=$cpi_vars::FLDESC{$fld}{cols} rows=$cpi_vars::FLDESC{$fld}{rows} name=$fld >".$cpi_vars::FORM{$fld}."</textarea>"
		    : "<input type=text autocapitalize=none help='COMMON_account_$fld' name=$fld size=$cpi_vars::FLDESC{$fld}{cols} value='".$cpi_vars::FORM{$fld}."'>"
		    ), "</td></tr>" )
		    if( $cpi_vars::FLDESC{$fld}{req} );
		}
	    }
	push( @toprint, $langstring );
	if( $cpi_vars::require_captcha )
	    {
	    push( @toprint, "<tr help='COMMON_account_captcha'><th colspan=2><center>" );
	    my $captchaptr = Captcha::reCAPTCHA->new;
	    $cpi_vars::KEY_CAPTCHA_PUBLIC if(0);		# Get rid of "only used once" warning
	    push( @toprint, $captchaptr->get_html( $cpi_vars::KEY_CAPTCHA_PUBLIC ) );
	    push( @toprint, "</center></th></tr>" );
	    }
	push( @toprint, <<EOF );
<tr help='COMMON_account_session'><th colspan=2><input type=submit value="XL(Begin session)"></th></tr>
EOF
	if( $cpi_vars::allow_account_creation &&
	    (!defined($cpi_vars::FORM{user}) ||
		$cpi_vars::FORM{user} ne "anonymous") )
	    {
	    if( ! $cpi_vars::FORM{create_account} )
	        { push( @toprint, "<tr help='COMMON_account_create'><th colspan=2><input type=submit name=create_account value=\"XL(Create account)\"></th></tr>" ); }
	    }
	push( @toprint, "</table>\n" );
	my $vn;
	foreach $vn ( keys %cpi_vars::FORM )
	    {
	    push(@toprint,"<input type=hidden name=$vn value=\"$cpi_vars::FORM{$vn}\">\n")
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
    $cpi_vars::USER = $cpi_vars::REALUSER;
    $cpi_vars::FORM{USER} = $cpi_vars::USER
	if( !defined($cpi_vars::FORM{USER}) || $cpi_vars::FORM{USER} eq "" );
    if( $cpi_vars::FORM{USER} ne $cpi_vars::REALUSER )
        {
	$cpi_vars::FORM{USER} = lc($cpi_vars::FORM{USER});
	if( $cpi_vars::FORM{USER} !~ /^[a-z0-9\.\@]+$/ )
	    { &autopsy("$cpi_vars::FORM{USER} contains illegal characters."); }
	elsif( ! &dbget($cpi_vars::ACCOUNTDB,"users",$cpi_vars::FORM{USER},"inuse") )
	    { &autopsy("$cpi_vars::FORM{USER} does not exist"); }
	elsif( ! &can_suser() )
	    { &autopsy("$cpi_vars::REALUSER cannot switch users from [$cpi_vars::REALUSER] to [$cpi_vars::FORM{USER}]."); }
	else
	    {
#	    my %seen = ();
#	    grep( $seen{$_}++, &dbget($cpi_vars::ACCOUNTDB,"users",$cpi_vars::REALUSER,"groups") );
#	    if(! grep($seen{$_} > 0, &dbget($cpi_vars::ACCOUNTDB,"users",$cpi_vars::FORM{USER},"groups")))
#	        { &autopsy("$cpi_vars::FORM{USER} is not in any of your groups."); }
#	    else
		{ $cpi_vars::USER=$cpi_vars::FORM{USER}; }
	    }
	}
    $cpi_vars::FULLNAME = &dbget($cpi_vars::ACCOUNTDB,"users",$cpi_vars::USER,"fullname");
    }

#########################################################################
#	Determine if the current user is a member of the specified	#
#########################################################################
sub can
    {
    my( $priv ) = @_;
    return grep( $priv eq $_, &dbget($cpi_vars::ACCOUNTDB,"users",$cpi_vars::REALUSER,"groups") );
    }

#########################################################################
#	Return full name of a user					#
#########################################################################
sub user_name
    {
    my( $u ) = @_;
    return (&dbget($cpi_vars::ACCOUNTDB,"users",$u,"fullname") || $u);
    }

#########################################################################
#	Return full name of a group					#
#########################################################################
sub group_to_name
    {
    my( $g ) = @_;
    return (&dbget($cpi_vars::ACCOUNTDB,"groups",$g,"fullname") || $g);
    }

#########################################################################
#	Returns list of all non deleted users.				#
#########################################################################
sub all_users
    {
    my @ret = ();
    foreach my $u ( &dbget($cpi_vars::ACCOUNTDB,"users") )
	{
	&dbget($cpi_vars::ACCOUNTDB,"users",$u,"inuse") && push(@ret,$u);
	}
    return sort @ret;
    }

#########################################################################
#	Return a list of all the users who can run this program.	#
#########################################################################
sub all_prog_users
    {
    my $check_group = &name_to_group( $cpi_vars::PROG . " user" );
    return
	grep(
	    &dbget($cpi_vars::ACCOUNTDB,"users",$_,"inuse")
	    && &in_group($_,$check_group),
	    &all_users() );
    }

#########################################################################
#	Return list of non deleted groups.				#
#########################################################################
sub groups()
    {
    my( @ret ) = ();
    foreach my $g ( &dbget($cpi_vars::ACCOUNTDB,"groups" ) )
	{
        &dbget($cpi_vars::ACCOUNTDB,"groups",$g,"inuse") &&
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
    foreach my $g ( &dbget($cpi_vars::ACCOUNTDB,"users",$u,"groups" ) )
	{
        &dbget($cpi_vars::ACCOUNTDB,"groups",$g,"inuse") &&
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
	&dbget($cpi_vars::ACCOUNTDB,"users",$uname,"groups"));
    }

#########################################################################
#	Returns list of all non-deleted users in group.			#
#	If no group specified, assume group of people who can use this	#
#	application.							#
#########################################################################
sub users_in_group
    {
    my( $l4 ) = @_;
    $l4 = &name_to_group("$cpi_vars::PROG user")
	if( ! defined($l4) );
    return grep( &in_group($_,$l4), &all_users() );
    }

1;

#########################################################################
#	Return an HTML table of who's used the system recently.		#
#########################################################################
sub who
    {
    my @dirs = grep(/^[^\.]/,&files_in( $cpi_vars::SIDDIR ) );
    my %results = ();
    foreach my $sidfile ( @dirs )
        {
	my $fname = "$cpi_vars::SIDDIR/$sidfile";
	my( $st_ino, $st_dev, $st_mode, $st_nlink,
	    $st_uid, $st_gid, $st_rdev, $st_size, $st_atime, $st_mtime,
	    $st_ctime, $st_blksize, $st_blocks) = lstat( $fname );
	my $inactivity = time - $st_mtime;
	if( $inactivity <= $cpi_vars::LOGIN_TIMEOUT )
	    {
	    my( $user, $lang ) = &read_lines($fname);
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
    &dbwrite( $cpi_vars::ACCOUNTDB );
    &dbput( $cpi_vars::ACCOUNTDB, "invitations",
	$new_code, &dbarr(@parts) );
    &dbpop( $cpi_vars::ACCOUNTDB );
    &send_via( $means, $cpi_vars::DAEMON_EMAIL, $address,
        &xlate("XL(Invitation)"),
	"$msg\n$cpi_vars::URL?func=admin&activation_code=$new_code"
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
    my $lastval=&dbget($cpi_vars::ACCOUNTDB,"users",$user,$fld)||"";
    if( $lastval ne ($cpi_vars::FORM{$fld}||"") )
	{
	&dbput($cpi_vars::ACCOUNTDB,
	    "users",$user,$fld,$cpi_vars::FORM{$fld});
	my $new_code = "c" . &compress_integer( rand() );
	&dbput($cpi_vars::ACCOUNTDB,
	    "users",$user,"confirm$fld",$new_code);
	my $conmsg = &xlate(<<EOF);
XL(This message was sent to you by the $cpi_vars::PROG server to verify that
the $fld information you gave it was correct.)

XL(To confirm that it is, login to the $cpi_vars::PROG server as
[[$user]], enter the "Administration" mode and enter the value
'[[$new_code]]' where it asks for an activition code.)
EOF
	if( $fld eq "email" )
	    {
	    $conmsg .= &xlate(<<EOF);

XL(If your e-mail reader supports it, you can click here:

[[$cpi_vars::URL?user=$user&activation_code=$new_code]]
)
EOF
	    }
	print STDERR $conmsg;
	if( $cpi_vars::FORM{$fld} )
	    {
	    &send_via( $fld,
		$cpi_vars::DAEMON_EMAIL, $cpi_vars::FORM{$fld},
		&xlate("XL(Action required)"), $conmsg );
	    push( @changed_list,
		"XL(Confirmation sent to [[$fld $cpi_vars::FORM{$fld}]].)");
	    }
	}
    return @changed_list;
    }

##########################################################################
##	Allow user to change settings about his account.  Normal users	#
##	can only change their password.					#
##########################################################################
#sub admin_page
#    {
#    my( $form_admin ) = @_;
#    $form_admin ||= $cpi_vars::DEFAULT_FORM;
#    my $msg = "";
#    my %mygroups = ();
#    my ( $u, $g );
#    my ( @problems ) = ();
#    my @toprint;
#    my( @startlist ) =
#	( &can_cgroup
#	? &dbget($cpi_vars::ACCOUNTDB,"groups")
#	: &dbget($cpi_vars::ACCOUNTDB,"users",$cpi_vars::REALUSER,"groups")
#	);
#    foreach $g ( @startlist )
#        {
#	&dbget($cpi_vars::ACCOUNTDB,"groups",$g,"inuse")
#	    && $mygroups{$g}++;
#	}
#
#    $cpi_vars::FORM{modrequest} ||= "";
#    $cpi_vars::FORM{switchuser} ||= "";
#
#    if( $cpi_vars::FORM{modrequest} eq "delete_user" )
#	{
#	&dbwrite( $cpi_vars::ACCOUNTDB );
#	&dbdel( $cpi_vars::ACCOUNTDB, "users", $cpi_vars::USER );
#	&dbput( $cpi_vars::ACCOUNTDB, "users", $cpi_vars::USER, "inuse",0);
#	&dbpop( $cpi_vars::ACCOUNTDB );
#	}
#    elsif( $cpi_vars::FORM{modrequest} eq "modify_user" )
#	{
#	my @changed_list = ();
#	my $usertobe = $cpi_vars::USER;
#	if( &can_cuser() && $cpi_vars::FORM{newuser} )
#	    {
#	    $usertobe = lc( $cpi_vars::FORM{newuser} );
#	    if( $usertobe !~ /^[a-z0-9\.\@_]+$/ )
#		{ push( @changed_list, "Bad characters in new user name." ); }
#	    }
#	if( $cpi_vars::FORM{newuser} ne "" && $cpi_vars::FORM{password0} eq "" )
#	    { push( @changed_list, "No password specified." ); }
#	elsif( ($cpi_vars::FORM{password0}||"")
#	    ne ($cpi_vars::FORM{password1}||"") )
#	    { push( @changed_list, "XL(Password mismatch.)" ); }
#
#	my @glist = split(',',$cpi_vars::FORM{groups});
#
#	if( &can_cuser() )
#	    {
#	    if( ! @glist )
#		{ push( @changed_list, "No groups specified." ); }
#	    elsif( grep( $mygroups{$_} eq "", @glist ) )
#		{ push( @changed_list, "Bad group specified." ); }
#	    }
#
#	if( ! @changed_list )
#	    {
#	    $cpi_vars::USER = $usertobe;
#	    &dbwrite($cpi_vars::ACCOUNTDB);
#	    if( ! &can_cuser() )
#		{
#		if( $cpi_vars::FORM{fullname} ne
#		    &dbget($cpi_vars::ACCOUNTDB,"users",$cpi_vars::USER,"fullname") )
#		    {
#		    &dbput($cpi_vars::ACCOUNTDB,"users",$cpi_vars::USER,
#			"fullname",$cpi_vars::FORM{fullname});
#		    push( @changed_list, "Full name updated." );
#		    }
#		if( $cpi_vars::FORM{password0} ne "" )
#		    {
#		    &dbput( $cpi_vars::ACCOUNTDB, "users", $cpi_vars::USER,
#			"password", &salted_password( $cpi_vars::FORM{password0} ) );
#		    push( @changed_list, "Password updated." );
#		    }
#		}
#	    else
#		{
#		&dbadd($cpi_vars::ACCOUNTDB,"users",$cpi_vars::USER);
#		&dbput($cpi_vars::ACCOUNTDB,"users",$cpi_vars::USER,
#		    "inuse",1);
#		&dbput($cpi_vars::ACCOUNTDB,"users",$cpi_vars::USER,
#		    "password",$cpi_vars::FORM{password0})
#		    if( $cpi_vars::FORM{password0} ne "" );
#		&dbput($cpi_vars::ACCOUNTDB,"users",$cpi_vars::USER,
#		    "groups",&dbarr(@glist));
#		&dbput($cpi_vars::ACCOUNTDB,"users",$cpi_vars::USER,
#		    "fullname",$cpi_vars::FORM{fullname});
#		push( @changed_list, "XL(User [[$cpi_vars::USER]] updated)" );
#		}
#
#	    foreach my $fld ( @cpi_vars::CONFIRM_FIELDS )
#		{
#		push( @changed_list,
#		    &check_com_field( $cpi_vars::USER, $fld ) );
#		}
#	    &dbpop( $cpi_vars::ACCOUNTDB );
#	    }
#	$msg = join("<br>",@changed_list);
#	}
#    elsif( $cpi_vars::FORM{modrequest} eq "add_group" )
#	{
#	if( ($cpi_vars::FORM{groupname} ne "") && &can_cgroup )
#	    {
#	    my $g = &name_to_group( $cpi_vars::FORM{groupname} );
#	    if( &dbget($cpi_vars::ACCOUNTDB,"groups",$g,"inuse") )
#		{ $msg = "Group $g already in use.  Try another."; }
#	    else
#		{
#		&dbwrite($cpi_vars::ACCOUNTDB);
#		&dbadd($cpi_vars::ACCOUNTDB,"groups",$g);
#		&dbput($cpi_vars::ACCOUNTDB,"groups",$g,"inuse",1);
#		&dbput($cpi_vars::ACCOUNTDB,"groups",$g,"fullname",
#		    $cpi_vars::FORM{groupname});
#		&dbpop( $cpi_vars::ACCOUNTDB );
#		}
#	    }
#	}
#    elsif( $cpi_vars::FORM{modrequest} eq "change_group" )
#	{
#	if( ($cpi_vars::FORM{group} ne "") && &can_cgroup )
#	    {
#	    my $g = $cpi_vars::FORM{group};
#	    if( ! &dbget($cpi_vars::ACCOUNTDB,"groups",$g,"inuse") )
#		{ $msg = "Group $g not in use.  Try another."; }
#	    else
#		{
#		&dbwrite($cpi_vars::ACCOUNTDB);
#		&dbadd($cpi_vars::ACCOUNTDB,"groups",$g);
#		&dbput($cpi_vars::ACCOUNTDB,"groups",$g,"inuse",1);
#		&dbput($cpi_vars::ACCOUNTDB,"groups",$g,"fullname",
#		    $cpi_vars::FORM{groupname});
#		&dbpop( $cpi_vars::ACCOUNTDB );
#		}
#	    }
#	}
#    elsif( $cpi_vars::FORM{modrequest} eq "delete_group" )
#	{
#	if( ($cpi_vars::FORM{group} ne "") && &can_cgroup )
#	    {
#	    my $g = $cpi_vars::FORM{group};
#	    if( ! &dbget($cpi_vars::ACCOUNTDB,"groups",$g,"inuse") )
#		{ $msg = "No group called '$g'.  Try another."; }
#	    else
#		{
#		&dbwrite($cpi_vars::ACCOUNTDB);
#		&dbdel($cpi_vars::ACCOUNTDB,"groups",$g);
#		&dbput($cpi_vars::ACCOUNTDB,"groups",$g,"inuse","");
#		&dbpop( $cpi_vars::ACCOUNTDB );
#		}
#	    }
#	}
#    elsif( $cpi_vars::FORM{modrequest} eq "payment"
#	    && $cpi_vars::FORM{topay} ne "" )
#	{
#	my $note;
#	push( @problems, "XL(Illegal payment amount specified.)" )
#	    if( $cpi_vars::FORM{topay} !~ /^[ \$]*(\d+\.\d\d)$/ );
#	my $paid = $1;
#	$paid =~ s/^[ \$]*//g;
#	if( $cpi_vars::FORM{cardname} )
#	    {
#	    $_ = $cpi_vars::FORM{cardnum};
#	    if( /\*/ )
#		{
#		$cpi_vars::FORM{cardnum} =
#		    &dbget($cpi_vars::ACCOUNTDB,"users",$cpi_vars::USER,
#		    "cardnum");
#		$cpi_vars::FORM{cardname} =
#		    &dbget($cpi_vars::ACCOUNTDB,"users",$cpi_vars::USER,
#		    "cardname");
#		$cpi_vars::FORM{cardexp} =
#		    &dbget($cpi_vars::ACCOUNTDB,"users",$cpi_vars::USER,
#		    "cardexp");
#		$_ = $cpi_vars::FORM{cardnum};
#		}
#	    s/[ \-]*//g;
#	    if( /^\d\d\d\d\d\d\d\d\d\d\d\d(\d\d\d\d)$/ )
#		{ $note="CC$1"; }
#	    elsif( /^\d\d\d\d\d\d\d\d\d\d\d\d\d(\d\d\d\d)$/ )
#		{ $note="CC$1"; }
#	    else
#		{
#		push( @problems, "XL(Illegal card of credit number: [[$_]]" );
#		}
#	    $_ = $cpi_vars::FORM{cardexp};
#	    push( @problems,
#		"XL(Illegal expiration date: [[$_]] [[1=$1, 2=$2]])." )
#		if( ! /^(\d\d)\/(\d\d\d\d)$/			||
#		    $1<1 || $1>12 || $2<2000 || $2>2100		);
#	    push( @problems, "XL(Multiple methods of payment specified.)" )
#		if( $cpi_vars::FORM{checknum}
#		    || $cpi_vars::FORM{certnum}
#		    || $cpi_vars::FORM{usecash} );
#	    }
#	elsif( $cpi_vars::FORM{checknum} )
#	    {
#	    push( @problems, "XL(Illegal check number.)" )
#		if( $cpi_vars::FORM{checknum} !~ /^\d[\d\-]*$/ );
#	    push( @problems, "XL(Multiple methods of payment specified.)" )
#		if( $cpi_vars::FORM{certnum} || $cpi_vars::FORM{usecash} );
#	    $note = "CK$cpi_vars::FORM{checknum}";
#	    }
#	elsif( $cpi_vars::FORM{certnum} )
#	    {
#	    push( @problems, "XL(Illegal certificate number.)" )
#		if( $cpi_vars::FORM{certnum} !~ /^\d[\d\-]*$/ );
#	    push( @problems, "XL(Multiple methods of payment specified.)" )
#		if( $cpi_vars::FORM{usecash} );
#	    $note = "CN$cpi_vars::FORM{certnum}";
#	    }
#	elsif( $cpi_vars::FORM{usecash} )
#	    { $note = "Cash"; }
#	else
#	    { push( @problems, "XL(No payment method specified.)" ); }
#	if( @problems )
#	    {
#	    push( @toprint, "<h1>XL(Problems with your form:)</h1>\n" );
#	    foreach $_ ( @problems )
#		{ push(@toprint, "<dd><font color=red>$_</font>\n" ); }
#	    push( @toprint, "<p>XL(Go back and correct these problems.)\n" );
#	    &xprint( @toprint );
#	    exit(0);
#	    }
#	my( $ind ) = $cpi_vars::TODAY;
#	&dbwrite($cpi_vars::DB);
#	&dbadd($cpi_vars::DB,"users",$cpi_vars::USER,"days",
#	    $cpi_vars::TODAY,"payments",$ind);
#	&dbput($cpi_vars::DB,"users",$cpi_vars::USER,"days",
#	    $cpi_vars::TODAY,"payments",$ind,"note",$note);
#	&dbput($cpi_vars::DB,"users",$cpi_vars::USER,"days",
#	    $cpi_vars::TODAY,"payments",$ind,"paid",$paid);
#	&dbpop($cpi_vars::DB);
#	if( $cpi_vars::FORM{cardonfile} )
#	    {
#	    &dbwrite($cpi_vars::ACCOUNTDB);
#	    &dbput($cpi_vars::ACCOUNTDB,"users",$cpi_vars::USER,
#	        "cardnum",$cpi_vars::FORM{cardnum});
#	    &dbput($cpi_vars::ACCOUNTDB,"users",$cpi_vars::USER,
#	        "cardexp",$cpi_vars::FORM{cardexp});
#	    &dbput($cpi_vars::ACCOUNTDB,"users",$cpi_vars::USER,
#	        "cardname",$cpi_vars::FORM{cardname});
#	    &dbpop($cpi_vars::ACCOUNTDB);
#	    }
#	}
#
#    @startlist =
#	( &can_cgroup
#	? &dbget($cpi_vars::ACCOUNTDB,"groups")
#	: &dbget($cpi_vars::ACCOUNTDB,"users",$cpi_vars::REALUSER,"groups")
#	);
#    %mygroups = ();
#    foreach $g ( @startlist )
#        {
#	&dbget($cpi_vars::ACCOUNTDB,"groups",$g,"inuse")
#	    && $mygroups{$g}++;
#	}
#    my $pname = $cpi_vars::FULLNAME || $cpi_vars::USER;
#
#    my %thisusergroup = ();
#    grep( $thisusergroup{$_}="selected",
#	&dbget($cpi_vars::ACCOUNTDB,"users",$cpi_vars::USER,"groups") );
#
#    push( @toprint, <<EOF );
#<script>
#function switchuserfnc()
#    {
#    with ( window.document.$form_admin )
#        {
#	if( switchuser.options[ switchuser.selectedIndex ].value != "*" )
#	    {
#	    USER.value = switchuser.options[ switchuser.selectedIndex ].value;
#	    }
#	modrequest.value = "";
#	submit();
#	}
#    }
#</script>
#<title>${pname}'s $cpi_vars::PROG XL(Administration Page)</title>
#<body $cpi_vars::BODY_TAGS>
#$cpi_vars::HELP_IFRAME
#<center><form name=$form_admin method=post>
#<h1>$msg</h1>
#<input type=hidden name=SID value=$cpi_vars::SID>
#<input type=hidden name=USER value=$cpi_vars::FORM{USER}>
#<input type=hidden name=func value=$cpi_vars::FORM{func}>
#<input type=hidden name=modrequest value="">
#<input type=hidden name=group value="">
#<input type=hidden name=groupname value="">
#<table border=1 $cpi_vars::TABLE_TAGS><tr>
#<th valign=top><table border=0>
#EOF
#    my $fullname =
#	&dbget($cpi_vars::ACCOUNTDB,"users",
#	    $cpi_vars::USER,"fullname");
#    if( $cpi_vars::FORM{switchuser} eq "*" )
#        {
#	push( @toprint, <<EOF );
#<tr><th align=left>XL(New user ID:)</th>
#    <td><input type=text autocapitalize=none name=newuser size=10></td></tr>
#<tr><th align=left>XL(Entire name:)</th>
#    <td><input type=text autocapitalize=words name=fullname size=30></td></tr>
#EOF
#	}
#    elsif( &can_suser() )
#	{
#	push( @toprint, <<EOF );
#<tr><th align=left>XL(User ID:)</th>
#    <td><select name=switchuser onChange='switchuserfnc();'>
#EOF
#	push( @toprint, "<option value=*>XL(Create new user)\n" )
#	    if( &can_cuser() );
#	my %selflag = ( $cpi_vars::USER, " selected" );
#	my $cgprivs = &can_cgroup();
#	foreach $u ( &all_users() )
#	    {
#	    next if( ! &dbget($cpi_vars::ACCOUNTDB,"users",$u,"inuse") );
#	    my $found_group = $cgprivs;
#	    if( ! $found_group )
#		{
#		$found_group++
#		    if( grep($mygroups{$_},
#		        &dbget($cpi_vars::ACCOUNTDB,
#			    "users",$u,"groups")) );
#		}
#	    if( $found_group )
#		{
#		$_ = &dbget($cpi_vars::ACCOUNTDB,"users",$u,"fullname");
#		push( @toprint,
#		    "<option",
#		        ($selflag{$u}||""),
#			" value=\"$u\">$u - $_</option>\n" );
#		}
#	    }
#    	push( @toprint, <<EOF );
#    </select></td></tr>
#<tr><th align=left>XL(Entire name:)</th>
#    <td><input type=text autocapitalize=words name=fullname value="$fullname" size=30></td></tr>
#EOF
#	}
#    else
#        {
#    	push( @toprint, <<EOF );
#<tr><th align=left>XL(User ID:)</th><td>$cpi_vars::USER</td></tr>
#<tr><th align=left>XL(Entire name:)</th><td><input type=text autocapitalize=words name=fullname value="$fullname" size=30></td></tr>
#EOF
#	}
##<tr><th align=left>XL(Entire name:)</th><td>$cpi_vars::FULLNAME</td></tr>
#    my %current = ();
#    my %confirmed = ();
#    foreach my $fld ( @cpi_vars::CONFIRM_FIELDS )
#        {
#	$current{$fld} = &dbget($cpi_vars::ACCOUNTDB,"users",$cpi_vars::USER,$fld);
#	my $lf = &dbget($cpi_vars::ACCOUNTDB,"users",$cpi_vars::USER,"last".$fld) || "";
#	if( ! $current{$fld} )
#	    { $confirmed{$fld} = ""; }
#	elsif( ($current{$fld}||"") eq $lf )
#	    { $confirmed{$fld} = "(Confirmed)"; }
#	else
#	    { $confirmed{$fld} = "(Unconfirmed)"; }
#	}
#    push( @toprint, <<EOF );
#<tr><th align=left>XL(Password:)</th>
#    <td><input type=password name=password0 size=12></td>
#    </th></tr>
#<tr><th align=left>XL(Password repeated:)</th>
#    <td><input type=password name=password1 size=12></td></tr>
#EOF
#    foreach my $fld ( @cpi_vars::CONFIRM_FIELDS )
#        {
#	push( @toprint, "<tr><th align=left valign=top>XL($cpi_vars::FLDESC{$fld}{prompt}:)</th><td>",
#	    ( ( $cpi_vars::FLDESC{$fld}{rows} && $cpi_vars::FLDESC{$fld}{rows}>1 )
#	    ? "<textarea cols=$cpi_vars::FLDESC{$fld}{cols} rows=$cpi_vars::FLDESC{$fld}{rows} name=$fld >$current{$fld}</textarea>"
#	    : "<input type=text name=$fld autocapitalize=none size=$cpi_vars::FLDESC{$fld}{cols} value='$current{$fld}'>"
#	    ),
#	    "XL($confirmed{$fld})</td></tr>" )
#	    if( $cpi_vars::FLDESC{$fld}{ask} );
#	}
#    if( &can_cuser )
#	{
#	push( @toprint, "<tr><th align=left>XL(Groups:)</th>\n" );
#	$_ = 10 if( ($_ = scalar( keys %mygroups )) > 10 );
#	push( @toprint, "<td><select name=groups multiple size=$_>\n" );
#	foreach $g ( sort keys %mygroups )
#	    {
#	    push( @toprint,
#		"<option value=\"$g\" ".($thisusergroup{$g}||"").">",
#	        &group_to_name($g) . "\n" );
#	    }
#	push( @toprint, <<EOF );
#</select></td></tr>
#EOF
#	}
#    $_ = (  ( $cpi_vars::FORM{switchuser} eq "*" )
#	    ? "XL(Create new user)"
#	    : "XL(Modify) $cpi_vars::USER" );
#    push( @toprint, <<EOF );
#<tr><th colspan=2><input type=button value="$_" onClick='document.$form_admin.modrequest.value="modify_user";submit();'>
#EOF
#    push( @toprint, <<EOF ) if( ( $cpi_vars::FORM{switchuser} ne "*" ) && &can_cuser );
#<input type=button value="XL(Delete [[$cpi_vars::USER]])" onClick='document.$form_admin.modrequest.value="delete_user";submit();'>
#EOF
#    push( @toprint, <<EOF );
#    </th></tr>
#<tr><th colspan=2>&nbsp;</th></tr>
#<tr><th align=left>XL(Enter activation code:)</th>
#    <td><input type=text autocapitalize=none name=activation_code onChange='submit();'></td></tr>
#</table></th>
#EOF
#
#    if( $cpi_vars::PAYMENT_SYSTEM )
#        {
#	my($sec,$min,$hour,$mday,$month,$year) = localtime(time);
#	my( $topay, $weight, $cardname, $cardnum, $cardonfile, $checknum, $certnum, $usecash );
#	my $expselect = "";
#
#	$cardname = &dbget($cpi_vars::ACCOUNTDB,"users",$cpi_vars::USER,
#			"cardname");
#	$cardnum = &dbget($cpi_vars::ACCOUNTDB,"users",$cpi_vars::USER,
#			"cardnum");
#	$_ = length( $cardnum );
#	$cardnum = "************".substr($cardnum,$_-4,4);
#	my %selflag = ( &dbget($cpi_vars::ACCOUNTDB,"users",
#			    $cpi_vars::USER,"cardexp"), " selected" );
#
#	for( $_=0; $_<48; $_++ )
#	    {
#	    my $dstr = sprintf("%02d/%d",$month,$year+1900);
#	    $expselect .= "<option".($selflag{$dstr}||"")." value=$dstr>$dstr\n";
#	    if( ++$month > 12 )
#	        {
#		$month = 1;
#		$year++;
#		}
#	    }
#	push( @toprint, <<EOF );
#<th valign=top><table>
#<tr><th align=left>XL(To pay:)</th>
#    <td><input type=text name=topay autocapitalize=none value="$topay" size=6></td></tr>
#<tr><th colspan=2>&nbsp;</th></tr>
#<tr><th align=left>XL(Name on credit card:)</th>
#    <td><input type=text name=cardname autocapitalize=words value="$cardname" size=20></td></tr>
#<tr><th align=left>XL(Credit card number:)</th>
#    <td><input type=text name=cardnum value="$cardnum">
#    </td></tr>
#<tr><th align=left>XL(Expiration:)</th><td><select name=cardexp>
#$expselect
#</select>
#&nbsp;&nbsp;<b>Save:</b>
#<input type=checkbox name=cardonfile $cardonfile></td></tr>
#<tr><th colspan=2>XL(OR)</th></tr>
#<tr><th align=left>XL(Number on the Cheque:)</th>
#    <td><input type=text name=checknum value="" size=10></td></tr>
#<tr><th colspan=2>XL(OR)</th></tr>
#<tr><th align=left>XL(Number on the Certificate:)</th>
#    <td><input type=text name=certnum value="" size=10></td></tr>
#<tr><th colspan=2>XL(OR)</th></tr>
#<tr><th align=left>XL(Cash:)</th>
#    <td><input type=checkbox name=usecash $usecash></td></tr>
#<tr><th colspan=2><input type=button
#    onClick='document.$form_admin.modrequest.value="payment";submit();'
#    value="XL(Complete the payment)"></th></tr>
#</table></th>
#EOF
#	}
#
#    if( &can_cgroup )
#        {
#	push( @toprint, <<EOF );
#<th valign=top><table>
#<tr><th align=left>XL(Create group:)</th>
#    <td><input type=text autocapitalize=words value="" size=10
#	onChange='document.$form_admin.groupname.value=this.value;document.$form_admin.modrequest.value="add_group";submit();'></td>
#	<td></td>
#</tr>
#EOF
#	foreach my $g ( &groups() )
#	    {
#	    push( @toprint,
#		"<tr><th align=left>$g</th><td>",
#		"<input type=text autocapitalize=words size=10 value=\"",
#	        &group_to_name( $g ),
#	        "\" onChange='document.$form_admin.group.value=\"$g\";document.$form_admin.groupname.value=this.value;document.$form_admin.modrequest.value=\"change_group\";submit();'>",
#	        "</td><td><input type=button value=\"XL(Delete)\" ",
#	        "onClick='document.$form_admin.modrequest.value=\"delete_group\";document.$form_admin.group.value=\"$g\";submit();'>",
#	        "</td></tr>\n" );
#	    }
#	push( @toprint, "</table></th>" );
#	}
#
#    push( @toprint, "<td valign=top>" . &who() . "</td>" );
#
#    push( @toprint, "</tr></table></form>\n" );
#    &xprint( @toprint );
#    &main::footer("admin") if( exists(&main::footer) );;
#    &cleanup(0);
#    }

#########################################################################
#	Useful for logout select in footer.				#
#########################################################################
sub logout_select
    {
    my( $form_logout ) = @_;
    $form_logout ||= $cpi_vars::DEFAULT_FORM;
    my $script_prefix = $ENV{SCRIPT_NAME};
    $script_prefix =~ s:\?.*::;
    $script_prefix =~ s:index.cgi::;
    $script_prefix =~ s:[^/]*/$::;
    my $logoutfnc = 
	"if(this.value==\"logout\") { window.document.$form_logout.action=\"${script_prefix}User?func=logout\";window.document.$form_logout.submit();} else {window.document.$form_logout.action=\"$script_prefix\"+this.value;window.document.$form_logout.submit();}";
    my @s = ("<select name=new_prog help='COMMON_select_program' onChange='$logoutfnc'>\n");

    my %seen_cgs =
        map { $_, 1 }
	    grep( &in_group($cpi_vars::USER,&name_to_group("$_ user")),
		grep( -x "../$_/index.cgi", &files_in("..","^\\w") ) );
    $seen_cgs{$cpi_vars::PROG}=1;

    foreach my $prog ( sort { lc($a) cmp lc($b) } keys %seen_cgs )
	{
        push( @s, "<option value=$prog",
	    ( $prog eq $cpi_vars::PROG ? " selected" : "" ),
	    ">$prog</option>\n" );
	}
    #push( @s,	"<option value=admin>XL(User settings)</option>",
    push( @s, "<option value=logout>XL(Logout)</option></select>\n" );

    return join("",@s);
    }

1;
