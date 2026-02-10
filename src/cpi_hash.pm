#!/usr/bin/perl -w
#indx#	cpi_hash.pm - Routines integrating various hashes, standardize on one
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
#doc#	cpi_hash.pm - Routines integrating various hashes, standardize on one
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

    # This is useful only because all hashes are at least 13 characters
    # long.  If the user happens to have a long password and it is
    # stored in clear text, it's not going to get updated, but it
    # isn't going to pass the password check either.
    if( $check_word eq $check_against && length($check_against)<13 )
	{ return &salted_password($check_word); }
    return undef;
    }
1;
