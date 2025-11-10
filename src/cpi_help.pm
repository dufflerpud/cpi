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

package cpi_help;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( help_strings );
use lib ".";

use cpi_file qw( write_file );
use cpi_template qw( template );
use cpi_vars;
#__END__
1;

#########################################################################
#	Change help= strings in form objects to something more useful.	#
#########################################################################
sub help_strings
    {
    my @ret;
    foreach my $piece ( split(/(help='[\w_\-]+'|help="[\w_\-]+"|help=[\w_\-]+)/,join("",@_) ) )
        {
	if( $piece !~ /help=['"]*([\w_-]*)['"]*/ )
	    { push( @ret, $piece ); }
	else
	    {
	    my $subject = $1;
	    if( -r "$cpi_vars::HELPDIR/$subject.cgi" )
	        {
		push( @ret,
		    ( map { " on$_='help_event(event,&quot;$subject.cgi&quot;);'" }
			@cpi_vars::HELP_EVENTS )  );
		}
	    elsif( -r "$cpi_vars::HELPDIR/$subject.html" )
	        {
		push( @ret,
		    ( map { " on$_='help_event(event,&quot;$subject.html&quot;);'" }
			@cpi_vars::HELP_EVENTS )  );
		}
	    elsif( -r "$cpi_vars::HELPDIR/help_template.cgi" )
	        {
		&write_file( "$cpi_vars::HELPDIR/$subject.cgi",
		    &template( "$cpi_vars::HELPDIR/help_template.cgi",
			"%%MISSING%%", "$cpi_vars::HELPDIR/$subject.cgi") );
		system("chmod 755 $cpi_vars::HELPDIR/$subject.cgi");
		}
	    elsif( -r "$cpi_vars::HELPDIR/help_template.html" )
	        {
		&write_file( "$cpi_vars::HELPDIR/$subject.html",
		    &template( "$cpi_vars::HELPDIR/help_template.html",
			"%%MISSING%%", "$cpi_vars::HELPDIR/$subject.html") );
		}
	    }
	}
    return join("",@ret);
    }

1;
