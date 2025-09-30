#!/usr/bin/perl -w
########################################################################
#@HDR@	$Id$
#@HDR@		Copyright 2025 by
#@HDR@		Christopher Caldwell/Brightsands
#@HDR@		P.O. Box 401, Bailey Island, ME 04003
#@HDR@		All Rights Reserved
#@HDR@
#@HDR@	This software comprises unpublished confidential information
#@HDR@	of Brightsands and may not be used, copied or made available
#@HDR@	to anyone, except in accordance with the license under which
#@HDR@	it is furnished.
########################################################################

use strict;

package cpi_time;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( at at_add_field at_dur at_dur_add
 at_dur_diff at_dur_fix at_dur_string at_dur_to_days
 at_from_unix_epoch at_string at_time_cmp at_to_unix_epoch
 check_day_is days_in_month parsedate revlocaltime
 time_string timestr );
use lib ".";


#__END__
1;

#########################################################################
#	Return  base + number of increments required to make condition	#
#	true.  Clearly larger increments make this faster.		#
#########################################################################
sub check_day_is
    {
    my( $base, $day_num, $increment ) = @_;
    }

#########################################################################
#	Time constants.							#
#########################################################################
my @TIME_CODE_HOOKS =
    (
    	{name=>"sunset",	code=>undef				},
	{name=>"sunrise",	code=>undef				},
	{name=>"sunday",	code=>sub {	&check_day_is(0) }	},
	{name=>"monday",	code=>sub {	&check_day_is(1) }	},
	{name=>"tuesday",	code=>sub {	&check_day_is(2) }	},
	{name=>"wednesday",	code=>sub {	&check_day_is(3) }	},
	{name=>"thursday",	code=>sub {	&check_day_is(4) }	},
	{name=>"friday",	code=>sub {	&check_day_is(5) }	},
	{name=>"saturday",	code=>sub {	&check_day_is(6) }	}
    );
my @TIME_FIELD_LIST =
    (
    	{name=>"year",		fmt=>"%04d",	letter=>"Y",	startat=>0,	nvals=>undef	},
	{name=>"month",		fmt=>"%02d",	letter=>"m",	startat=>1,	nvals=>12	},
	{name=>"day",		fmt=>"%02d",	letter=>"d",	startat=>1,	nvals=>31	},
	{name=>"hour",		fmt=>"%02d",	letter=>"H",	startat=>0,	nvals=>24	},
	{name=>"minute",	fmt=>"%02d",	letter=>"M",	startat=>0,	nvals=>60	},
	{name=>"second",	fmt=>"%02d",	letter=>"S",	startat=>0,	nvals=>60	},
	{name=>"microsecond",	fmt=>"%06d",	letter=>"Q",	startat=>0,	nvals=>1000000	}
    );

our @TIME_FIELD_NAMES	= map { $_->{name} } @TIME_FIELD_LIST;
our %TIME_FIELDS	= map { $_->{name}, $_, $_->{letter}, $_ } @TIME_FIELD_LIST;
our %TIME_FIELDS_EMPTY	= map { $_->{name}, 0 } @TIME_FIELD_LIST;
our $TIME_OR_LIST	= join("|",(map{$_->{letter}} @TIME_FIELD_LIST));
our $ANYTIME_FMT	= "%Y-%m-%d %H:%M:%S.%Q";

