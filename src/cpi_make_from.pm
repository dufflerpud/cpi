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

package cpi_make_from;
use Exporter;
use AutoLoader;
our @ISA = qw /Exporter/;
#@ISA = qw( Exporter AutoLoader );
##use vars qw ( @ISA @EXPORT );
our @EXPORT_OK = qw( );
our @EXPORT = qw( convert_file generate_rules
 mf_all_enscript_rules mf_all_ffmpeg_rules
 mf_all_mf_obj2obj_rules mf_all_sox_rules
 mf_all_table_fun_rules mf_avivob mf_dump_maps mf_force_file
 mf_get_obj mf_movie2frame mf_obj2obj mf_one_rule
 mf_path_recurse mf_pnm2mpeg mf_pushtype mf_put_obj
 mf_setup_path mf_shcmd mf_sxw2html mf_txt2html mf_txt2pnm
 mf_type_of mf_wavlen mf_wavmpeg2avi mf_wavpnm2mpeg
 mf_xml2dxml );
use lib ".";

use cpi_db qw( dbpop dbread );
use cpi_file qw( echodo autopsy read_file write_file );
use cpi_vars;
use GDBM_File;
use JSON;
use Data::Dumper;
1;
#__END__

my $mf_MODEMINFO = "MT_5634 4";
#my $mf_SOX_STEREO = "-r 44100 -w -c 2";
my $mf_SOX_STEREO = "-r 44100 -c 2";
my $mf_SOX_DSP = "-t ossdsp /dev/dsp";
my $mf_SOX_RMD = "-r 8000 -u -b -c 1 -t .wav -";
my $mf_RMDCMDS = "wavtopvf | pvftormd $mf_MODEMINFO";
my $mf_SOXRMDCMDS = "$mf_SOX_RMD | $mf_RMDCMDS";
my $mf_TEXT_SIZE = "10";
my $mf_TMPDIR = "/var/tmp";
my $mf_TMP = "$mf_TMPDIR/MF.$$";
my $mf_OUTMODE = "";
my $mf_DEFAULT_FONT = "Helvetica14";
my $fm_FFMPEG_WARGS = "ffmpeg -loglevel 0";
my $mf_TABLE_FUN = "/usr/local/bin/table_fun";
my $mf_BGCOLOR = "#ffffff";
my $mf_FGCOLOR = "#000000";

my %mf_type_map =
    (
    "heif"		=> "heic",
    "jfif"		=> "jpeg",
    "jpg"		=> "jpeg",
    "riff"		=> "webp"
    );

