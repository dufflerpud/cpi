install:
	cd src; sudo make install_required_modules install

fresh:
	git pull
	@make install