#########################################################################
#	Return a at object based on the arguments.			#
#########################################################################
sub at
    {
    my( $t ) = @_;
    my %ret = %TIME_FIELDS_EMPTY;

    if( !defined($t) || $t eq "now" )
		# No arguments supplied, return today based on
        {	# UNIX time/localtime
	%ret = %{ &at_from_unix_epoch( time() ) };
	}
    elsif( ref($t) eq "HASH" )
	{
	grep($ret{$_}=($t->{$_}||0), @TIME_FIELD_NAMES );
	$ret{timezone}=$t->{timezone} if( defined($t->{timezone}) );
	#return \%ret;		# REMOVE THIS
	}
    elsif( $t =~ /^\d+$/ )
	{ $ret{second} = $t; }
    else
	{
	if( $t =~ /(-*\d+)-(\d+)-(\d+)/ )
	    { $ret{year}=$1; $ret{month}=$2; $ret{day}=$3; }
	elsif( $t =~ m:(\d+)/(\d+)/(\d+): )
	    {
	    $ret{year} = $3;
	    if( $1 > 12 )
		{ $ret{day}=$1; $ret{month}=$2; }
	    elsif( $2 > 12 )
		{ $ret{day}=$2; $ret{month}=$1; }
	    else
		{			# Dunno if this is American
		$ret{day}=$1;	# or non-American date.
		$ret{month}=$2;	# Americans are wrong
		}
	    }
	if( $t =~ /(\d+):([\d:\.]+)/ )
	    {
	    $ret{hour}=$1;
	    $ret{minute}=$2;
	    if( $ret{minute} =~ /(\d+):(.*)/ )
		{
		$ret{minute} = $1;
		$ret{second} = $2;
		if( $ret{second} =~ /(\d+)\.(.*)/ )
		    {
		    $ret{second} = $1;
		    my $microsecond = $2;
		    my $l = length($microsecond);
		    while( $l < 6 ) { $microsecond *= 10; $l++; }
		    while( $l > 6 ) { $microsecond = int($microsecond/10); $l--; }
		    $ret{microsecond} = $microsecond;
		    }
		}
	    }
	}

    $ret{timezone} ||= "GMT";
    return \%ret;
    }

#########################################################################
#	Create a duration (looks much like an at).  Can be used	#
#	to add durations.						#
#########################################################################
sub at_dur
    {
    my( @durptr ) = @_;
    my %offset = %TIME_FIELDS_EMPTY;
    my $sign = 1;
    foreach my $d ( @durptr )
	{
	if( ref($d) eq "HASH" )
	    { grep($offset{$_}+=($d->{$_}||0), @TIME_FIELD_NAMES ); }
	elsif( $d eq "+" )
	    { $sign=1; }
	elsif( $d eq "-" )
	    { $sign=-1; }
	elsif( $d =~ /^\d+$/ )
	    { $offset{second} += $sign*$d; }
	else
	    {
	    my $tstring = $d;
	    my $current_sign = $sign;
	    while( 1 )
	        {
		if( $tstring =~ /^(.*?)([\+\-]*)(\d+)($TIME_OR_LIST)(.*)$/ )
		    {
		    my($prefix,$newsign,$amt,$let,$suffix)=($1,$2,$3,$4,$5);
		    if( $newsign eq "+" )
			{ $current_sign = $sign; }
		    elsif( $newsign eq "-" )
			{ $current_sign = -$sign; }
		    $offset{ $TIME_FIELDS{$let}{name} } += $current_sign * $amt;
		    $tstring = $prefix . $suffix;
		    }
		elsif(	$tstring =~ /^(.*?)([\+\-]*)(\d+):(\d+):(\d+)\.(\d+)(.*)$/
		 ||	$tstring =~ /^(.*?)([\+\-]*)(\d+):(\d+):(\d+)(.*)$/
		 ||	$tstring =~ /^(.*?)([\+\-]*)(\d+):(\d+)(.*)$/ )
		    {
		    my $prefix = $1;
		    my $newsign = $2;
		    my $hour = $3;
		    my $minute = $4;
		    my $second = $5;
		    my $microsecond = $6;
		    my $suffix = $7;
		    if( $newsign eq "+" )
			{ $current_sign = $sign; }
		    elsif( $newsign eq "-" )
			{ $current_sign = -$sign; }
		    $offset{hour}		+=$current_sign*$hour;
		    $offset{minute}		+=$current_sign*$minute;
		    if( $second !~ /^\d+$/ )
		        { $suffix = $second; }
		    else
		        {
			$offset{second}		+=$current_sign*$second;
			if( $microsecond !~ /^\d+$/ )
			    { $suffix = $microsecond; }
			else
			    {
			    my $l = length($microsecond);
			    while( $l < 6 ) { $microsecond *= 10; $l++; }
			    while( $l > 6 ) { $microsecond = int($microsecond/10); $l--; }
			    $offset{microsecond} += $sign*$microsecond;
			    }
			}
		    $tstring = $prefix . $suffix;
		    }
		elsif( $tstring !~ /^\s*$/ )
		    { print STDERR "Ignoring [$tstring] out of [$d]\n"; last; }
		else
		    { last; }
		}
	    }
	}
    return \%offset;
    }