my %mf_rule_map =
    (
#    "mp3,out"		=> [ 1, \&mf_shcmd,
#				"mplayer - -quiet >/dev/null" ],
    "rm,out"		=> [ 1, \&mf_shcmd,
				"mplayer - -quiet >/dev/null" ],
#    "txt,out"		=> [ 4, \&mf_shcmd,
#				"text2wave - -otype au > $mf_TMP.au;".
#				" sox -q $mf_TMP.au ".
#				" $mf_SOX_STEREO $mf_SOX_DSP".
#				" vol `sox $mf_TMP.au -t .au /dev/null".
#				" stat -v 2>&1 | grep -v '[a-z]'`" ],
    "txt,out"		=> [ 4, \&mf_shcmd,
				"gtts-cli -f /dev/stdin | paplay" ],
    "txt,mp3"		=> [ 4, \&mf_shcmd,
				"gtts-cli -f /dev/stdin" ],
    "pvf,rmd"		=> [ 4, \&mf_shcmd,
				"pvftowav |".
				" sox -q -t .wav - $mf_SOXRMDCMDS" ],
    "mid,out",		=> [ 1, \&mf_shcmd, "timidity - -OsS" ],
    # This works if it doesn't end up in a pipe.  However, since it may well
    # end up in a pipe, we disable it so that some other interim type is
    # used (ogg at this time).  This is too bad because if we're trying to
    # create a .wav file, we end up outputting ogg and using sox to make the
    # .wav.  It is not clear why timidity dies if it is outputting a wav
    # file into a pipe.
    "mid,wav",		=> [ 1, \&mf_shcmd, "timidity - -OwS -o -" ],
    "mid,au",		=> [ 1, \&mf_shcmd, "timidity - -OuS -o -" ],
    "mid,ogg",		=> [ 1, \&mf_shcmd, "timidity - -OvS -o -" ],
    "pvf,wav",		=> [ 1, \&mf_shcmd, "pvftowav" ],
    "rmd,pvf",		=> [ 1, \&mf_shcmd, "rmdtopvf" ],
    "pvf,wav"		=> [ 1, \&mf_shcmd, "pvftowav" ],
    "pvf,au"		=> [ 1, \&mf_shcmd, "pvftoau" ],
    #"au,pvf"		=> [ 1, \&mf_shcmd, "autopvf" ],
#    "mp3,wav"		=> [ 1, \&mf_shcmd,
#				"lame --decode --mp3input - -" ],
#    "wav,mp3"		=> [ 1, \&mf_shcmd, "lame -S - -" ],
    "m4a,mp3"		=> [ 1, \&mf_shcmd,
    			    "cat > $mf_TMP.m4a;".
			    "ffmpeg -loglevel error ".
			    "-i $mf_TMP.m4a ".
			    "-acodec mp3 -ac 2 -ab 192k ".
			    "$mf_TMP.mp3;".
			    "cat $mf_TMP.mp3" ],
    "mp3,m4a"		=> [ 1, \&mf_shcmd,
    			    "cat > $mf_TMP.mp3;".
			    "ffmpeg -loglevel error ".
			    "-i $mf_TMP.mp3 ".
			    "$mf_TMP.m4a;".
			    "cat $mf_TMP.m4a" ],
    "ogv,mp3"		=> [ 1, \&mf_shcmd,
    			    "cat > $mf_TMP.ogv;".
			    "ffmpeg -loglevel error ".
			    "-i $mf_TMP.ogv ".
			    "-acodec mp3 -ac 2 -ab 192k ".
			    "$mf_TMP.mp3;".
			    "cat $mf_TMP.mp3" ],
    "mp3,ogv"		=> [ 1, \&mf_shcmd,
    			    "cat > $mf_TMP.mp3;".
			    "ffmpeg -loglevel error ".
			    "-i $mf_TMP.mp3 ".
			    "$mf_TMP.ogv;".
			    "cat $mf_TMP.ogv" ],
    "wav,aac"		=> [ 1, \&mf_shcmd,
			    "faac -o $mf_TMP.ac -;".
			    "cat $mf_TMP.ac" ],
    "wav,m4r"		=> [ 1, \&mf_shcmd,
			    "faac -o $mf_TMP.ac -;".
			    "cat $mf_TMP.ac" ],
    "aac,wav"		=> [ 1, \&mf_shcmd,
    			    "cat > $mf_TMP.ac;".
			    "faac -o $mf_TMP.wav $mf_TMP.ac;".
			    "cat $mf_TMP.wav" ],
    "m4r,wav"		=> [ 1, \&mf_shcmd,
    			    "cat > $mf_TMP.ac;".
			    "faac -o $mf_TMP.wav $mf_TMP.ac;".
			    "cat $mf_TMP.wav" ],
    "m4r,aac"		=> [ 1, \&mf_shcmd, "cat -" ],
    "aac,m4r"		=> [ 1, \&mf_shcmd, "cat -" ],
#    "txt,rmd"		=> [ 4, \&mf_shcmd,
#				"text2wave - -otype au > $mf_TMP.au;".
#				" sox -q $mf_TMP.au $mf_SOX_RMD".
#				" vol `sox $mf_TMP.au -t .au /dev/null".
#				" stat -v 2>&1 | grep -v '[a-z]'`".
#				" | $mf_RMDCMDS" ],
#    "mov,rmd"		=> [ 4, \&mf_shcmd,
#				"mplayer -aofile $mf_TMP.wav -ao pcm".
#				" - -vo null -quiet >/dev/null;".
#				" sox -q $mf_TMP.wav $mf_SOXRMDCMDS" ],
##    "avi,rmd"		=> [ 4, \&mf_shcmd,
#				"mplayer -aofile $mf_TMP.wav -ao pcm".
#				" - -vo null -quiet >/dev/null;".
#				" sox -q $mf_TMP.wav $mf_SOXRMDCMDS" ],
    "rm,avi"		=> [ 1, \&mf_shcmd,
				"mencoder -quiet - -o $mf_TMP.avi" .
				" -oac copy -ovc copy;" .
				" cat $mf_TMP.avi" ],
    "rm,mov"		=> [ 1, \&mf_shcmd,
				"mencoder -quiet - -o $mf_TMP.mov" .
				" -oac copy -ovc copy;" .
				" cat $mf_TMP.mov" ],
#    "avi,mov"		=> [ 1, \&mf_shcmd,
#				"cat > $mf_TMP.avi;".
#				" transcode --progress_off -i $mf_TMP.avi ".
#				" -o $mf_TMP.mov -x avi -y mov;".
#				" cat $mf_TMP.mov" ],
#    "mov,avi"		=> [ 1, \&mf_shcmd,
#				"cat > $mf_TMP.mov;".
#				" transcode --progress_off -i $mf_TMP.mov ".
#				" -o $mf_TMP.avi -x mov -y mjpeg;".
#				" cat $mf_TMP.avi" ],
    "3g2,avi"		=> [ 1, \&mf_shcmd,
    				"mencoder -quiet - ".
				"-o $mf_TMP.avi ".
				"-oac pcm -ovc copy; ".
				"cat $mf_TMP.avi" ],
    "avi,3g2"		=> [ 1, \&mf_shcmd,
    				"mencoder -quiet - ".
				"-o $mf_TMP.3g2 ".
				"-oac copy -ovc copy; ".
				"cat $mf_TMP.3g2" ],
    "3gp,avi"		=> [ 1, \&mf_shcmd,
    				"mencoder -quiet - ".
				"-o $mf_TMP.avi ".
				"-oac pcm -ovc copy; ".
				"cat $mf_TMP.avi" ],
    "avi,3gp"		=> [ 1, \&mf_shcmd,
    				"mencoder -quiet - ".
				"-o $mf_TMP.3gp ".
				"-oac copy -ovc copy; ".
				"cat $mf_TMP.3gp" ],
    "txt,pnm"		=> [ 1, \&mf_txt2pnm, "" ],
    "svg,png"		=> [ 1, \&mf_shcmd,
    				"cat - > $mf_TMP.svg; ".
				"rsvg $mf_TMP.svg $mf_TMP.png; ".
				"cat $mf_TMP.png" ],
    "webp,png"		=> [ 1, \&mf_shcmd,
    				"cat - > $mf_TMP.webp; ".
				"convert $mf_TMP.webp $mf_TMP.png; ".
				"cat $mf_TMP.png" ],
    "png,ico"		=> [ 1, \&mf_shcmd,
    				"cat - > $mf_TMP.png; ".
				"convert $mf_TMP.png $mf_TMP.ico; ".
				"cat $mf_TMP.ico" ],
    "ico,png"		=> [ 1, \&mf_shcmd,
    				"cat - > $mf_TMP.ico; ".
				"convert $mf_TMP.ico $mf_TMP.png; ".
				"cat $mf_TMP.png" ],
    "png,webp"		=> [ 1, \&mf_shcmd,
    				"cat - > $mf_TMP.png; ".
				"convert $mf_TMP.png $mf_TMP.webp; ".
				"cat $mf_TMP.webp" ],
    "avif,png"		=> [ 1, \&mf_shcmd,
    				"cat - > $mf_TMP.avif; ".
				"convert $mf_TMP.avif $mf_TMP.png; ".
				"cat $mf_TMP.png" ],
    "png,avif"		=> [ 1, \&mf_shcmd,
    				"cat - > $mf_TMP.png; ".
				"convert $mf_TMP.png $mf_TMP.avif; ".
				"cat $mf_TMP.avif" ],
    "png,svg"		=> [ 1, \&mf_shcmd, "pamtosvg" ],
    "jpeg,pnm"		=> [ 1, \&mf_shcmd, "jpegtopnm -quiet" ],
    "png,pnm"		=> [ 1, \&mf_shcmd, "pngtopnm" ],
    "pnm,png"		=> [ 1, \&mf_shcmd, "pnmtopng" ],
    #"pnm,pdf"		=> [ 1, \&mf_shcmd, "cat - > $mf_TMP.pnm; convert $mf_TMP.pnm $mf_TMP.pdf; cat $mf_TMP.pdf" ],
    "pnm,pdf"		=> [ 1, \&mf_shcmd, "pnmtops -noturn | cat - > $mf_TMP.ps; ps2pdf $mf_TMP.ps -" ],
    "mpeg,mov"		=> [ 1, \&mf_shcmd, "cat - > $mf_TMP.mpeg; $fm_FFMPEG_WARGS -i $mf_TMP.mpeg -strict -2 $mf_TMP.mov; cat $mf_TMP.mov" ],
    "mov,mpeg"		=> [ 1, \&mf_shcmd, "cat - > $mf_TMP.mov; $fm_FFMPEG_WARGS -i $mf_TMP.mov -strict -2 $mf_TMP.mpeg; cat $mf_TMP.mpeg" ],
    "mp4,mov"		=> [ 1, \&mf_shcmd, "cat - > $mf_TMP.mp4; $fm_FFMPEG_WARGS -i $mf_TMP.mp4 -strict -2 $mf_TMP.mov; cat $mf_TMP.mov" ],
    "mp4,mp3"		=> [ 1, \&mf_shcmd, "cat - > $mf_TMP.mp4; $fm_FFMPEG_WARGS -i $mf_TMP.mp4 -strict -2 $mf_TMP.mp3; cat $mf_TMP.mp3" ],
    "mov,mp3"		=> [ 1, \&mf_shcmd, "cat - > $mf_TMP.mov; $fm_FFMPEG_WARGS -i $mf_TMP.mov -strict -2 $mf_TMP.mp3; cat $mf_TMP.mp3" ],
    "m4v,mov"		=> [ 1, \&mf_shcmd, "cat - > $mf_TMP.m4v; $fm_FFMPEG_WARGS -i $mf_TMP.m4v -strict -2 $mf_TMP.mov; cat $mf_TMP.mov" ],
    "mov,mp4"		=> [ 1, \&mf_shcmd, "cat - > $mf_TMP.mov; $fm_FFMPEG_WARGS -i $mf_TMP.mov -strict -2 $mf_TMP.mp4; cat $mf_TMP.mp4" ],
    "mov,m4v"		=> [ 1, \&mf_shcmd, "cat - > $mf_TMP.mov; $fm_FFMPEG_WARGS -i $mf_TMP.mov -strict -2 $mf_TMP.m4v; cat $mf_TMP.m4v" ],
    "webm,mp3"		=> [ 1, \&mf_shcmd, "cat - > $mf_TMP.webm; $fm_FFMPEG_WARGS -i $mf_TMP.webm -strict -2 $mf_TMP.mp3; cat $mf_TMP.mp3" ],
    "webm,mp4"		=> [ 1, \&mf_shcmd, "cat - > $mf_TMP.webm; $fm_FFMPEG_WARGS -i $mf_TMP.webm -strict -2 $mf_TMP.mp4; cat $mf_TMP.mp4" ],
    "webm,mov"		=> [ 1, \&mf_shcmd, "cat - > $mf_TMP.webm; $fm_FFMPEG_WARGS -i $mf_TMP.webm -strict -2 $mf_TMP.mov; cat $mf_TMP.mov" ],
#    "mp4,mp3"		=> [ 1, \&mf_shcmd, "cat - > $mf_TMP.mp4; $fm_FFMPEG_WARGS -i $mf_TMP.mp4 -strict -2 -acodec libmp3lame $mf_TMP.mp3; cat $mf_TMP.mp3" ],
    "tivo,mpeg"		=> [ 1, \&mf_shcmd, "cat - > $mf_TMP.tivo; " .
    				"tivodecode --mak 2292885341 $mf_TMP.tivo" ],
    "tivo,mpeg"		=> [ 1, \&mf_shcmd, "cat - > $mf_TMP.tivo; " .
    				"tivodecode --mak 2292885341 $mf_TMP.tivo" ],
    "mp4,gif"		=> [ 1, \&mf_shcmd,
    				"ffmpeg -loglevel error " .
				"$mf_TMP.gif -i - ;" .
				" cat $mf_TMP.gif" ],
    "mov,gif"		=> [ 1, \&mf_shcmd,
    				"ffmpeg -loglevel error " .
				"$mf_TMP.gif -i - ;" .
				" cat $mf_TMP.gif" ],
    "wav,pnm,mpeg"	=> [ 1, \&mf_wavpnm2mpeg, "" ],
    "wav,mpeg,avi"	=> [ 1, \&mf_wavmpeg2avi, "" ],
    "avi,mpeg"		=> [ 1, \&mf_shcmd,
				"mencoder -quiet - ".
				"-of mpeg -nosound -ovc copy ".
				"-mpegopts format=mpeg1:tsaf " .
				"-o $mf_TMP.mpeg; " .
				" cat $mf_TMP.mpeg" ],
    "rm,jpeg"		=> [ 1, \&mf_movie2frame, "jpg" ],
    "rm,pnm"		=> [ 1, \&mf_movie2frame, "pnm" ],
    "pnm,xwd"		=> [ 1, \&mf_shcmd, "pnmtoxwd" ],
    "xwd,pnm"		=> [ 1, \&mf_shcmd, "xwdtopnm" ],
    "pnm,jpeg"		=> [ 1, \&mf_shcmd, "pnmtojpeg -quiet" ],
    "ppm,jpeg"		=> [ 1, \&mf_shcmd, "pnmtojpeg -quiet" ],
    "pnm,ppm"		=> [ 1, \&mf_shcmd, "ppmtoppm" ],
    "bmp,pnm"		=> [ 1, \&mf_shcmd, "anytopnm" ],
    "pnm,bmp"		=> [ 1, \&mf_shcmd, "pbmtoxbm" ],
    "pnm,gif"		=> [ 1, \&mf_shcmd, "ppmquant 256 | ppmtogif" ],
    "gif,pnm"		=> [ 1, \&mf_shcmd, "giftopnm" ],
    "pnm,ps"		=> [ 1, \&mf_shcmd, "pnmtops -noturn" ],
    #"pnm,txt"		=> [ 6, \&mf_shcmd, "gocr -" ],
    "pnm,txt"		=> [ 6, \&mf_shcmd, "cat > $mf_TMP.pnm; tesseract $mf_TMP.pnm $mf_TMP.txt; cat $mf_TMP.txt.txt" ],
    "heic,jpeg"		=> [ 1, \&mf_shcmd, "cat > $mf_TMP.heic; heif-convert $mf_TMP.heic $mf_TMP.jpg; cat $mf_TMP.jpg" ],
    "txt,ps"		=> [ 1, \&mf_shcmd, "enscript -B --verbose=0 -f $mf_DEFAULT_FONT -p $mf_TMP.ps; cat $mf_TMP.ps" ],
    "txt,pdf"		=> [ 1, \&mf_shcmd, "enscript -B --verbose=0 -f $mf_DEFAULT_FONT -p - | cat - > $mf_TMP.ps; ps2pdf $mf_TMP.ps -" ],
    "prn,pdf"		=> [ 1, \&mf_shcmd, "cat > $mf_TMP.prn; gxps -sDEVICE=pdfwrite -sOutputFile=$mf_TMP.pdf -dNOPAUSE $mf_TMP.prn; cat $mf_TMP.pdf" ],
    "xps,pdf"		=> [ 1, \&mf_shcmd, "cat > $mf_TMP.xps; gxps -sDEVICE=pdfwrite -sOutputFile=$mf_TMP.pdf -dNOPAUSE $mf_TMP.xps; cat $mf_TMP.pdf" ],
    "ps,pdf"		=> [ 1, \&mf_shcmd, "cat > $mf_TMP.ps; ps2pdf $mf_TMP.ps $mf_TMP.pdf; cat $mf_TMP.pdf" ],
    "odg,pdf"		=> [ 1, \&mf_shcmd, "( cat > $mf_TMP.odg; mkdir -p $mf_TMP.dir; cd $mf_TMP.dir; mv $mf_TMP.odg x.odg; libreoffice --headless --convert-to pdf x.odg 1>&2; cat x.pdf; cd /; rm -rf $mf_TMP.dir )" ],
    "odt,pdf"		=> [ 1, \&mf_shcmd, "( cat > $mf_TMP.odt; mkdir -p $mf_TMP.dir; cd $mf_TMP.dir; mv $mf_TMP.odt x.odt; libreoffice --headless --convert-to pdf x.odt 1>&2; cat x.pdf; cd /; rm -rf $mf_TMP.dir )" ],
    "pdf,doc"		=> [ 1, \&mf_shcmd, "( cat > $mf_TMP.pdf; mkdir -p $mf_TMP.dir; cd $mf_TMP.dir; mv $mf_TMP.pdf x.pdf; libreoffice --headless --convert-to 'doc:MS Word 97' x.pdf 1>&2; cat x.doc; cd /; rm -rf $mf_TMP.dir )" ],
    "html,doc"		=> [ 1, \&mf_shcmd, "( cat > $mf_TMP.html; mkdir -p $mf_TMP.dir; cd $mf_TMP.dir; mv $mf_TMP.html x.html; soffice --headless --convert-to 'doc:MS Word 97' x.html 1>&2; cat x.doc; cd /; rm -rf $mf_TMP.dir )" ],
    "pdf,rtf"		=> [ 1, \&mf_shcmd, "( cat > $mf_TMP.pdf; mkdir -p $mf_TMP.dir; cd $mf_TMP.dir; mv $mf_TMP.pdf x.pdf; libreoffice --headless --convert-to 'rtf:Rich Text Format' x.pdf 1>&2; cat x.rtf; cd /; rm -rf $mf_TMP.dir )" ],
    "pdf,ps"		=> [ 1, \&mf_shcmd, "cat > $mf_TMP.pdf; pdf2ps $mf_TMP.pdf $mf_TMP.ps; cat $mf_TMP.ps" ],
    "html,rtf"		=> [ 1, \&mf_shcmd, "( cat > $mf_TMP.html; mkdir -p $mf_TMP.dir; cd $mf_TMP.dir; mv $mf_TMP.html x.html; soffice --headless --convert-to 'rtf:Rich Text Format' x.html 1>&2; cat x.rtf; cd /; rm -rf $mf_TMP.dir )" ],
    "sxw,html"		=> [ 1, \&mf_sxw2html, "" ],
    "html,ps"		=> [ 1, \&mf_shcmd, "html2ps -D -g" ],
#    "pdf,txt"		=> [ 1, \&mf_shcmd, "(cat > $mf_TMP.pdf;".
#    				"pdftotext $mf_TMP.pdf -;".
#				"rm -rf $mf_TMP.pdf)" ],
    "pdf,pnm"		=> [ 1, \&mf_shcmd,
				"( cat > $mf_TMP.pdf;".
				"mkdir -p $mf_TMP.dir;".
				"cd $mf_TMP.dir;".
				"gs -sOutputFile=%08d.pnm".
				" -dNOPAUSE -sDEVICE=pnm -r204x196".
				" -q -dSAFER $mf_TMP.pdf " .
				" >/dev/null </dev/null;".
				"pnmcat -tb *.pnm;".
				"cd /;".
				"rm -rf $mf_TMP.dir )" ],
    "html,txt"		=> [ 3, \&mf_shcmd,
				"cat ->$mf_TMP.txt.html;".
				" lynx -dump $mf_TMP.txt.html" ],
    "html,pdf"		=> [ 1, \&mf_shcmd, "wkhtmltopdf -q - -" ],
    "txt,html"		=> [ 1, \&mf_txt2html, "" ],
    "pnm,tiff"		=> [ 1, \&mf_shcmd,
				"pnmtotiff > $mf_TMP.tiff;".
				" cat $mf_TMP.tiff" ],
    "tiff,pnm"		=> [ 1, \&mf_shcmd,
				"cat ->$mf_TMP.tiff;".
				" tifftopnm $mf_TMP.tiff" ],
    "avi,vob"		=> [ 1, \&mf_avivob ],
    "odt,xml"		=> [ 1, \&mf_shcmd,
				"cat > $mf_TMP.odt;".
				"mkdir $mf_TMP.dir;".
				"unzip -q $mf_TMP.odt -d $mf_TMP.dir;".
				"cat $mf_TMP.dir/content.xml" ],
    "xml,dxml"		=> [ 1, \&mf_xml2dxml ],
    );

