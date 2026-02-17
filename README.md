# Documentation for CPI
Caldwell's Perl Interface - several perl modules that I have found incredibly
useful over the years.

They suffer from the fact that they have grown organically, not been specifically
planned.
<hr>

<table src="src/*.pl src/*.pm"><tr><th align=left><a href='#dt_86zMrNa6h'>common_to_cpi.pl</a></th><td>Convert programs using old COMMON.pm</td></tr>
<tr><th align=left><a href='#dt_86zMrNa6i'>cpi_to_common.pl</a></th><td>Create a COMMON.pm from cpi routines</td></tr>
<tr><th align=left><a href='#dt_86zMrNa6j'>COMMON.pm</a></th><td>(VERY brief explanation of what this file is/does)</td></tr>
<tr><th align=left><a href='#dt_86zMrNa6k'>cpi_arguments.pm</a></th><td>Argument parsing</td></tr>
<tr><th align=left><a href='#dt_86zMrNa6l'>cpi_cache.pm</a></th><td>Create cache for expensive commands</td></tr>
<tr><th align=left><a href='#dt_86zMrNa6m'>cpi_cgi.pm</a></th><td>Various routines for CGI script processing</td></tr>
<tr><th align=left><a href='#dt_86zMrNa6n'>cpi_compress_integer.pm</a></th><td>Convert an integer to base 52</td></tr>
<tr><th align=left><a href='#dt_86zMrNa6o'>cpi_config.pm</a></th><td>Read configuration files</td></tr>
<tr><th align=left><a href='#dt_86zMrNa6p'>cpi_copy_db.pm</a></th><td>Copy database from one format to another</td></tr>
<tr><th align=left><a href='#dt_86zMrNa6q'>cpi_db.pm</a></th><td>Various routines for accessing databases</td></tr>
<tr><th align=left><a href='#dt_86zMrNa6r'>cpi_drivers.pm</a></th><td>Files for reading directory of different handlers</td></tr>
<tr><th align=left><a href='#dt_86zMrNa6s'>cpi_english.pm</a></th><td>Perl routines for handling english eccentricities</td></tr>
<tr><th align=left><a href='#dt_86zMrNa6t'>cpi_escape.pm</a></th><td>Escaping strings for different languages</td></tr>
<tr><th align=left><a href='#dt_86zMrNa6u'>cpi_file.pm</a></th><td>Core routines used by rest of CPI (file i/o etc)</td></tr>
<tr><th align=left><a href='#dt_86zMrNa6v'>cpi_filename.pm</a></th><td>Filename manipulation</td></tr>
<tr><th align=left><a href='#dt_86zMrNa6w'>cpi_hash.pm</a></th><td>Routines integrating various hashes, standardize on one</td></tr>
<tr><th align=left><a href='#dt_86zMrNa6x'>cpi_hash_to_string.pm</a></th><td>Obsoleted by Dumper - hash to string converter</td></tr>
<tr><th align=left><a href='#dt_86zMrNa6y'>cpi_help.pm</a></th><td>Software associated to CGI help suite</td></tr>
<tr><th align=left><a href='#dt_86zMrNa6z'>cpi_inlist.pm</a></th><td>Return item if it's in a list.</td></tr>
<tr><th align=left><a href='#dt_86zMrNa70'>cpi_lock.pm</a></th><td>Simple locking (depends on symlinks being atomic)</td></tr>
<tr><th align=left><a href='#dt_86zMrNa71'>cpi_log.pm</a></th><td>Standardize logger</td></tr>
<tr><th align=left><a href='#dt_86zMrNa72'>cpi_magic_http.pm</a></th><td>Front end to wget or curl</td></tr>
<tr><th align=left><a href='#dt_86zMrNa73'>cpi_make_from.pm</a></th><td>A table of commands to convert one file type to another</td></tr>
<tr><th align=left><a href='#dt_86zMrNa74'>cpi_media.pm</a></th><td>Software to play/display arbitrary file types on local equipment</td></tr>
<tr><th align=left><a href='#dt_86zMrNa75'>cpi_mime.pm</a></th><td>Parse mimes config file for extension and base types</td></tr>
<tr><th align=left><a href='#dt_86zMrNa76'>cpi_perl.pm</a></th><td>Software for writing readable perl</td></tr>
<tr><th align=left><a href='#dt_86zMrNa77'>cpi_qrcode_of.pm</a></th><td>Frontend to QR-Code software (ease of use)</td></tr>
<tr><th align=left><a href='#dt_86zMrNa78'>cpi_reorder.pm</a></th><td>Easy list manipulation</td></tr>
<tr><th align=left><a href='#dt_86zMrNa79'>cpi_send_file.pm</a></th><td>Easy front ends to send faxes, mail etc.</td></tr>
<tr><th align=left><a href='#dt_86zMrNa7A'>cpi_setup.pm</a></th><td>Basically logging in for web applications</td></tr>
<tr><th align=left><a href='#dt_86zMrNa7B'>cpi_sortable.pm</a></th><td>Routines to help sort strings with numbers in them</td></tr>
<tr><th align=left><a href='#dt_86zMrNa7C'>cpi_template.pm</a></th><td>Routines to search and substitute in template files</td></tr>
<tr><th align=left><a href='#dt_86zMrNa7D'>cpi_time.pm</a></th><td>Software for handling time on huge time scales</td></tr>
<tr><th align=left><a href='#dt_86zMrNa7E'>cpi_trace.pm</a></th><td>Front-end to perl stack tracing</td></tr>
<tr><th align=left><a href='#dt_86zMrNa7F'>cpi_trans_shell.pm</a></th><td>Back-end to getting text translated</td></tr>
<tr><th align=left><a href='#dt_86zMrNa7G'>cpi_translate.pm</a></th><td>Suite of software to make it easy to do multi-language software</td></tr>
<tr><th align=left><a href='#dt_86zMrNa7H'>cpi_unique_nbit_color.pm</a></th><td>Generate unique color strings</td></tr>
<tr><th align=left><a href='#dt_86zMrNa7I'>cpi_user.pm</a></th><td>Software for handling a web user</td></tr>
<tr><th align=left><a href='#dt_86zMrNa7J'>cpi_vars.pm</a></th><td>Variables shared with CPI interface</td></tr></table>