#########################################################################
#	Return a duration struct justified to days.			#
#########################################################################
sub at_dur_to_days
    {
    my( $d ) = @_;
    my $carryover = 0;
    foreach my $field ( qw( microsecond second minute hour ) )
	{ $carryover = &add_field( $d, undef, $field, $carryover ); }
    $d->{day} += $carryover;
    my $day_factor = 1;
    foreach my $field ( qw( month year ) )
        {
	$day_factor *= $TIME_FIELDS{ $field }{ nvals };
	$d->{day} += $d->{$field} * $day_factor;
	$d->{$field} = 0;
	}
    return $d;
    }

#########################################################################
#	Return a duration as an easy to read ndnHnMnSnnq		#
#########################################################################
sub at_dur_string
    {
    my( $d ) = @_;
    my @ret;
    foreach my $field ( @TIME_FIELD_NAMES )
        {
	push( @ret, $d->{$field}, $TIME_FIELDS{$field}{letter} )
	    if( $d->{$field} );
	}
    return ( @ret ? join("",@ret) : "0S" );
    }

#########################################################################
#	Fix duration assuming 30 days per month.			#
#########################################################################
sub at_dur_fix
    {
    my( $d ) = @_;
    my $carryover = 0;
    foreach my $field ( reverse @TIME_FIELD_LIST )
	{ $carryover = &add_field( $d, undef, $field, $carryover ); }
    return $d;
    }

#########################################################################
#	Compare two time structures					#
#########################################################################
sub at_time_cmp
    {
    my( $t0, $t1 ) = @_;
    my $diff;
    foreach my $tf ( @TIME_FIELD_NAMES )
        {
	return $diff if( $diff = $t0->{$tf} <=> $t1->{$tf} );
	}
    return $diff;
    }

#########################################################################
#	Does the hard part of time math.				#
#########################################################################
sub at_dur_diff
    {
    my( $t0, $t1 ) = @_;
    $t0 = &at($t0);
    $t1 = &at($t1);
    my $morl = &at_time_cmp( $t0, $t1 );
    if( $morl < 0 )
        { my $copy=$t0; $t0=$t1; $t1=$copy; }

    my %bottom = %TIME_FIELDS_EMPTY;
    my %top = %TIME_FIELDS_EMPTY;
    $top{year} = $t0->{year} - $t1->{year} + 1;

    my %half_way;
    while( 1 )
        {
	%half_way = %TIME_FIELDS_EMPTY;
	my $carry = 0;
	foreach my $f ( @TIME_FIELD_NAMES )
	    {
	    my $top_w_carry = $top{$f};
	    $top_w_carry += $TIME_FIELDS{$f}{nvals} if( $carry );
	    if( $top_w_carry > $bottom{$f}+1 )
	        {
		$half_way{$f} = $bottom{$f} + int(($top_w_carry-$bottom{$f})/2);
		last;
		}
	    elsif( $top_w_carry > $bottom{$f} )
	        {
		$carry = 1;
		$half_way{$f} = $bottom{$f};
		}
	    else
	        {
		$carry = 0;
		$half_way{$f} = $bottom{$f};
		}
	    }
	my $try_time = &at_dur_add( $t1, \%half_way );
	my $more_or_less = &at_time_cmp( $try_time, $t0 );
	if( $more_or_less == 0 )
	    { last; }
	elsif( $more_or_less < 0 )
	    { %bottom = %half_way; }
	else
	    { %top = %half_way; }
	}
    return \%half_way;
    }

#########################################################################
#	Returns the number of days in a month.  I hate time math.	#
#	NOTE:  January is m=0, February is m=1, December is m=11	#
#########################################################################
sub days_in_month
    {
    my( $y, $m ) = @_;
    $m -= $TIME_FIELDS{month}{startat};
    return
	( $m != 1	? [31,28,31,30,31,30,31,31,30,31,30,31]->[$m]
	: $y % 400==0	? 29
	: $y % 100==0	? 28
	: $y % 4==0	? 29
	:		  28 );
    }

#########################################################################
#	
#########################################################################
sub at_add_field
    {
    my( $base, $duration, $field, $carryover ) = @_;
    $base->{$field} += ($carryover - $TIME_FIELDS{$field}{startat});
    $base->{$field} += $duration->{$field} if( $duration );
    my $nvals = $TIME_FIELDS{$field}{nvals};
    if( ! $nvals )
        { $carryover = 0; }
    else
	{
	$carryover = int($base->{$field} / $nvals);
	$carryover-- if( $base->{$field} < 0 ) ;
	#print "base->{$field}=",$base->{$field}, " nvals=$nvals, carryover=$carryover.\n";
	$base->{$field} %= $nvals;
	#print "base->{$field} now =",$base->{$field}, ".\n";
	}
    $base->{$field} += $TIME_FIELDS{$field}{startat};
    return $carryover;
    }