my %mf_bestpath = ();
my %mf_costpath = ();
my %mf_possible_sources = ();
my %mf_sorted_rule_map = ();
my %mf_defining = ();
my %mf_filemap = ();
my %mf_commandmap = ();

#########################################################################

#########################################################################
#	Add one rule to the table.					#
#########################################################################
sub mf_one_rule
    {
    my( $fext, $text, $pref, $rule ) = @_;
    $mf_rule_map{"$fext,$text"} =
	[ $pref, \&mf_shcmd, $rule ]
	    if( ($fext ne $text) && ! $mf_rule_map{"$fext,$text"} );
    }

#########################################################################
#	There are all kinds of text files that we just enscript to ps.	#
#########################################################################
sub mf_all_enscript_rules
    {
    my @txt_exts =
	( "adb", "alg", "bas", "cpp", "cob", "f", "gcc", "go", "hs",
	"java", "js", "lsp", "pas", "pdf", "pil", "pl", "py", "rs",
	"ruby", "s", "scala", "sh", "sim", "swift", "tcl" );
    foreach my $fext ( @txt_exts )
	{
        &mf_one_rule( $fext, "ps", 1, "enscript -p -" );
	}
    }

#########################################################################
#	Sox has so many file types that we'll add them automatically.	#
#########################################################################
sub mf_all_sox_rules
    {
    my $defext = "au";
    open( SOXFILES, "sox -h 2>&1 |" ) || &autopsy("Cannot run sox:  $!");
    my %ext_hash = ("ogg",1);
    while( $_ = <SOXFILES> )
	{
	grep( $ext_hash{$_}=1, split(/\s+/,$1) )
	    if( /AUDIO FILE FORMATS: ([^\r\n]*)/ );
#	    if( /Supported file formats: ([^\r\n]*)/ );
	}
    close( SOXFILES );
    my @sox_exts = keys %ext_hash;
    my( $fext, $text );
    foreach $fext ( @sox_exts )
	{
	foreach $text ( @sox_exts )
	    {
	    &mf_one_rule( $fext, $text, 1,
	        "sox -q -t $fext - -t $text $mf_SOX_STEREO -" );
	    }
        &mf_one_rule( $fext, "out", 1,
	    "sox -q -t $fext - $mf_SOX_DSP" );
#        &mf_one_rule( $fext, "txt", 4,
#	    "sox -q -t $fext - -t $fext /dev/null stat 2>&1 | cat -" );
        &mf_one_rule( $fext, "rmd", 4,
	    "sox -q -t $fext - $mf_SOXRMDCMDS" );
        &mf_one_rule( $fext, "pvf", 2,
	    "sox -q -t $fext - -c 1 -t .wav - | wavtopvf" );
	}

    foreach $text ( @sox_exts )
	{
	my $pref = (( $text eq "wav" ) ? 1 : 2 );
	$pref = 4;
#	&mf_one_rule( "txt", $text, $pref,
#	    "text2wave - -otype $defext > $mf_TMP.$defext;".
#	    " sox -q $mf_TMP.$defext $mf_SOX_STEREO -t $text -".
#	    " vol `sox $mf_TMP.$defext -t .$defext /dev/null".
#	    " stat -v 2>&1 | grep -v '[a-z]'`" );
	foreach $fext ( "avi", "mov", "rm", "flv", "swf" )
	    {
	    &mf_one_rule( $fext, $text, $pref,
		"mplayer -aofile $mf_TMP.wav -ao pcm".
		" - -vo null -quiet >/dev/null;".
		" sox -q $mf_TMP.wav $mf_SOX_STEREO -t $text -" );
	    }
	}
    }

