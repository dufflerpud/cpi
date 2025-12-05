install:
	cd src; sudo make install_required_modules install
	install -d /usr/local/bin
	install -m 0755 tests/cpi_user.pl /usr/local/bin/cpi_user
	install -m 0755 tests/cpi_db.pl /usr/local/bin/cpi_db

fresh:
	git pull
	@make install
