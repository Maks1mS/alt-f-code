#############################################################
#
# ncurses
# this installs only a few vital termcap entries
#
#############################################################
# Copyright (C) 2002 by Ken Restivo <ken@246gt.com>
# $Id: ncurses.mk,v 1.7 2005/01/03 04:38:13 andersen Exp $
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Library General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
# USA

NCURSES_VERSION:=5.9

NCURSES_SITE:=$(BR2_GNU_MIRROR)/ncurses
NCURSES_DIR:=$(BUILD_DIR)/ncurses-$(NCURSES_VERSION)
NCURSES_SOURCE:=ncurses-$(NCURSES_VERSION).tar.gz
NCURSES_CAT:=$(ZCAT)

ifneq ($(BR2_PACKAGE_NCURSES_TARGET_HEADERS),y)
NCURSES_WANT_STATIC=--disable-static
endif

$(DL_DIR)/$(NCURSES_SOURCE):
	$(call DOWNLOAD,$(NCURSES_SITE),$(NCURSES_SOURCE))

$(NCURSES_DIR)/.patched: $(DL_DIR)/$(NCURSES_SOURCE)
	$(NCURSES_CAT) $(DL_DIR)/$(NCURSES_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(NCURSES_DIR) package/ncurses/ ncurses\*.patch
	$(CONFIG_UPDATE) $(NCURSES_DIR)
	touch $@

#$(NCURSES_HOST_DIR)/.stamp_host_configured: $(NCURSES_HOST_DIR)/.stamp_host_extracted:
#	$(NCURSES_CAT) $(DL_DIR)/$(NCURSES_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
#	toolchain/patch-kernel.sh $(NCURSES_HOST_DIR) package/ncurses/ ncurses\*.patch
#	$(CONFIG_UPDATE) $(NCURSES_HOST_DIR)
#	touch $@

$(NCURSES_DIR)/.configured: $(NCURSES_DIR)/.patched
	(cd $(NCURSES_DIR); rm -rf config.cache; \
		BUILD_CC="$(HOSTCC)" \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(REAL_GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--exec-prefix=/usr \
		--bindir=/usr/bin \
		--sbindir=/usr/sbin \
		--libdir=/usr/lib \
		--libexecdir=/usr/lib \
		--sysconfdir=/etc \
		--datadir=/usr/share \
		--localstatedir=/var \
		--includedir=/usr/include \
		--mandir=/usr/man \
		--infodir=/usr/info \
		--with-terminfo-dirs=/usr/share/terminfo \
		--with-default-terminfo-dir=/usr/share/terminfo \
		--with-shared --without-cxx --without-cxx-binding \
		--without-ada --without-progs --disable-big-core \
		$(DISABLE_NLS) $(DISABLE_LARGEFILE) \
		--without-profile --without-debug --disable-rpath \
		--enable-echo --enable-const --enable-overwrite \
		$(NCURSES_WANT_STATIC) \
	)
	touch $@

#		--enable-broken_linker \

$(NCURSES_DIR)/lib/libncurses.so.$(NCURSES_VERSION): $(NCURSES_DIR)/.configured
	$(MAKE1) DESTDIR=$(STAGING_DIR) -C $(NCURSES_DIR) \
		libs panel menu form headers

$(STAGING_DIR)/usr/lib/libncurses.so.$(NCURSES_VERSION): $(NCURSES_DIR)/lib/libncurses.so.$(NCURSES_VERSION)
	$(MAKE1) \
	    prefix=$(STAGING_DIR)/usr/ \
	    exec_prefix=$(STAGING_DIR) \
	    bindir=$(STAGING_DIR)/bin \
	    sbindir=$(STAGING_DIR)/sbin \
	    libexecdir=$(STAGING_DIR)/usr/lib \
	    datadir=$(STAGING_DIR)/usr/share \
	    sysconfdir=$(STAGING_DIR)/etc \
	    localstatedir=$(STAGING_DIR)/var \
	    libdir=$(STAGING_DIR)/usr/lib \
	    infodir=$(STAGING_DIR)/usr/info \
	    mandir=$(STAGING_DIR)/usr/man \
	    includedir=$(STAGING_DIR)/usr/include \
	    gxx_include_dir=$(STAGING_DIR)/usr/include/c++ \
	    ticdir=$(STAGING_DIR)/usr/share/terminfo \
	    -C $(NCURSES_DIR) install
	chmod a-x $(NCURSES_DIR)/lib/libncurses.so*
	#$(SED) -e 's^prefix="^prefix="$(STAGING_DIR)^' \
	#	-e 's|^includedir="|includedir="'$(STAGING_DIR)'|' \
	#	-e 's|libdir="|libdir="'$(STAGING_DIR)'|' \
	#	$(STAGING_DIR)/bin/ncurses5-config
	touch -c $@

$(TARGET_DIR)/usr/lib/libncurses.so.$(NCURSES_VERSION): $(STAGING_DIR)/usr/lib/libncurses.so.$(NCURSES_VERSION)
	mkdir -p $(TARGET_DIR)/usr/lib
ifeq ($(BR2_PACKAGE_NCURSES),y)
	cp -dpf $(NCURSES_DIR)/lib/libncurses.so* $(TARGET_DIR)/usr/lib/
ifeq ($(BR2_PACKAGE_NCURSES_PANEL),y)
	cp -dpf $(NCURSES_DIR)/lib/libpanel.so* $(TARGET_DIR)/usr/lib/
endif
ifeq ($(BR2_PACKAGE_NCURSES_FORM),y)
	cp -dpf $(NCURSES_DIR)/lib/libform.so* $(TARGET_DIR)/usr/lib/
endif
ifeq ($(BR2_PACKAGE_NCURSES_MENU),y)
	cp -dpf $(NCURSES_DIR)/lib/libmenu.so* $(TARGET_DIR)/usr/lib/
endif
	ln -snf /usr/share/terminfo $(TARGET_DIR)/usr/lib/terminfo
	mkdir -p $(TARGET_DIR)/usr/share/terminfo/x
	cp -dpf $(STAGING_DIR)/usr/share/terminfo/x/xterm $(TARGET_DIR)/usr/share/terminfo/x
	cp -dpf $(STAGING_DIR)/usr/share/terminfo/x/xterm-color $(TARGET_DIR)/usr/share/terminfo/x
	cp -dpf $(STAGING_DIR)/usr/share/terminfo/x/xterm-xfree86 $(TARGET_DIR)/usr/share/terminfo/x
	mkdir -p $(TARGET_DIR)/usr/share/terminfo/v
	cp -dpf $(STAGING_DIR)/usr/share/terminfo/v/vt100 $(TARGET_DIR)/usr/share/terminfo/v
	cp -dpf $(STAGING_DIR)/usr/share/terminfo/v/vt102 $(TARGET_DIR)/usr/share/terminfo/v
	cp -dpf $(STAGING_DIR)/usr/share/terminfo/v/vt200 $(TARGET_DIR)/usr/share/terminfo/v
	cp -dpf $(STAGING_DIR)/usr/share/terminfo/v/vt220 $(TARGET_DIR)/usr/share/terminfo/v
	mkdir -p $(TARGET_DIR)/usr/share/terminfo/a
	cp -dpf $(STAGING_DIR)/usr/share/terminfo/a/ansi $(TARGET_DIR)/usr/share/terminfo/a
	mkdir -p $(TARGET_DIR)/usr/share/terminfo/l
	cp -dpf $(STAGING_DIR)/usr/share/terminfo/l/linux $(TARGET_DIR)/usr/share/terminfo/l
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $@
endif
	touch -c $@

$(NCURSES_DIR)/lib/libncurses.a: $(NCURSES_DIR)/lib/libncurses.so.$(NCURSES_VERSION)

$(TARGET_DIR)/usr/lib/libncurses.a: $(NCURSES_DIR)/lib/libncurses.a
	mkdir -p $(TARGET_DIR)/usr/include
	cp -dpf $(NCURSES_DIR)/include/curses.h $(TARGET_DIR)/usr/include/curses.h
	cp -dpf $(NCURSES_DIR)/include/ncurses_dll.h $(TARGET_DIR)/usr/include/ncurses_dll.h
	cp -dpf $(NCURSES_DIR)/include/term.h $(TARGET_DIR)/usr/include/
	cp -dpf $(NCURSES_DIR)/include/unctrl.h $(TARGET_DIR)/usr/include/
	cp -dpf $(NCURSES_DIR)/include/termcap.h $(TARGET_DIR)/usr/include/
	cp -dpf $(NCURSES_DIR)/lib/libncurses.a $(TARGET_DIR)/usr/lib/
	(cd $(TARGET_DIR)/usr/lib; \
	 ln -fs libncurses.a libcurses.a; \
	 ln -fs libncurses.a libtermcap.a; \
	)
	(cd $(TARGET_DIR)/usr/include; ln -fs curses.h ncurses.h)
	rm -f $(TARGET_DIR)/usr/lib/libncurses.so
	(cd $(TARGET_DIR)/usr/lib; ln -fs libncurses.so.$(NCURSES_VERSION) libncurses.so)
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/usr/lib/libncurses.so.$(NCURSES_VERSION)
	touch -c $@

NCURSES_HOST_CONF_OPT = --with-shared --without-cxx-binding

$(eval $(call AUTOTARGETS_HOST,package,ncurses))

$(NCURSES_HOST_HOOK_POST_EXTRACT):
	toolchain/patch-kernel.sh $(NCURSES_HOST_DIR) package/ncurses ncurses\*.patch
	touch $@

$(NCURSES_HOST_HOOK_POST_INSTALL):
	$(SED) 's|prefix="|prefix="$(HOST_DIR)|' \
	       -e 's|libdir="|libdir="$(HOST_DIR)|' \
		$(HOST_DIR)/usr/bin/ncurses5-config
	touch $@
		
ncurses: ncurses-host $(TARGET_DIR)/usr/lib/libncurses.so.$(NCURSES_VERSION)

ncurses-unpacked: $(NCURSES_DIR)/.patched

ncurses-headers: $(TARGET_DIR)/usr/lib/libncurses.a

ncurses-source: $(DL_DIR)/$(NCURSES_SOURCE)

ncurses-clean:
	rm -f $(STAGING_DIR)/usr/lib/libncurses.so* $(TARGET_DIR)/usr/lib/libncurses.so*
	rm -rf $(STAGING_DIR)/usr/share/tabset $(TARGET_DIR)/usr/share/tabset
	rm -rf $(STAGING_DIR)/usr/share/terminfo $(TARGET_DIR)/usr/share/terminfo
	rm -rf $(TARGET_DIR)/usr/lib/terminfo
	-$(MAKE) -C $(NCURSES_DIR) clean

ncurses-dirclean:
	rm -rf $(NCURSES_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_NCURSES),y)
TARGETS+=ncurses
endif
ifeq ($(BR2_PACKAGE_NCURSES_TARGET_HEADERS),y)
TARGETS+=ncurses-headers
endif