#########################################################################
#	ffmpeg has so many file types that we'll add them automatically.#
#########################################################################
sub mf_all_ffmpeg_rules
    {
    my @exts = ( "mkv", "wmv", "avi", "mov", "flv", "swf" );
    foreach my $fext ( @exts )
        {
	&mf_one_rule( $fext, "out", 1, "mplayer - -quiet >/dev/null" );
	&mf_one_rule( $fext, "pnm", 1,
	    "mplayer - -quiet -vo pnm:outdir=$mf_TMP.frames " .
	    "-frames 1 -nosound >/dev/null; " .
	    "cat $mf_TMP.frames/00000001.ppm" );
	&mf_one_rule( $fext, "jpeg", 1,
	    "mplayer - -quiet -vo jpeg:outdir=$mf_TMP.frames " .
	    "-frames 1 -nosound >/dev/null; " .
	    "cat $mf_TMP.frames/00000001.jpg" );
	&mf_one_rule( $fext, "mp3", 1,
	    "cat > $mf_TMP.$fext;" .
	    " $fm_FFMPEG_WARGS -v 0 -i $mf_TMP.$fext -strict -2 -acodec libmp3lame $mf_TMP.mp3;" .
	    "cat $mf_TMP.mp3" );
	foreach my $text ( @exts )
	    {
	    if( $fext ne $text )
	        {
		&mf_one_rule( $fext, $text, 1,
		    "cat > $mf_TMP.$fext;" .
		    " $fm_FFMPEG_WARGS -v 0 -i $mf_TMP.$fext -strict -2 -acodec libmp3lame $mf_TMP.$text;" .
		    "cat $mf_TMP.$text" );
		}
	    }
	}
    }

