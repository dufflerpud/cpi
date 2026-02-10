#!/usr/bin/perl -w
#
#indx#	cpi_qrcode_of.pm - Frontend to QR-Code software (ease of use)
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
#doc#	cpi_qrcode_of.pm - Frontend to QR-Code software (ease of use)
########################################################################

use strict;

package cpi_qrcode_of;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( qrcode_of );
use lib ".";

use cpi_file qw( autopsy write_file );
use MIME::Base64 qw( encode_base64 );
use Imager::QRCode;
#__END__
1;

#########################################################################
#	Return text as a QR code, probably as a jpeg.			#
#########################################################################
sub qrcode_of
    {
    my( $text, $argp ) = @_;
    my $fmt = $argp->{type} || "jpeg";
    my $qrcode = Imager::QRCode->new
        (
        size          => 2,
        margin        => 5,
        version       => 1,
        level         => 'M',
        casesensitive => 1,
        lightcolor    => Imager::Color->new(255, 255, 255),
        darkcolor     => Imager::Color->new(0, 0, 0)
	);
    &autopsy("Imager::QRCode->new failed:  $!") if( ! $qrcode );
    my $img = $qrcode->plot($text);
    &autopsy("Imager::QRCode->plot($text) failed:  $!") if( ! $img );

    my $ret;
    $img->write( data=>\$ret, type=>($argp->{type}||"jpeg") );

    if( ! $ret )
        { &autopsy("image writer failed:  ".$img->errstr); }
    else
	{
	if( my $encoding = $argp->{encoding} )
	    {
	    if( $encoding eq "base64" )
		{ $ret = encode_base64( $ret ); }
	    elsif( $encoding eq "image" )
		{ $ret = "<img src='data:image/jpeg;base64,".encode_base64($ret)."'/>"; }
	    }

	&write_file( $argp->{file}, $ret ) if( $argp->{file} );
	}
    print STDERR "qrcode_of() returned.\n";
    return $ret;
    }
1;
