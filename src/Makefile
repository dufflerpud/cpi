# Makefile to build CPI
CURRENT_MAKEFILE=$(lastword $(MAKEFILE_LIST))
MODULES=$(shell ls cpi_*.pm | sed -e 's/\.pm//')
INSTALLDIR=/usr/local/lib/perl
CPI_USER_DIR=/usr/local/projects/common
REQUIRED_MODULES=$(shell \
    grep '^use ' cpi_*.pm | sed -e 's/.*:use //' -e 's/ .*//' -e 's/;//' | \
    grep -v '^cpi_' | \
    grep -v '^lib' | \
    grep -v '^strict' | \
    grep -v '^Exporter' | \
    grep -v '^AutoLoader' | \
    sort -u)

No_argument_supplied:
	id
	@echo "You must specify either 'install', 'remake' or 'all_modules'"
	@false

show_required_modules:
	cpan -O $(REQUIRED_MODULES)

install_required_modules:
	cpan install $(REQUIRED_MODULES)

install:
	@[ "$(INSTALLDIR)" != "." ] || (echo "Cannot install to CWD." && false)
	@id | grep uid=0 || (echo "Must install as root." && false)
	rm -rf $(INSTALLDIR)/cpi_* $(INSTALLDIR)/auto/cpi_*
	for m in *.pm; do \
	    sed -e 's:use lib ".":use lib "$(INSTALLDIR)":' < $$m > $(INSTALLDIR)/$$m; \
	done
	cp $(CURRENT_MAKEFILE) $(INSTALLDIR)/Makefile.cpi
	cd $(INSTALLDIR); make -f Makefile.cpi all_modules
	mkdir -p $(CPI_USER_DIR)/db $(CPI_USER_DIR)/SIDS
	chmod 755 $(CPI_USER_DIR)
	chmod 777 $(CPI_USER_DIR)/db $(CPI_USER_DIR)/SIDS
	[ -f $(CPI_USER_DIR)/db/accounts.db ] || /usr/local/projects/cpi/tests/cpi_test.pl \
	    -database $(CPI_USER_DIR)/db/accounts.db \
	    -init \
	    -administrator administrator \
	    -password "CHANGEME!"
	chmod 666 $(CPI_USER_DIR)/db/accounts.db

remake:
	rm -rf auto/cpi_*
	make -f $(CURRENT_MAKEFILE) all_modules

all_modules:\
	auto/cpi_vars/autosplit.ix\
	auto/cpi_cache/autosplit.ix\
	auto/cpi_sortable/autosplit.ix\
	auto/cpi_reorder/autosplit.ix\
	auto/cpi_mime/autosplit.ix\
	auto/cpi_hash_to_string/autosplit.ix\
	auto/cpi_lock/autosplit.ix\
	auto/cpi_cgi/autosplit.ix\
	auto/cpi_file/autosplit.ix\
	auto/cpi_drivers/autosplit.ix\
	auto/cpi_compress_integer/autosplit.ix\
	auto/cpi_magic_http/autosplit.ix\
	auto/cpi_config/autosplit.ix\
	auto/cpi_trans_none/autosplit.ix\
	auto/cpi_db/autosplit.ix\
	auto/cpi_log/autosplit.ix\
	auto/cpi_filename/autosplit.ix\
	auto/cpi_english/autosplit.ix\
	auto/cpi_template/autosplit.ix\
	auto/cpi_setup/autosplit.ix\
	auto/cpi_translate/autosplit.ix\
	auto/cpi_hash/autosplit.ix\
	auto/cpi_escape/autosplit.ix\
	auto/cpi_time/autosplit.ix\
	auto/cpi_qrcode_of/autosplit.ix\
	auto/cpi_send_file/autosplit.ix\
	auto/cpi_copy_db/autosplit.ix\
	auto/cpi_user/autosplit.ix\
	auto/cpi_make_from/autosplit.ix\
	auto/cpi_trace/autosplit.ix\
	auto/cpi_help/autosplit.ix\
	auto/cpi_inlist/autosplit.ix\
	auto/cpi_arguments/autosplit.ix\
	auto/cpi_perl/autosplit.ix\
	auto/cpi_unique_nbit_color/autosplit.ix
auto/cpi_cache/autosplit.ix:\
	auto/cpi_file/autosplit.ix\
	auto/cpi_filename/autosplit.ix\
	auto/cpi_hash/autosplit.ix\
	auto/cpi_magic_http/autosplit.ix\
	auto/cpi_vars/autosplit.ix
	perl cpi_cache.pm
	[ -d auto/cpi_cache ] || mkdir -p auto/cpi_cache
	mv cpi_cache.pm cpi_cache.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_cache.compiling > cpi_cache.pm
	perl -MAutoSplit -e 'autosplit(cpi_cache,auto,0,1,1)' || excode=0
	mv cpi_cache.compiling cpi_cache.pm