<hr>

<div id=docs>

## <a id='dt_86zMrNa6h'>common_to_cpi.pl</a>
Convert programs using old COMMON.pm

## <a id='dt_86zMrNa6i'>cpi_to_common.pl</a>
Create a COMMON.pm from cpi routines

## <a id='dt_86zMrNa6j'>COMMON.pm</a>
(Replace with more full explanation of what this file is or does
spread across multiple lines)

## <a id='dt_86zMrNa6k'>cpi_arguments.pm</a>
Argument parsing

## <a id='dt_86zMrNa6l'>cpi_cache.pm</a>
Create cache for expensive commands

## <a id='dt_86zMrNa6m'>cpi_cgi.pm</a>
Various routines for CGI script processing

## <a id='dt_86zMrNa6n'>cpi_compress_integer.pm</a>
Convert an integer to base 52

## <a id='dt_86zMrNa6o'>cpi_config.pm</a>
Read configuration files

## <a id='dt_86zMrNa6p'>cpi_copy_db.pm</a>
Copy database from one format to another

## <a id='dt_86zMrNa6q'>cpi_db.pm</a>
Various routines for accessing databases

## <a id='dt_86zMrNa6r'>cpi_drivers.pm</a>
Files for reading directory of different handlers

## <a id='dt_86zMrNa6s'>cpi_english.pm</a>
Perl routines for handling english eccentricities

## <a id='dt_86zMrNa6t'>cpi_escape.pm</a>
Escaping strings for different languages

## <a id='dt_86zMrNa6u'>cpi_file.pm</a>
Core routines used by rest of CPI (file i/o etc)

## <a id='dt_86zMrNa6v'>cpi_filename.pm</a>
Filename manipulation

## <a id='dt_86zMrNa6w'>cpi_hash.pm</a>
Routines integrating various hashes, standardize on one

## <a id='dt_86zMrNa6x'>cpi_hash_to_string.pm</a>
Obsoleted by Dumper - hash to string converter

## <a id='dt_86zMrNa6y'>cpi_help.pm</a>
Software associated to CGI help suite

## <a id='dt_86zMrNa6z'>cpi_inlist.pm</a>
Return item if it's in a list.

## <a id='dt_86zMrNa70'>cpi_lock.pm</a>
Simple locking (depends on symlinks being atomic)

## <a id='dt_86zMrNa71'>cpi_log.pm</a>
Standardize logger

## <a id='dt_86zMrNa72'>cpi_magic_http.pm</a>
Front end to wget or curl

## <a id='dt_86zMrNa73'>cpi_make_from.pm</a>
A table of commands to convert one file type to another
This is the crux of nene

## <a id='dt_86zMrNa74'>cpi_media.pm</a>
Software to play/display arbitrary file types on local equipment
This is the crux of show.pl

## <a id='dt_86zMrNa75'>cpi_mime.pm</a>
Parse mimes config file for extension and base types

## <a id='dt_86zMrNa76'>cpi_perl.pm</a>
Software for writing readable perl

## <a id='dt_86zMrNa77'>cpi_qrcode_of.pm</a>
Frontend to QR-Code software (ease of use)

## <a id='dt_86zMrNa78'>cpi_reorder.pm</a>
Easy list manipulation

## <a id='dt_86zMrNa79'>cpi_send_file.pm</a>
Easy front ends to send faxes, mail etc.

## <a id='dt_86zMrNa7A'>cpi_setup.pm</a>
Basically logging in for web applications

## <a id='dt_86zMrNa7B'>cpi_sortable.pm</a>
Routines to help sort strings with numbers in them

## <a id='dt_86zMrNa7C'>cpi_template.pm</a>
Routines to search and substitute in template files

## <a id='dt_86zMrNa7D'>cpi_time.pm</a>
Software for handling time on huge time scales

## <a id='dt_86zMrNa7E'>cpi_trace.pm</a>
Front-end to perl stack tracing

## <a id='dt_86zMrNa7F'>cpi_trans_shell.pm</a>
Back-end to getting text translated

## <a id='dt_86zMrNa7G'>cpi_translate.pm</a>
Suite of software to make it easy to do multi-language software

## <a id='dt_86zMrNa7H'>cpi_unique_nbit_color.pm</a>
Generate unique color strings

## <a id='dt_86zMrNa7I'>cpi_user.pm</a>
Software for handling a web user

## <a id='dt_86zMrNa7J'>cpi_vars.pm</a>
Variables shared with CPI interface</div>

<hr>

There are very few routines here that aren't used by multiple
different pieces of software.