#########################################################################
#	Does the hard part of time math.				#
#########################################################################
sub at_dur_add
    {
    my( $base, @duration_args ) = @_;
    my %ret = %{$base};

    foreach my $duration_arg ( @duration_args )
	{
	my $duration = &at_dur($duration_arg);
	my $carryover = 0;

	# Add in months and years EXPLICITLY specified in duration given.
	foreach my $field ( qw( month year ) )
	    { $carryover = &at_add_field( \%ret, $duration, $field, $carryover ); }

	# Add in hours, minutes, seconds and microseconds to get days carryover
	foreach my $field ( qw( microsecond second minute hour ) )
	    { $carryover = &at_add_field( \%ret, $duration, $field, $carryover ); }

	$ret{day} -= $TIME_FIELDS{day}{startat};
	$ret{day} += $duration->{day} + $carryover;
	while( 1 )
	    {
	    my $days_this_month = &days_in_month( $ret{year}, $ret{month} );
	    if( $ret{day} >= $days_this_month )
		{
		$ret{day} -= $days_this_month;
		$carryover = 1;
		}
	    elsif( $ret{day} < 0 )
		{ 
		$ret{day} += $days_this_month;
		$carryover = -1;
		}
	    else
		{last;}

	    foreach my $field ( qw( month year ) )
		{ $carryover = &at_add_field( \%ret, undef, $field, $carryover ); }
	    }
	$ret{day} += $TIME_FIELDS{day}{startat};
	}

    $ret{timezone} ||= "GMT";
    return \%ret;
    }

#########################################################################
#	Convert a time from the UNIX seconds-based epoch system		#
#	to an attime.							#
#########################################################################
sub at_from_unix_epoch
    {
    my %ret = %TIME_FIELDS_EMPTY;
    my( $seconds_since_epoch ) = @_;
    my @pieces = localtime( $seconds_since_epoch );
    grep( $ret{$_}=shift(@pieces),qw(second minute hour day month year) );
    $ret{year} += 1900;
    $ret{month}++;
    $ret{timezone} = "GMT";
    return \%ret;
    }

#########################################################################
#	Convert a at back to seconds from the unix epoch.		#
#	If the at is before 1970 or after 2038, this won't		#
#	work.								#
#########################################################################
sub at_to_unix_epoch
    {
    my( $t ) = &at(@_);
    &die("Cannot convert this date back to seconds past UNIX epoch.")
        if( $t->{year} < 1970 || $t->{year} >= 2038 );
    return &revlocaltime(
        $t->{second},
	$t->{minute},
	$t->{hour},
	$t->{day},
	$t->{month},
	$t->{year} );
    }

#########################################################################
#	Return a string of whatever the time represented by @rest	#
#	shows with the specified format.  If no @rest is specified,	#
#	we use now.							#
#########################################################################
sub at_string
    {
    my( $fmt, @rest ) = @_;
    #my $t = &at(@rest);
    my $t = $rest[0];
    $t = ( ref($t) eq "HASH" ? $t : &at(@rest) );

    $fmt =
	( $t->{microsecond}		? "%Y-%m-%d %H:%M:%S.%Q"
	: $t->{second}			? "%Y-%m-%d %H:%M:%S"
	: $t->{minute}||$t->{hour}	? "%Y-%m-%d %H:%M"
	: $t->{day}||$t->{month}	? "%Y-%m-%d"
	:				  "%Y" ) if( ! $fmt );
	   
    my @toks = split(/(%)/,$fmt);
    my $tok;
    my @ret;
    my @fields = @TIME_FIELD_NAMES;
    while( defined($tok=shift(@toks) ) )
        {
	if( $tok eq "" )
	    {}
	elsif( $tok ne "%" )
	    { push( @ret, $tok ); }
	else
	    {
	    $tok = shift(@toks);
	    if( $tok eq "%" )
	        { push( @ret, $tok ); }
	    elsif( $tok =~ /^($TIME_OR_LIST)(.*)$/ )
		{
		my $tp = $TIME_FIELDS{$1};
		push( @ret, sprintf( $tp->{fmt}, $t->{$tp->{name}} ) );
		unshift( @toks, $2 );
		}
	    elsif( $tok =~ /^(\d+)($TIME_OR_LIST)(.*)$/ )
		{
		unshift( @toks, $3 );
		my $piece_fmt = "%$1$2";
		push( @ret, sprintf( $piece_fmt, $t->{shift(@fields)} ) );
		}
	    else
	        { die("Cannot calculate time with [$tok] in line ".__LINE__); }
	    }
	}
    return join("",@ret);
    }