auto/cpi_cgi/autosplit.ix:\
	auto/cpi_file/autosplit.ix\
	auto/cpi_vars/autosplit.ix
	perl cpi_cgi.pm
	[ -d auto/cpi_cgi ] || mkdir -p auto/cpi_cgi
	mv cpi_cgi.pm cpi_cgi.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_cgi.compiling > cpi_cgi.pm
	perl -MAutoSplit -e 'autosplit(cpi_cgi,auto,0,1,1)' || excode=0
	mv cpi_cgi.compiling cpi_cgi.pm
auto/cpi_compress_integer/autosplit.ix:
	perl cpi_compress_integer.pm
	[ -d auto/cpi_compress_integer ] || mkdir -p auto/cpi_compress_integer
	mv cpi_compress_integer.pm cpi_compress_integer.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_compress_integer.compiling > cpi_compress_integer.pm
	perl -MAutoSplit -e 'autosplit(cpi_compress_integer,auto,0,1,1)' || excode=0
	mv cpi_compress_integer.compiling cpi_compress_integer.pm
auto/cpi_perl/autosplit.ix:
	perl cpi_perl.pm
	[ -d auto/cpi_perl ] || mkdir -p auto/cpi_perl
	mv cpi_perl.pm cpi_perl.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_perl.compiling > cpi_perl.pm
	perl -MAutoSplit -e 'autosplit(cpi_perl,auto,0,1,1)' || excode=0
	mv cpi_perl.compiling cpi_perl.pm
auto/cpi_unique_nbit_color/autosplit.ix:
	perl cpi_unique_nbit_color.pm
	[ -d auto/cpi_unique_nbit_color ] || mkdir -p auto/cpi_unique_nbit_color
	mv cpi_unique_nbit_color.pm cpi_unique_nbit_color.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_unique_nbit_color.compiling > cpi_unique_nbit_color.pm
	perl -MAutoSplit -e 'autosplit(cpi_unique_nbit_color,auto,0,1,1)' || excode=0
	mv cpi_unique_nbit_color.compiling cpi_unique_nbit_color.pm
auto/cpi_config/autosplit.ix:\
	auto/cpi_file/autosplit.ix
	perl cpi_config.pm
	[ -d auto/cpi_config ] || mkdir -p auto/cpi_config
	mv cpi_config.pm cpi_config.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_config.compiling > cpi_config.pm
	perl -MAutoSplit -e 'autosplit(cpi_config,auto,0,1,1)' || excode=0
	mv cpi_config.compiling cpi_config.pm
auto/cpi_copy_db/autosplit.ix:\
	auto/cpi_config/autosplit.ix\
	auto/cpi_db/autosplit.ix\
	auto/cpi_file/autosplit.ix\
	auto/cpi_vars/autosplit.ix
	perl cpi_copy_db.pm
	[ -d auto/cpi_copy_db ] || mkdir -p auto/cpi_copy_db
	mv cpi_copy_db.pm cpi_copy_db.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_copy_db.compiling > cpi_copy_db.pm
	perl -MAutoSplit -e 'autosplit(cpi_copy_db,auto,0,1,1)' || excode=0
	mv cpi_copy_db.compiling cpi_copy_db.pm
auto/cpi_db/autosplit.ix:\
	auto/cpi_compress_integer/autosplit.ix\
	auto/cpi_config/autosplit.ix\
	auto/cpi_file/autosplit.ix\
	auto/cpi_lock/autosplit.ix\
	auto/cpi_inlist/autosplit.ix\
	auto/cpi_trace/autosplit.ix\
	auto/cpi_vars/autosplit.ix
	perl cpi_db.pm
	[ -d auto/cpi_db ] || mkdir -p auto/cpi_db
	mv cpi_db.pm cpi_db.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_db.compiling > cpi_db.pm
	perl -MAutoSplit -e 'autosplit(cpi_db,auto,0,1,1)' || excode=0
	mv cpi_db.compiling cpi_db.pm
auto/cpi_escape/autosplit.ix:
	perl cpi_escape.pm
	[ -d auto/cpi_escape ] || mkdir -p auto/cpi_escape
	mv cpi_escape.pm cpi_escape.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_escape.compiling > cpi_escape.pm
	perl -MAutoSplit -e 'autosplit(cpi_escape,auto,0,1,1)' || excode=0
	mv cpi_escape.compiling cpi_escape.pm
