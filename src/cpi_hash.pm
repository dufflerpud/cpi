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

package cpi_hash;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( hashof match_password salted_password set_best_password_hash );
use lib ".";

use cpi_file qw( autopsy );
use Digest::MD5 qw(md5_hex);
use Digest::SHA qw(sha1_hex sha256_hex);
#__END__
1;

#########################################################################
#	Create a string that is really likely to be unique.		#
#	Probably not best for passwords, but good compromise for	#
#	speed, variance, etc.						#
#########################################################################
sub hashof		{ return md5_hex(@_); }

my @SALT_DIGITS = ( '.', '/', 0 .. 9, 'A' .. 'Z', 'a' .. 'z' );
my @HASHING_METHODS =
    (
    { salt_size=>8, digits=>\@SALT_DIGITS, name=>"sha1",	digester=>\&sha1_hex	},
    { salt_size=>8, digits=>\@SALT_DIGITS, name=>"sha256",	digester=>\&sha256_hex	},
    { salt_size=>8, digits=>\@SALT_DIGITS, name=>"md5",		digester=>\&md5_hex	},
    { salt_size=>2, digits=>\@SALT_DIGITS, name=>"des"					}
    );
my %HASHING_METHODS = map { ($_->{name},$_) } @HASHING_METHODS;
my $BEST_PASSWORD_HASH = $HASHING_METHODS[0]->{name};

#########################################################################
#	Specify best hashing for passwords (probably for debugging).	#
#########################################################################
sub set_best_password_hash
    {
    my( $new_password_hash ) = @_;
    &autopsy("$new_password_hash is not a known hashing method.")
	if( ! $HASHING_METHODS{$new_password_hash} );;
    $BEST_PASSWORD_HASH = $new_password_hash;
    }

#########################################################################
#	Make all hashes look like des.  You're welcome.			#
#########################################################################
sub cryptic
    {
    my( $methodp, $plaintext, $salt ) = @_;
    my $func = $methodp->{digester};
    my $ret = $func ? $salt . &{$func}( $salt . $plaintext ) : crypt( $plaintext, $salt );
    #print STDERR "cryptic( $salt.$plaintext ) returns [$ret]\n";
    return $ret;
    }

#########################################################################
#	Creates string suitable for storage from a clear text password.	#
#########################################################################
sub salted_password
    {
    #print STDERR __LINE__, ": salted_password(",join(",",@_),")\n";
    my ( $unencrypted, $methodp ) = @_;
    if( ! $methodp )
	{ $methodp = $HASHING_METHODS{$BEST_PASSWORD_HASH}; }
    elsif( ! ref( $methodp ) )
	{ $methodp = $HASHING_METHODS{$methodp}; }
    my @digits = @{ $methodp->{digits} };
    my $salt = join("",(map{$digits[rand(@digits)]} 1..$methodp->{salt_size}));
    return &cryptic( $methodp, $unencrypted, $salt );
    }

#########################################################################
#	Check if the hypothesized password matches the password		#
#	on file.  If not, return undef, if so, return the best possible	#
#	version to put back on file.  Should have the effect of making	#
#	sure the best encryption standards are maintained.		#
#########################################################################
sub match_password
    {
    #print STDERR __LINE__, ": match_password(",join(",",@_),")\n";
    my( $check_word, $check_against ) = @_;
    my $ret;
    foreach my $methodp ( @HASHING_METHODS )
	{
	my $salt = substr( $check_against, 0, $methodp->{salt_size} );
	#my $pepper = substr( $check_against, $methodp->{salt_size} );
	if( $check_against eq &cryptic( $methodp, $check_word, $salt ) )
	    {
	    return
		( $methodp->{name} eq $BEST_PASSWORD_HASH
		? $check_against
		: &salted_password( $check_word ) );
	    }
	}
    if( $check_word eq $check_against )	# This should go away, very insecure
	{ return &salted_password($check_word); }
    return undef;
    }
1;