#########################################################################
#	Figures out what format its input is in and returns string	#
#	that format is in.						#
#########################################################################
sub time_string
    {
    my( $fmt, $year, $month, $day, $hour, $min, $sec ) = @_;
    if( ! defined($month) )
	{
	my $timevar = $year || time();
	if( $timevar =~ m:^(20\d\d)([0-1]\d)([0-3]\d)$: )
	    { $year=$1; $month=$2; $day=$3; }
	elsif( $timevar =~ m:^([0-1]\d)/([0-3]\d)/(20\d\d): )
	    { $year=$3; $month=$1; $day=$2; }
	elsif( $timevar =~ m:^([0-1]\d)/([0-3]\d)/(\d\d)$: )
	    { $year=$3+1900; $month=$1; $day=$2; }
	else
	    {
	    return undef if( $timevar!~/^\d*$/ && !($timevar=str2time($timevar)) );
	    ($sec,$min,$hour,$day,$month,$year) = localtime($timevar);
	    $year += 1900;
	    $month += 1;
	    }
	}
    return sprintf($fmt,$year,$month,$day,$hour||0,$min||0,$sec||0);
    }

#########################################################################
#	Return yyyymmdd for a specified offset from epoch.		#
#########################################################################
sub timestr
    {
    return &time_string("%4d%02d%02d",@_);
    }

#########################################################################
#       Use binary search to convert min,hour,day,month,year to         #
#       seconds from the epoch.                                         #
#########################################################################
sub revlocaltime
    {
    my( @alist ) = @_;
    my( $base ) = 0;
    my( $bit ) = 0x40000000;
    $alist[5] += 100 if( $alist[5] < 90 );
    $alist[5] -= 1900 if( $alist[5] >= 1900 );
    while( $bit )
        {
        my $try = $base | $bit;
        my @compare = localtime( $try );
        my( $i, $res );
        for( $i=5; $i>=0; $i-- )
            {
            last if( $res = ( $alist[$i] <=> $compare[$i] ) );
            }
        if( $res >= 0 )
            {
            $base = $try;
            last if( $res == 0 );
            }
        $bit >>= 1;
        }
    return $base;
    }

#########################################################################
#	Convert a string in many formats to seconds since epoch.	#
#########################################################################
sub parsedate
    {
    my( $tocvt, $relative_to ) = @_;
    return $tocvt if( $tocvt =~ /^\d\d\d\d\d+/ );
    my($csec,$cmin,$chour,$cmday,$cmonth,$cyear)
	= localtime($relative_to?$relative_to:time);
    my($nsec,$nmin,$nhour,$nmday,$nmonth,$nyear);
    foreach $_ ( split(/\s+/,$tocvt) )
        {
	if( /:/ )
	    { ( $nhour, $nmin, $nsec ) = split(':'); }
	elsif( /^(\-*\d+)-(\d+)-(\d+)$/ )
	    { ( $nyear, $nmonth, $nmday ) = ( $1, $2, $3 ); }
	elsif( /\// )
	    {
	    my @left = ();
	    foreach my $part ( split('\/') )
	        {
		if( $part > 31 )
		    { $nyear = $part; }
		elsif( $part > 12 && !defined($nmday) )
		    { $nmday = $part; }
		else
		    { push( @left, $part ); }
		}
	    $nmonth = shift(@left) if( !defined($nmonth) );
	    $nmday  = shift(@left) if( !defined($nmday)  );
	    $nyear  = shift(@left) if( !defined($nyear)  );
	    }
	}
    $nmday = $cmday if( !defined($nmday) );
    $nmonth = ( defined($nmonth)?($nmonth-1):$cmonth );
    $nyear = $cyear if( !defined($nyear) );
    $nhour = $chour if( !defined($nhour) );
    $nmin = $cmin if( !defined($nmin) );
    $nsec = $csec if( !defined($nsec) );
    return &revlocaltime($nsec,$nmin,$nhour,$nmday,$nmonth,$nyear);
    }

1;