auto/cpi_file/autosplit.ix:\
	auto/cpi_log/autosplit.ix\
	auto/cpi_vars/autosplit.ix
	perl cpi_file.pm
	[ -d auto/cpi_file ] || mkdir -p auto/cpi_file
	mv cpi_file.pm cpi_file.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_file.compiling > cpi_file.pm
	perl -MAutoSplit -e 'autosplit(cpi_file,auto,0,1,1)' || excode=0
	mv cpi_file.compiling cpi_file.pm
auto/cpi_drivers/autosplit.ix:\
	auto/cpi_filename/autosplit.ix \
	auto/cpi_template/autosplit.ix \
	auto/cpi_file/autosplit.ix
	perl cpi_drivers.pm
	[ -d auto/cpi_drivers ] || mkdir -p auto/cpi_drivers
	mv cpi_drivers.pm cpi_drivers.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_drivers.compiling > cpi_drivers.pm
	perl -MAutoSplit -e 'autosplit(cpi_drivers,auto,0,1,1)' || excode=0
	mv cpi_drivers.compiling cpi_drivers.pm
auto/cpi_filename/autosplit.ix:
	perl cpi_filename.pm
	[ -d auto/cpi_filename ] || mkdir -p auto/cpi_filename
	mv cpi_filename.pm cpi_filename.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_filename.compiling > cpi_filename.pm
	perl -MAutoSplit -e 'autosplit(cpi_filename,auto,0,1,1)' || excode=0
	mv cpi_filename.compiling cpi_filename.pm
auto/cpi_english/autosplit.ix:
	perl cpi_english.pm
	[ -d auto/cpi_english ] || mkdir -p auto/cpi_english
	mv cpi_english.pm cpi_english.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_english.compiling > cpi_english.pm
	perl -MAutoSplit -e 'autosplit(cpi_english,auto,0,1,1)' || excode=0
	mv cpi_english.compiling cpi_english.pm
auto/cpi_hash/autosplit.ix:\
	auto/cpi_file/autosplit.ix
	perl cpi_hash.pm
	[ -d auto/cpi_hash ] || mkdir -p auto/cpi_hash
	mv cpi_hash.pm cpi_hash.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_hash.compiling > cpi_hash.pm
	perl -MAutoSplit -e 'autosplit(cpi_hash,auto,0,1,1)' || excode=0
	mv cpi_hash.compiling cpi_hash.pm
auto/cpi_hash_to_string/autosplit.ix:\
	auto/cpi_escape/autosplit.ix
	perl cpi_hash_to_string.pm
	[ -d auto/cpi_hash_to_string ] || mkdir -p auto/cpi_hash_to_string
	mv cpi_hash_to_string.pm cpi_hash_to_string.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_hash_to_string.compiling > cpi_hash_to_string.pm
	perl -MAutoSplit -e 'autosplit(cpi_hash_to_string,auto,0,1,1)' || excode=0
	mv cpi_hash_to_string.compiling cpi_hash_to_string.pm
auto/cpi_help/autosplit.ix:\
	auto/cpi_file/autosplit.ix\
	auto/cpi_template/autosplit.ix\
	auto/cpi_vars/autosplit.ix
	perl cpi_help.pm
	[ -d auto/cpi_help ] || mkdir -p auto/cpi_help
	mv cpi_help.pm cpi_help.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_help.compiling > cpi_help.pm
	perl -MAutoSplit -e 'autosplit(cpi_help,auto,0,1,1)' || excode=0
	mv cpi_help.compiling cpi_help.pm
auto/cpi_lock/autosplit.ix:\
	auto/cpi_file/autosplit.ix\
	auto/cpi_trace/autosplit.ix
	perl cpi_lock.pm
	[ -d auto/cpi_lock ] || mkdir -p auto/cpi_lock
	mv cpi_lock.pm cpi_lock.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_lock.compiling > cpi_lock.pm
	perl -MAutoSplit -e 'autosplit(cpi_lock,auto,0,1,1)' || excode=0
	mv cpi_lock.compiling cpi_lock.pm
auto/cpi_log/autosplit.ix:\
	auto/cpi_vars/autosplit.ix
	perl cpi_log.pm
	[ -d auto/cpi_log ] || mkdir -p auto/cpi_log
	mv cpi_log.pm cpi_log.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_log.compiling > cpi_log.pm
	perl -MAutoSplit -e 'autosplit(cpi_log,auto,0,1,1)' || excode=0
	mv cpi_log.compiling cpi_log.pm
