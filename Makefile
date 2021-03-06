FILES=data lib package.json README.md bootstrap.js
ADDON_NAME=valence
ADDON_VERSION=0.3.1pre
XPI_NAME=$(ADDON_NAME)-$(ADDON_VERSION)
SOURCE_ZIPFILE=$(XPI_NAME)-sources.zip

FTP_ROOT_PATH=/pub/mozilla.org/labs/valence

UPDATE_LINK=https://ftp.mozilla.org$(FTP_ROOT_PATH)/
UPDATE_URL=$(UPDATE_LINK)

XPIS = $(XPI_NAME)-win32.xpi $(XPI_NAME)-linux32.xpi $(XPI_NAME)-linux64.xpi $(XPI_NAME)-mac64.xpi

all: $(XPIS)

define build-xpi
	echo "build xpi for $1";
	mv install.rdf jpm_install.rdf
	sed -e 's#@@UPDATE_URL@@#$(UPDATE_URL)$1/update.rdf#;s#@@ADDON_VERSION@@#$(ADDON_VERSION)#' template/install.rdf > install.rdf
	zip $(XPI_NAME)-$1.xpi -r $2 install.rdf
	mv jpm_install.rdf install.rdf
endef

bootstrap.js: template
	cp template/bootstrap.js bootstrap.js

$(XPI_NAME)-win32.xpi: $(FILES) tools/win32
	@$(call build-xpi,win32, $^)

$(XPI_NAME)-linux32.xpi: $(FILES) tools/linux32
	@$(call build-xpi,linux32, $^)

$(XPI_NAME)-linux64.xpi: $(FILES) tools/linux64
	@$(call build-xpi,linux64, $^)

$(XPI_NAME)-mac64.xpi: $(FILES) tools/mac64
	@$(call build-xpi,mac64, $^)

clean:
	rm -f *.xpi
	rm -f update.rdf bootstrap.js

define release
  echo "releasing $1"
  # Copy the xpi
  chmod 766 $(XPI_NAME)-$1.xpi
	scp -p $(XPI_NAME)-$1.xpi $(SSH_USER)@stage.mozilla.org:$(FTP_ROOT_PATH)/$1/$(XPI_NAME)-$1.xpi
  # Update the "latest" symbolic link
	ssh $(SSH_USER)@stage.mozilla.org 'cd $(FTP_ROOT_PATH)/$1/ && ln -fs $(XPI_NAME)-$1.xpi $(ADDON_NAME)-$1-latest.xpi'
  # Update a "latest" symbolic link for compat with Fx 39 and earlier
	ssh $(SSH_USER)@stage.mozilla.org 'cd $(FTP_ROOT_PATH)/$1/ && ln -fs $(XPI_NAME)-$1.xpi fxdt-adapters-$1-latest.xpi'
  # Update the update manifest
	sed -e 's#@@UPDATE_LINK@@#$(UPDATE_LINK)$1/$(XPI_NAME)-$1.xpi#;s#@@ADDON_VERSION@@#$(ADDON_VERSION)#' template/update.rdf > update.rdf
  chmod 766 update.rdf
	scp -p update.rdf $(SSH_USER)@stage.mozilla.org:$(FTP_ROOT_PATH)/$1/update.rdf
endef

release: $(XPIS) archive-sources
	@if [ -z $(SSH_USER) ]; then \
	  echo "release target requires SSH_USER env variable to be defined."; \
	  exit 1; \
	fi
	ssh $(SSH_USER)@stage.mozilla.org 'mkdir -m 755 -p $(FTP_ROOT_PATH)/{win32,linux32,linux64,mac64,sources}'
	@$(call release,win32)
	@$(call release,linux32)
	@$(call release,linux64)
	@$(call release,mac64)
	scp -p ../$(SOURCE_ZIPFILE) $(SSH_USER)@stage.mozilla.org:$(FTP_ROOT_PATH)/sources/$(SOURCE_ZIPFILE)
  # Update the "latest sources" symbolic link
	ssh $(SSH_USER)@stage.mozilla.org 'cd $(FTP_ROOT_PATH)/sources/ && ln -fs $(SOURCE_ZIPFILE) $(ADDON_NAME)-latest-sources.zip'

# Expects to find the following directories in the same level as this one:
#
# ios-webkit-debug-proxy (https://github.com/google/ios-webkit-debug-proxy)
# ios-webkit-debug-proxy-win32 (https://github.com/artygus/ios-webkit-debug-proxy-win32)
# libimobiledevice (https://github.com/libimobiledevice/libimobiledevice)
# libplist (https://github.com/libimobiledevice/libplist)
# libusbmuxd (https://github.com/libimobiledevice/libusbmuxd)
# openssl (https://github.com/openssl/openssl)
# libxml2 (git://git.gnome.org/libxml2.git)
# libiconv (git://git.savannah.gnu.org/libiconv.git)
# pcre (svn://vcs.exim.org/pcre2/code/trunk)
# zlib (http://zlib.net/)
archive-sources:
	@echo "archiving $1 sources"
	@echo "(make sure you have run 'make distclean' in all dependencies!)"
	rm -f ../$(SOURCE_ZIPFILE)
	cd .. && zip -qx \*.git\* -r $(SOURCE_ZIPFILE) $(ADDON_NAME)
	cd .. && zip -qx \*.git\* -r $(SOURCE_ZIPFILE) ios-webkit-debug-proxy
	cd .. && zip -qx \*.git\* -r $(SOURCE_ZIPFILE) ios-webkit-debug-proxy-win32
	cd .. && zip -qx \*.git\* -r $(SOURCE_ZIPFILE) libimobiledevice
	cd .. && zip -qx \*.git\* -r $(SOURCE_ZIPFILE) libplist
	cd .. && zip -qx \*.git\* -r $(SOURCE_ZIPFILE) libusbmuxd
	cd .. && zip -qx \*.git\* -r $(SOURCE_ZIPFILE) openssl
	cd .. && zip -qx \*.git\* -r $(SOURCE_ZIPFILE) libxml2
	cd .. && zip -qx \*.git\* -r $(SOURCE_ZIPFILE) libiconv
	cd .. && zip -qx \*.git\* -r $(SOURCE_ZIPFILE) pcre
	cd .. && zip -qx \*.git\* -r $(SOURCE_ZIPFILE) zlib