#########################################################################
#	table_fun has so many file types that we'll add them automatically.#
#########################################################################
sub mf_all_table_fun_rules
    {
    my @fexts = split(/\n/,&read_file("$mf_TABLE_FUN -show=inputs |"));
    my @texts = split(/\n/,&read_file("$mf_TABLE_FUN -show=outputs|"));

    foreach my $fext ( @fexts )
        {
	foreach my $text ( @texts )
	    {
	    if( $fext ne $text )
	        {
		&mf_one_rule( $fext, $text, 1,
		    "$mf_TABLE_FUN -it $fext -ot $text" );
		}
	    }
	}
    }

#########################################################################
#	Push the file onto the stack.					#
#########################################################################
sub mf_pushtype
    {
    my( $ftype ) = @_;
    # print "push [$ftype]\n";
    # $cmdbuf = $mf_filemap{$ftype};
    }

#########################################################################
#	Handle the "simple filter" case.  Actually, $cmd may be quite	#
#	complex, but it is just data to be handed off to a shell.	#
#########################################################################
sub mf_shcmd
    {
    my( $rule, $cmd ) = @_;
    my( $desttype, $srctype, @srctypes ) = split(/,/,$rule);
    
    if( $mf_commandmap{$srctype} )
	{
	$mf_commandmap{$desttype}
	    = "$mf_commandmap{$srctype} | $cmd";
	}
    elsif( $mf_filemap{$srctype} eq "-" )
	{ $mf_commandmap{$desttype} = $cmd; }
    else
        {
        my( @toks ) = split(/([\|;])/,$cmd);
	#print STDERR "toks=[",join(",",@toks),"]\n";
        $mf_commandmap{$desttype} = 
	    ( ( !defined($toks[1]) || $toks[1] eq "" )
	    ? "$cmd < '$mf_filemap{$srctype}' "
	    : join("",
		"$toks[0] < '$mf_filemap{$srctype}' ",@toks[1..$#toks])
	    );
	}
    }

#########################################################################
#	Use mf_commandmap and mf_filemap to determine how to make sure	#
#	that the we have an actual file of the type specified.  Return	#
#	the name of the file.						#
#########################################################################
sub mf_force_file
    {
    my ( $ftype ) = @_;
    my $fname = "$mf_TMP.$ftype";
    if( $_ = $mf_commandmap{$ftype} )
	{ &echodo("$_ > '$fname'"); }
    elsif( ($_ = $mf_filemap{$ftype}) ne "-" )
	{ $fname = $_; }
    else
	{ &echodo("cat - > '$fname'"); }
    return $fname;
    }

#########################################################################
#	Figures out how to read a file of specified extension and	#
#	returns a pointer to its contents (in memory).			#
#	Unfortunately, this leaves around an open database for GDBM.	#
#########################################################################
my $need_to_pop;
sub mf_get_obj
    {
    my( $fext ) = @_;
    my $src = &mf_force_file($fext);
    my $objp;
    if( $fext eq "db" )
	{
	&dbread( $need_to_pop = $src );
	$objp = $cpi_vars::databases{$src};
	}
    else
	{
        undef $need_to_pop;
	my $contents = &read_file( $src );
	if( $fext eq "json" )
	    {
	    eval { $objp = decode_json($contents) };
	    print STDERR "JSON error:  $@\n" if( ! $objp );
	    }
	elsif( $fext eq "po" )
	    {
	    my $VAR1;
	    eval ( $contents );
	    $objp = $VAR1;
	    }
	else
	    { &autopsy("Do not know how to read $fext object in $src."); }
	}
    &autopsy("Read of $fext object in $src failed.") unless( $objp );
    return $objp;
    }

#########################################################################
#	Writes object pointed to by $objp to a file in $text format.	#
#########################################################################
sub mf_put_obj
    {
    my( $text, $objp ) = @_;
    my $dst = "$mf_TMP.db";
    if( $text eq "db" )
	{
	open(TOUCHFILE,">$dst") || &autopsy("Cannot truncate $dst:  $!");
	chmod( 0666, $dst ) || &autopsy("Cannot chmod(0666,$dst):  $!");
	close(TOUCHFILE);
	my %swallow_db;
	tie( %swallow_db, 'GDBM_File', $dst, &GDBM_WRITER, 0666 );
	%swallow_db = %{$objp};
	untie %swallow_db;
	}
    else
    	{
	my $contents;
	if( $text eq "po" )
	    { $contents = Dumper( $objp ); }
	#elsif( $text eq "json" || $text eq "txt" )
	elsif( $text eq "json" )
	    { $contents = JSON->new->ascii->pretty->encode($objp); }
	else
	    { &autopsy("Do not know how to write $text object in $dst."); }
	&autopsy("Could not format $dst for $text.") unless $contents;
	&write_file( $dst, $contents );
	}
    $mf_filemap{$text} = $dst;
    }

#########################################################################
#	Converts one object of one type (in a file) to another.		#
#########################################################################
sub mf_obj2obj
    {
    my( $rule, $cmd ) = @_;
    my( $text, $fext, @rest ) = split(/,/,$rule);
    &mf_put_obj( $text, &mf_get_obj( $fext ) );
    &dbpop( $need_to_pop ) if( $need_to_pop );
    }

#########################################################################
#	Generate all of the rules for mf_obj2obj				#
#########################################################################
sub mf_all_mf_obj2obj_rules
    {
    my @exts = ( "po","json","db" );
    foreach my $fext ( @exts )
        {
	#foreach my $text ( @exts, "txt" )
	foreach my $text ( @exts )
	    {
	    if( $fext ne $text )
	        {
    		$mf_rule_map{"$fext,$text"} =
		    [ 2, \&mf_obj2obj ]
	    	    if( ! $mf_rule_map{"$fext,$text"} );
		}
	    }
	}
    }

#########################################################################
#	Create a PNM file from a text file.  To do this, we need to	#
#	strip out all non-printable characters and compute its height	#
#	and width.  Also need to get a blank PNM file sized correctly	#
#	to label.							#
#########################################################################
sub mf_txt2pnm
    {
    my( $rule, $cmd ) = @_;
    my( $desttype, @srctypes ) = split(/,/,$rule);

    #my($lbgcolor) = ($bgcolor?$bgcolor:"#a0b0b0");
    #my($lfgcolor) = ($fgcolor?$fgcolor:"#ffffff");

    #my($lbgcolor) = ($bgcolor?$bgcolor:"#000000");
    #my($lfgcolor) = ($fgcolor?$fgcolor:"#ffffff");

    my($lbgcolor) = ($mf_BGCOLOR?$mf_BGCOLOR:"#ffffff");
    my($lfgcolor) = ($mf_FGCOLOR?$mf_FGCOLOR:"#000000");

    my( $offset ) = $mf_TEXT_SIZE * 2;

    my $height = 0;
    my $width = 0;
    my $TABLEN = 8;
    my $desttext = "$mf_TMP.cleantext";
    my $scaledpnm = "$mf_TMP.scaled.pnm";
    my $col;
    my $srcpnmfile = (($#srctypes > 1) ? &mf_force_file("pnm") : "");

    #$srcpnmfile = "$mf_TMPDIR/ref.pnm";

    if( $_ = $mf_commandmap{txt} )
	{ open( CTINF, "$_ |" ) || &autopsy("Cannot run $_:  $!"); }
    elsif( ($_ = $mf_filemap{txt}) ne "-" )
    	{ open( CTINF, $_ ) || &autopsy("Cannot read $_:  $!"); }

    open(CTOUT,"> $desttext")|| &autopsy("Cannot write ${desttext}:  $!");

    while($_=(($mf_filemap{txt} eq "-") ? <STDIN> : <CTINF>))
	{
	$height++;
	$col = 0;
	s/[^ -~\t]//g;
	foreach $_ ( split(/(\t)/,$_) )
	    {
	    if( $_ eq "\t" )
		{
		my $tabwidth = int(($col+$TABLEN)/$TABLEN) * $TABLEN - $col;
		$_ = sprintf("%${tabwidth}.${tabwidth}s"," ");
		}
	    print CTOUT $_;
	    $col += length($_);
	    }
	print CTOUT "\n";
	$width = $col if( $col > $width );
	}
    close( CTOUT );
    close( CTINF );	# This may be silly if we're reading from STDIN

    $height = int( ($height+2) * $mf_TEXT_SIZE * 1.75 );
    $width = int( ($width+2) * $mf_TEXT_SIZE );

    if( ! $srcpnmfile )
        { &echodo("ppmmake '$lbgcolor' $width $height > $scaledpnm"); }
    else
    	{
	open(INF,"pnmfile $srcpnmfile |")
	    || &autopsy("Cannot pnmfile $srcpnmfile:  $!");
	$_ = <INF>;
	close( INF );
	&autopsy("pnmfile failed to size $srcpnmfile")
	    if( ! / (\d+) by (\d+) / );
	my ( $inpixelwidth, $inpixelheight ) = ( $1, $2 );
	my( $wratio ) = $width / $inpixelwidth;
	my( $hratio ) = $height / $inpixelheight;
	my( $ratio ) = ( $wratio > $hratio ? $wratio : $hratio );
	if( $ratio <= 1 )		# If text is smaller than graphic,
	    { $scaledpnm = $srcpnmfile; }	# just use it
	else
	    {
	    if( $mf_OUTMODE eq "tile" )
		{ &echodo("pnmtile $width $height $srcpnmfile > $scaledpnm"); }
	    elsif( $ratio <= 3 )
		{ &echodo("pnmscale $ratio $srcpnmfile > $scaledpnm"); }
	    else
		{
		my($efac) = 2*int($ratio/2) - 1;
		&echodo("pnmscale $ratio $srcpnmfile | ".
			"pnmsmooth -size $efac $efac > $scaledpnm");
		}
	    }
	}

    $mf_commandmap{$desttype} =
	"ppmlabel -background transparent -colour '$lfgcolor' ".
	"-x $mf_TEXT_SIZE -y $offset -size $mf_TEXT_SIZE ".
	"-file $desttext $scaledpnm";
    }

#########################################################################
#	Convert a movie understood by transcode to single frame (jpeg).	#
#########################################################################
sub mf_movie2frame
    {
    my( $rule, $otype ) = @_;
    my( $desttype, @srctypes ) = split(/,/,$rule);
    my $srctype = $srctypes[0];
    my $oext = ( ( $desttype eq "jpeg" ) ? "jpg" : "ppm" );
    my $destdir = "$mf_TMP.frames";
    my $destfile = "$destdir/00000001.$oext";
    my $cmd = "mplayer -quiet - -vo $desttype:outdir=$destdir -frames 1 -nosound";

    if( $mf_commandmap{$srctype} )
	{ &echodo( "$mf_commandmap{$srctype} | $cmd" ); }
    elsif( $mf_filemap{$srctype} eq "-" )
	{ &echodo( $cmd ); }
    else
	{ &echodo( "$cmd < $mf_filemap{$srctype}" ); }

    $mf_filemap{$desttype} = $destfile;
    }

#########################################################################
#	Convert avi file to vob file (suitable for burning to DVD).	#
#########################################################################
sub mf_avivob
    {
    my( $rule, $cmd ) = @_;
    my( $desttype, @srctypes ) = split(/,/,$rule);

    my $src = &mf_force_file("avi");
    my $dst = "$mf_TMP.vob";
    my $srctype = $srctypes[0];

    my $splitfiles = "$mf_TMP.avivob";
    my $c="transcode --progress_off -V -y mpeg,mp2enc -F dn,,dvd.prof -i $src -o $splitfiles";
    &echodo($c);
    $c = "tcmplex -o X -i $splitfiles.m2v -p $splitfiles.mpa -m d";
    &echodo($c);

    $mf_filemap{$desttype} = $dst;
    }

#########################################################################
#	Use sox to determine length a wav file.				#
#########################################################################
sub mf_wavlen
    {
    my( $srcwavfile ) = @_;
    my $file_len;
    open( PWA, "sox -q $srcwavfile -t .wav /dev/null stat 2>&1 |" )
    	|| &autopsy("Cannot sox $srcwavfile to find length");
    while( $_ = <PWA> )
        {
	$file_len = $1 if( /^Length .*:\s+([\d\.]+)/ );
	}
    close( PWA );
    return $file_len;
    }

#########################################################################
#	Given a pnm file and a duration in seconds, return mpeg file.	#
#########################################################################
sub mf_pnm2mpeg
    {
    my( $srcpnmfile, $file_len, $mpgfile, $desttype ) = @_;
    my $FRAME_RATE = 24;	# Since picture doesn't change, we want
				# smallest value.  Unfortunately, 24 is it.
    my( $infilestring ) = "";
    my $iterations = int( $FRAME_RATE * $file_len );
    my $pattern = "IB";
    print "FRAME_RATE=$FRAME_RATE file_len=$file_len Iterations=$iterations.\n";
    for( $_=$iterations; $_ > 0; $_-- )
	{
	$infilestring .= "$srcpnmfile\n";
	$pattern .= "P";
	}

    open( PARAMS, ">$mf_TMP.params" )
	|| &autopsy("Cannot write $mf_TMP.params:  $!");
print PARAMS <<CEOF;
PATTERN	$pattern
OUTPUT			$mpgfile
BASE_FILE_FORMAT	PNM
GOP_SIZE		60
SLICES_PER_FRAME	1
FRAME_RATE		$FRAME_RATE
PIXEL			FULL
RANGE			2
PSEARCH_ALG		LOGARITHMIC
BSEARCH_ALG		CROSS2
IQSCALE			1
PQSCALE			1
BQSCALE			1
REFERENCE_FRAME		DECODED
INPUT_CONVERT		*
INPUT_DIR		/
INPUT
$infilestring
END_INPUT
CEOF
    close( PARAMS );
    my $cmd = "ppmtompeg -realquiet $mf_TMP.params";
    &echodo( $cmd );
    $mf_filemap{$desttype} = $mpgfile;
    }

#########################################################################
#	Make a mpeg out of a pnm and .wav file.				#
#########################################################################
sub mf_wavpnm2mpeg
    {
    my( $rule, $cmd ) = @_;
    my( $desttype, @srctypes ) = split(/,/,$rule);
    my $mpgfile = "$mf_TMP.mpeg";

    my $srcwavfile = &mf_force_file( "wav" );
    my $srcpnmfile = &mf_force_file( "pnm" );
    &mf_pnm2mpeg(
	$srcpnmfile, &mf_wavlen($srcwavfile), $mpgfile, $desttype );
    }

#########################################################################
#	Make a movie out of a mpeg and .wav file.			#
#########################################################################
sub mf_wavmpeg2avi
    {
    my( $rule, $cmd ) = @_;
    my( $desttype, @srctypes ) = split(/,/,$rule);

    my $srcwavfile = &mf_force_file( "wav" );
    my $srcmpeg = &mf_force_file( "mpeg" );

    $cmd = "transcode --progress_off -i $srcmpeg -p $srcwavfile -y mjpeg ".
	"-o $mf_TMP.mjpeg";
    $cmd = "mencoder $srcmpeg -audiofile $srcwavfile -o $mf_TMP.mjpeg -oac copy -ovc copy";
    &echodo( $cmd );
    $mf_filemap{$desttype} = "$mf_TMP.mjpeg";
    }

#########################################################################
#	Simple filter to convert .sxw xml files to html.		#
#########################################################################
sub mf_sxw2html
    {
    my( $rule, $cmd ) = @_;
    my( $desttype, @srctypes ) = split(/,/,$rule);
    my $destfile = "$mf_TMP.2.html";
    my $srcsxwfile = &mf_force_file( "sxw" );
    
    open( INF, "unzip -qq -p -C $srcsxwfile content.xml |" )
	|| &autopsy("Cannot unzip $srcsxwfile:  $!");
    open(OUTF,"> $destfile") || &autopsy("Cannot write $destfile:  $!");
    print OUTF "<html><head><title>SXW file converted to HTML</title><style>\n";
    print OUTF "<!--\n";
    print OUTF "td {font-size:14;font-family:verdana,lucida,arial}\n";
    print OUTF "p {font-size:14;font-family:verdana,lucida,arial}\n";
    print OUTF "-->\n";
    print OUTF "</style></head><body><font face=verdana,lucida size=2>\n";
    while( $_ = <INF> )
	{
	s/\200/"/g;
	s/[^ -~\n\t]//g;
	s/text:p/p/g;
	s/ text:style-name="P[0-9][0-9]"//g;
	s/ text:style-name="Standard"//g;
	s/\<table:table-row/tr bgcolor=white/g;
	s/\<table:table-cell/td/g;
	s/\<table:table /table border=0 cellpadding=2 cellspacing=1 bgcolor=666666 /g;
	s/table:table-row/tr/g;
	s/table:table-cell/td/g;
	s/table:table/table/g;
	s/text:list-item/li/g;
	s/text:ordered-list/ol/g;
	s/text:unordered-list/ul/g;
	s/<\/td>/\&nbsp;<\/td>/g;
	s/ end text:id="IMark1153870916"//g;
	s/ text:style-name="Standard"//g;
	s/ start text:id="IMark1153870916" text:outline-level="1"//g;
	s/ end text:id="IMark1153871324"//g;
	s/<text:tab-stop>//g;
	s/table:value-type="string"//g;
	s/<text:index-entry-text>//g;
	s/<text:index-entry-chapter-number>//g;
	s/ table:style-name="Table[0-9].[A-Z][0-9]"//g;
	s/table:style-name="Table[0-9].[A-Z]"//g;
	s/<text:tab-stop\/>/\&nbsp;\&nbsp;\&nbsp;\&nbsp;\&nbsp;/g;
	s/<b\/>//g;
	s/<text:index-entry-text\/>//g;
	s/<text:index-entry-page-number\/>//g;
	s/<text:s\/>//g;
	s/<\/b>//g;
	s/<table-column \/>//g;
	s/<table-header-rows>//g;
	s/^[1-9]<\/p>//g;
	s/<\/text:table-of-content-entry-template>//g;
	s/<text:span text:style-name="T1">//g;
	s/<\/text:span>//g;
	s/\&nbsp;\&nbsp;[0-9]/\&nbsp;\&nbsp;/g;
	print OUTF $_;
	}
    print OUTF "</body></html>\n";
    close( INF );
    close( OUTF );
    $mf_filemap{$desttype} = $destfile;
    }

#########################################################################
#	Convert input from text to html.				#
#########################################################################
sub mf_txt2html
    {
    my( $rule, $cmd ) = @_;
    my( $desttype, @srctypes ) = split(/,/,$rule);
    my( $destfile ) = "$mf_TMP.txt.html";

    if( $_ = $mf_commandmap{txt} )
	{ open( CTINF, "$_ |" ) || &autopsy("Cannot run $_:  $!"); }
    elsif( ($_ = $mf_filemap{txt}) ne "-" )
    	{ open( CTINF, $_ ) || &autopsy("Cannot read $_:  $!"); }
    open(CTOUT,"> $destfile") || &autopsy("Cannot write $destfile:  $!");
    print CTOUT "<pre>";
    while($_=(($mf_filemap{txt} eq "-") ? <STDIN> : <CTINF>))
	{
        s/&/\&amp;/g;
        s/</\&lt;/g;
        s/>/\&gt;/g;
	print CTOUT $_;
	}
    print CTOUT "</pre>\n";
    close( CTOUT );
    close( CTINF );
    $mf_filemap{$desttype} = $destfile;
    }

#########################################################################
#	Convert input from XML to easy to debug xml			#
#########################################################################
sub mf_xml2dxml
    {
    my( $rule, $cmd ) = @_;
    my( $desttype, @srctypes ) = split(/,/,$rule);
    my( $destfile ) = "$mf_TMP.dxml";

    if( $_ = $mf_commandmap{xml} )
	{ open( CTINF, "$_ |" ) || &autopsy("Cannot run $_:  $!"); }
    elsif( ($_ = $mf_filemap{xml}) ne "-" )
    	{ open( CTINF, $_ ) || &autopsy("Cannot read $_:  $!"); }
    open(CTOUT,"> $destfile") || &autopsy("Cannot write $destfile:  $!");

    my $pgraph = $/;
    undef $/;
    $_ = (($mf_filemap{xml} eq "-") ? <STDIN> : <CTINF>);
    $/ = $pgraph;

    my $level = 0;
    foreach my $piece ( split(/(<.*?>)/) )
	{
	if( $piece =~ m:</.*: )
	    {
	    $level--;
	    print CTOUT " " x ($level * 4 + 2), "}", $piece, "\n";
	    }
	elsif( $piece =~ m:<.*/>: )
	    {
	    print CTOUT " " x ($level * 4), $piece, "\n";
	    }
	elsif( $piece =~ m:<.*>: )
	    {
	    print CTOUT " " x ($level * 4 + 2), $piece, "{", "\n";
	    $level++;
	    }
	else
	    {
	    print CTOUT " " x ($level * 4), $piece, "\n";
	    }
	}
    close( CTOUT );
    close( CTINF );
    $mf_filemap{$desttype} = $destfile;
    }

#########################################################################
#	Recursive routine to find best path to get from source files	#
#	to destination file.						#
#########################################################################
sub mf_path_recurse
    {
no warnings 'recursion';
    my( $dest, $level ) = @_;

    return -1 if( $mf_defining{$dest}++ );
    if( ! defined($mf_costpath{ $dest }) )
	{
	my $srcextlist;
	my $lenmf_bestpath;
	my @pr_mf_bestpath = ();
	undef $lenmf_bestpath;
	if( defined( $mf_possible_sources{$dest} ) )
	    {
	    foreach $srcextlist ( @{$mf_possible_sources{$dest} } )
		{
		my $lenpath =
		    ${$mf_sorted_rule_map{"$dest,$srcextlist"}}[0];
		my $ext;
		my @pathnodes = ();
		my $add_to_path = -1;
		foreach $ext ( split(/,/,$srcextlist) )
		    {
		    #print STDERR "CMC ext=[$ext], level=[$level]\n";
		    $add_to_path = &mf_path_recurse($ext,$level+1);
		    last if( $add_to_path < 0 );
		    $lenpath += $add_to_path;
		    push( @pathnodes, @{ $mf_bestpath{$ext} } );
		    }
		next if( $add_to_path < 0 );
		next if( defined($lenmf_bestpath)
			&& ($lenpath >= $lenmf_bestpath) );
		$lenmf_bestpath = $lenpath;
		@pr_mf_bestpath = (@pathnodes,"$dest,$srcextlist");
		}
	    }
	if( ! defined( $lenmf_bestpath ) )
	    { $mf_costpath{$dest} = -1; }
	else
	    {
	    @{ $mf_bestpath{$dest} } = @pr_mf_bestpath;
	    $mf_costpath{$dest} = $lenmf_bestpath;
	    }
	}
    undef $mf_defining{$dest};
    return $mf_costpath{$dest};
    }

#########################################################################
#	Return type of filename specified.  Hoping that there are no	#
#	file types that differ base case only.				#
#									#
#	In the vast majority of cases, the type of a file IS its	#
#	extension (or lower case version of it).  We could, I suppose,	#
#	do a "file" and look in mime types - but that would only work	#
#	for source files, since	presumably the destination file doesn't	#
#	have any data yet.						#
#########################################################################
sub mf_type_of
    {
    my( $fn ) = @_;
    if( $fn =~ /.*\.([a-zA-Z0-9]+)$/ )
        {
	my $e = lc( $1 );
	return ( $mf_type_map{$e} ? $mf_type_map{$e} : $e )
	};
    return "UNKNOWN";
    }

#########################################################################
#	Setup database for recursion and then call recursive routine.	#
#########################################################################
sub mf_setup_path
    {
    my( $destfile, @srcfiles ) = @_;
    my $dest = &mf_type_of( $destfile );
    my @srcexts = ();
    my( $srcext, $fn );
    foreach $fn ( @srcfiles )
	{
	$srcext = &mf_type_of( $fn );
	$mf_filemap{$srcext} = ( ( $fn eq "-.$srcext" ) ? "-" : $fn );
	$mf_costpath{$srcext} = 0;
	push( @{$mf_bestpath{$srcext}}, $srcext );
	@{$mf_sorted_rule_map{$srcext}}
	    = ( 1, \&mf_pushtype, $srcext );
	}
    
    my $path;
    foreach $path ( keys %mf_rule_map )
	{
	my @pathtoks = split(/,/,$path);
	my $destext = $pathtoks[ $#pathtoks ];
	my @srcexts = sort( @pathtoks[0..$#pathtoks-1] );
	my ( $sorted_srcexts ) = join(",",@srcexts);
	$mf_sorted_rule_map{"$destext,$sorted_srcexts"}
	    = $mf_rule_map{$path};
	push( @{$mf_possible_sources{$destext} }, $sorted_srcexts );
	}
no warnings 'recursion';
    return &mf_path_recurse( $dest, 0 );
    }

#########################################################################
#	Execute the path.						#
#########################################################################
sub generate_rules
    {
    my( $destfile, @srcfiles ) = @_;

    &mf_all_sox_rules();
    &mf_all_ffmpeg_rules();
    &mf_all_enscript_rules();
    &mf_all_table_fun_rules();
    &mf_all_mf_obj2obj_rules();

    &autopsy("Can't generate $destfile from ".join(",",@srcfiles).".")
	if( &mf_setup_path( $destfile, @srcfiles ) < 0 );

    my $ind;
    foreach $ind ( @{ $mf_bestpath{ &mf_type_of($destfile) } } )
	{
	&{ ${$mf_sorted_rule_map{$ind}}[1] }
	    ( $ind, ${$mf_sorted_rule_map{$ind}}[2] );
	}
    }

#########################################################################
#	Debug:  Dump mf_commandmap and mf_filemap for the types.	#
#########################################################################
sub mf_dump_maps
    {
    foreach $_ ( sort keys %mf_filemap )
	{ print "mf_filemap{$_}=\"$mf_filemap{$_}\"\n"; }
    foreach $_ ( sort keys %mf_commandmap )
	{ print "mf_commandmap{$_}=\"$mf_commandmap{$_}\"\n"; }
    }

#########################################################################
#	This retrieves the commands from the generated rule structures	#
#	and executes them to create the files.  It then cleans up any	#
#	/tmp files it may have created in the process.			#
#	NOTE:  It can now be called in two ways:			#
#	    With 1 arg (destfile) - assume &generate_rules prev called	#
#	    With >1 arg, we're doing it all.  Stand back!		#
#########################################################################
sub convert_file
    {
    &generate_rules( @_ ) if( scalar(@_) > 1 );
    my( $destfile ) = @_;
    my( $destext ) = &mf_type_of( $destfile );
    my( $deststr ) = ( ($destfile eq "-.$destext") ? "" : " > $destfile" );
    #print STDERR "convert_file(df=$destfile de=$destext ds=$deststr)\n";
    $_ = $mf_commandmap{ &mf_type_of( $destfile ) };
    my( $srcstr ) = ( $_ ? $_ : "cat $mf_filemap{$destext}" );
    my( $cmd ) = "$srcstr$deststr";
    &echodo($cmd);
    opendir(TD,$mf_TMPDIR) ||
	&autopsy("Cannot opendir($mf_TMPDIR):  $!");
    my ( @torm ) = ();
    while( $_ = readdir( TD ) )
	{
	$_ = "$mf_TMPDIR/$_";
	push( @torm, $_ ) if( $_ =~ m+^$mf_TMP\.+ );
	}
    closedir( TD );
    system("rm -rf ".join(" ",@torm)) if( @torm );
    }

1;