auto/cpi_magic_http/autosplit.ix:\
	auto/cpi_cgi/autosplit.ix\
	auto/cpi_file/autosplit.ix
	perl cpi_magic_http.pm
	[ -d auto/cpi_magic_http ] || mkdir -p auto/cpi_magic_http
	mv cpi_magic_http.pm cpi_magic_http.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_magic_http.compiling > cpi_magic_http.pm
	perl -MAutoSplit -e 'autosplit(cpi_magic_http,auto,0,1,1)' || excode=0
	mv cpi_magic_http.compiling cpi_magic_http.pm
auto/cpi_make_from/autosplit.ix:\
	auto/cpi_db/autosplit.ix\
	auto/cpi_file/autosplit.ix\
	auto/cpi_vars/autosplit.ix
	perl cpi_make_from.pm
	[ -d auto/cpi_make_from ] || mkdir -p auto/cpi_make_from
	mv cpi_make_from.pm cpi_make_from.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_make_from.compiling > cpi_make_from.pm
	perl -MAutoSplit -e 'autosplit(cpi_make_from,auto,0,1,1)' || excode=0
	mv cpi_make_from.compiling cpi_make_from.pm
auto/cpi_mime/autosplit.ix:\
	auto/cpi_vars/autosplit.ix
	perl cpi_mime.pm
	[ -d auto/cpi_mime ] || mkdir -p auto/cpi_mime
	mv cpi_mime.pm cpi_mime.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_mime.compiling > cpi_mime.pm
	perl -MAutoSplit -e 'autosplit(cpi_mime,auto,0,1,1)' || excode=0
	mv cpi_mime.compiling cpi_mime.pm
auto/cpi_qrcode_of/autosplit.ix:\
	auto/cpi_file/autosplit.ix
	perl cpi_qrcode_of.pm
	[ -d auto/cpi_qrcode_of ] || mkdir -p auto/cpi_qrcode_of
	mv cpi_qrcode_of.pm cpi_qrcode_of.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_qrcode_of.compiling > cpi_qrcode_of.pm
	perl -MAutoSplit -e 'autosplit(cpi_qrcode_of,auto,0,1,1)' || excode=0
	mv cpi_qrcode_of.compiling cpi_qrcode_of.pm
auto/cpi_reorder/autosplit.ix:\
	auto/cpi_sortable/autosplit.ix
	perl cpi_reorder.pm
	[ -d auto/cpi_reorder ] || mkdir -p auto/cpi_reorder
	mv cpi_reorder.pm cpi_reorder.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_reorder.compiling > cpi_reorder.pm
	perl -MAutoSplit -e 'autosplit(cpi_reorder,auto,0,1,1)' || excode=0
	mv cpi_reorder.compiling cpi_reorder.pm
auto/cpi_send_file/autosplit.ix:\
	auto/cpi_file/autosplit.ix\
	auto/cpi_mime/autosplit.ix\
	auto/cpi_vars/autosplit.ix
	perl cpi_send_file.pm
	[ -d auto/cpi_send_file ] || mkdir -p auto/cpi_send_file
	mv cpi_send_file.pm cpi_send_file.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_send_file.compiling > cpi_send_file.pm
	perl -MAutoSplit -e 'autosplit(cpi_send_file,auto,0,1,1)' || excode=0
	mv cpi_send_file.compiling cpi_send_file.pm
auto/cpi_setup/autosplit.ix:\
	auto/cpi_cgi/autosplit.ix\
	auto/cpi_copy_db/autosplit.ix\
	auto/cpi_db/autosplit.ix\
	auto/cpi_time/autosplit.ix\
	auto/cpi_translate/autosplit.ix\
	auto/cpi_user/autosplit.ix\
	auto/cpi_vars/autosplit.ix
	perl cpi_setup.pm
	[ -d auto/cpi_setup ] || mkdir -p auto/cpi_setup
	mv cpi_setup.pm cpi_setup.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_setup.compiling > cpi_setup.pm
	perl -MAutoSplit -e 'autosplit(cpi_setup,auto,0,1,1)' || excode=0
	mv cpi_setup.compiling cpi_setup.pm
auto/cpi_sortable/autosplit.ix:
	perl cpi_sortable.pm
	[ -d auto/cpi_sortable ] || mkdir -p auto/cpi_sortable
	mv cpi_sortable.pm cpi_sortable.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_sortable.compiling > cpi_sortable.pm
	perl -MAutoSplit -e 'autosplit(cpi_sortable,auto,0,1,1)' || excode=0
	mv cpi_sortable.compiling cpi_sortable.pm
