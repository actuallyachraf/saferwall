COMODO_URL = http://download.comodo.com/cis/download/installs/linux/cav-linux_x64.deb
COMODO_UPDATE = http://download.comodo.com/av/updates58/sigs/bases/bases.cav
COMODO_INSTALL_DIR = /etc/COMODO
COMODO_LIB_SSL = http://security.ubuntu.com/ubuntu/pool/universe/o/openssl098/libssl0.9.8_0.9.8o-7ubuntu3.2.14.04.1_amd64.deb

install-comodo:			## install Comodo Antivirus for Linux
	wget $(COMODO_LIB_SSL) -P /tmp/			# Download and install the trusty package manually
	wget  $(COMODO_URL) -P /tmp
	sudo dpkg -i /tmp/libssl0.9.8_0.9.8o-7ubuntu3.2.14.04.1_amd64.deb
	ar x /tmp/cav-linux_x64.deb
	sudo tar zxvf data.tar.gz -C /
	make update-comodo

update-comodo:			## update Comodo Antivirus for Linux
	sudo wget  $(COMODO_UPDATE) -P $(COMODO_INSTALL_DIR)/scanners

uninstall-comodo:		## uninstall Comodo Antivirus for Linux
	sudo rm -rf $(COMODO_INSTALL_DIR)