auto/cpi_template/autosplit.ix:\
	auto/cpi_file/autosplit.ix\
	auto/cpi_vars/autosplit.ix
	perl cpi_template.pm
	[ -d auto/cpi_template ] || mkdir -p auto/cpi_template
	mv cpi_template.pm cpi_template.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_template.compiling > cpi_template.pm
	perl -MAutoSplit -e 'autosplit(cpi_template,auto,0,1,1)' || excode=0
	mv cpi_template.compiling cpi_template.pm
auto/cpi_time/autosplit.ix:
	perl cpi_time.pm
	[ -d auto/cpi_time ] || mkdir -p auto/cpi_time
	mv cpi_time.pm cpi_time.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_time.compiling > cpi_time.pm
	perl -MAutoSplit -e 'autosplit(cpi_time,auto,0,1,1)' || excode=0
	mv cpi_time.compiling cpi_time.pm
auto/cpi_trace/autosplit.ix:
	perl cpi_trace.pm
	[ -d auto/cpi_trace ] || mkdir -p auto/cpi_trace
	mv cpi_trace.pm cpi_trace.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_trace.compiling > cpi_trace.pm
	perl -MAutoSplit -e 'autosplit(cpi_trace,auto,0,1,1)' || excode=0
	mv cpi_trace.compiling cpi_trace.pm
auto/cpi_trans_none/autosplit.ix:
	perl cpi_trans_none.pm
	[ -d auto/cpi_trans_none ] || mkdir -p auto/cpi_trans_none
	mv cpi_trans_none.pm cpi_trans_none.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_trans_none.compiling > cpi_trans_none.pm
	perl -MAutoSplit -e 'autosplit(cpi_trans_none,auto,0,1,1)' || excode=0
	mv cpi_trans_none.compiling cpi_trans_none.pm
auto/cpi_translate/autosplit.ix:\
	auto/cpi_db/autosplit.ix\
	auto/cpi_file/autosplit.ix\
	auto/cpi_help/autosplit.ix\
	auto/cpi_trans_none/autosplit.ix\
	auto/cpi_vars/autosplit.ix
	perl cpi_translate.pm
	[ -d auto/cpi_translate ] || mkdir -p auto/cpi_translate
	mv cpi_translate.pm cpi_translate.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_translate.compiling > cpi_translate.pm
	perl -MAutoSplit -e 'autosplit(cpi_translate,auto,0,1,1)' || excode=0
	mv cpi_translate.compiling cpi_translate.pm
auto/cpi_user/autosplit.ix:\
	auto/cpi_cgi/autosplit.ix\
	auto/cpi_compress_integer/autosplit.ix\
	auto/cpi_db/autosplit.ix\
	auto/cpi_file/autosplit.ix\
	auto/cpi_log/autosplit.ix\
	auto/cpi_send_file/autosplit.ix\
	auto/cpi_translate/autosplit.ix\
	auto/cpi_vars/autosplit.ix
	perl cpi_user.pm
	[ -d auto/cpi_user ] || mkdir -p auto/cpi_user
	mv cpi_user.pm cpi_user.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_user.compiling > cpi_user.pm
	perl -MAutoSplit -e 'autosplit(cpi_user,auto,0,1,1)' || excode=0
	mv cpi_user.compiling cpi_user.pm
auto/cpi_vars/autosplit.ix:
	perl cpi_vars.pm
	[ -d auto/cpi_vars ] || mkdir -p auto/cpi_vars
	mv cpi_vars.pm cpi_vars.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_vars.compiling > cpi_vars.pm
	perl -MAutoSplit -e 'autosplit(cpi_vars,auto,0,1,1)' || excode=0
	mv cpi_vars.compiling cpi_vars.pm
auto/cpi_inlist/autosplit.ix:
	perl cpi_inlist.pm
	[ -d auto/cpi_inlist ] || mkdir -p auto/cpi_inlist
	mv cpi_inlist.pm cpi_inlist.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_inlist.compiling > cpi_inlist.pm
	perl -MAutoSplit -e 'autosplit(cpi_inlist,auto,0,1,1)' || excode=0
	mv cpi_inlist.compiling cpi_inlist.pm
auto/cpi_arguments/autosplit.ix:\
	auto/cpi_english/autosplit.ix\
	auto/cpi_file/autosplit.ix\
	auto/cpi_inlist/autosplit.ix
	perl cpi_arguments.pm
	[ -d auto/cpi_arguments ] || mkdir -p auto/cpi_arguments
	mv cpi_arguments.pm cpi_arguments.compiling
	sed -e 's/^#*__END__/__END__/' < cpi_arguments.compiling > cpi_arguments.pm
	perl -MAutoSplit -e 'autosplit(cpi_arguments,auto,0,1,1)' || excode=0
	mv cpi_arguments.compiling cpi_arguments.pm
