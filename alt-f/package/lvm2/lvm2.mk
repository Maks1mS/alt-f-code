#############################################################
#
# lvm2
#
#############################################################
# Copyright (C) 2005 by Richard Downer <rdowner@gmail.com>
# Derived from work
# Copyright (C) 2001-2005 by Erik Andersen <andersen@codepoet.org>
# Copyright (C) 2002 by Tim Riker <Tim@Rikers.org>
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

#https://gitlab.com/lvmteam/lvm2/-/archive/v2_02_88/lvm2-v2_02_88.tar.bz2

#LVM2_BASEVER=2.02
LVM2_DMVER=1.02
#LVM2_PATCH=50
#LVM2_PATCH=67
#LVM2_VERSION=$(LVM2_BASEVER).$(LVM2_PATCH)
#LVM2_VERSION=2.02.67
# next try 2.02.177 Dec-2017; after that libaio is a dependency?
LVM2_VERSION=2.02.88
LVM2_VERSION2=v2_02_88

LVM2_SITE:=https://gitlab.com/lvmteam/lvm2/-/archive/$(LVM2_VERSION2)
LVM2_SOURCE:=lvm2-$(LVM2_VERSION2).tar.bz2

LVM2_CAT:=$(BZCAT)
LVM2_DIR:=$(BUILD_DIR)/lvm2-$(LVM2_VERSION)

LVM2_SBIN:=lvchange lvcreate lvdisplay lvextend lvm lvmchange lvmdiskscan lvmsadc lvmsar lvreduce lvremove lvrename lvresize lvs lvscan pvchange pvcreate pvdisplay pvmove pvremove pvresize pvs pvscan vgcfgbackup vgcfgrestore vgchange vgck vgconvert vgcreate vgdisplay vgexport vgextend vgimport vgmerge vgmknodes vgreduce vgremove vgrename vgs vgscan vgsplit
LVM2_DMSETUP_SBIN:=dmsetup
LVM2_LIB:=libdevmapper.so.$(LVM2_DMVER)
LVM2_TARGET_SBINS=$(foreach lvm2sbin, $(LVM2_SBIN), $(TARGET_DIR)/usr/sbin/$(lvm2sbin))
LVM2_TARGET_DMSETUP_SBINS=$(foreach lvm2sbin, $(LVM2_DMSETUP_SBIN), $(TARGET_DIR)/sbin/$(lvm2sbin))
LVM2_TARGET_LIBS=$(foreach lvm2lib, $(LVM2_LIB), $(TARGET_DIR)/lib/$(lvm2lib))
LVM2_CONF_OPT:=--disable-dmeventd --disable-selinux --disable-udev_sync --disable-udev_rules

# device-mapper: the kernel event handling can *probably* only be solved with udev sync,
# which has some other dependencies
#LVM2_CONF_OPT:=--disable-dmeventd --disable-selinux --enable-udev_sync --disable-udev_rules
#LVM2_CONF_ENV:=UDEV_CFLAGS=-I$(STAGING_DIR)/usr/include/udev UDEV_LIBS=-L$(STAGING_DIR)/usr/lib

$(DL_DIR)/$(LVM2_SOURCE):
	 $(call DOWNLOAD,$(LVM2_SITE),$(LVM2_SOURCE))

lvm2-source: $(DL_DIR)/$(LVM2_SOURCE)

ifeq ($(BR2_PACKAGE_READLINE),y)
LVM2_DEPENDENCIES+=readline
else
# v2.02.44: disable readline usage, or binaries are linked against provider
# of "tgetent" (=> ncurses) even if it's not used..
LVM2_CONF_OPT+=--disable-readline
endif

$(LVM2_DIR)/.unpacked: $(DL_DIR)/$(LVM2_SOURCE)
	mkdir -p $(LVM2_DIR)
	$(LVM2_CAT) $(DL_DIR)/$(LVM2_SOURCE) | tar $(TAR_STRIP_COMPONENTS)=1 -C $(LVM2_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(LVM2_DIR) package/lvm2 lvm2-$(LVM2_VERSION)-\*.patch\*
	touch $(LVM2_DIR)/.unpacked

$(LVM2_DIR)/.configured: $(LVM2_DIR)/.unpacked
	(cd $(LVM2_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		$(TARGET_CONFIGURE_ENV) \
		$(LVM2_CONF_ENV) \
		ac_cv_have_decl_malloc=yes \
		gl_cv_func_malloc_0_nonnull=yes \
		ac_cv_func_malloc_0_nonnull=yes \
		ac_cv_func_calloc_0_nonnull=yes \
		ac_cv_func_realloc_0_nonnull=yes \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--libdir=/usr/lib \
		$(DISABLE_NLS) \
		$(DISABLE_LARGEFILE) \
		$(LVM2_CONF_OPT) \
	)
	touch $(LVM2_DIR)/.configured

#--with-usrlibdir=/usr/lib \
# --with-user=$(shell id -un) --with-group=$(shell id -gn) \

$(LVM2_DIR)/.built: $(LVM2_DIR)/.configured
	$(MAKE1) CC=$(TARGET_CC) RANLIB=$(TARGET_RANLIB) AR=$(TARGET_AR) -C $(LVM2_DIR)
	$(MAKE1) -C $(LVM2_DIR) DESTDIR=$(STAGING_DIR) install
	# Fixup write permissions so that the files can be overwritten
	# several times in the $(TARGET_DIR)
	chmod 755 $(STAGING_DIR)/sbin/lvm
	chmod 755 $(STAGING_DIR)/sbin/dmsetup
	chmod 644 $(STAGING_DIR)/usr/lib/$(LVM2_LIB)
	touch $(LVM2_DIR)/.built

$(LVM2_TARGET_SBINS) $(LVM2_TARGET_DMSETUP_SBINS): $(LVM2_DIR)/.built
	cp -a $(STAGING_DIR)/sbin/$(notdir $@) $@
	cp -a $(STAGING_DIR)/etc/lvm $(TARGET_DIR)/etc

$(LVM2_TARGET_LIBS): $(LVM2_DIR)/.built
	cp -a $(STAGING_DIR)/usr/lib/$(notdir $@) $@

lvm2-source:	$(DL_DIR)/$(LVM2_SOURCE)
	
lvm2-extract:	$(LVM2_DIR)/.unpacked
	
lvm2-configure: $(LVM2_DIR)/.configured

lvm2-build: $(LVM2_DIR)/.built

ifeq ($(BR2_PACKAGE_LVM2_DMSETUP_ONLY),y)
lvm2: uclibc $(LVM2_TARGET_DMSETUP_SBINS) $(LVM2_TARGET_LIBS)
else
lvm2: uclibc $(LVM2_TARGET_SBINS) $(LVM2_TARGET_DMSETUP_SBINS) $(LVM2_TARGET_LIBS)
endif

lvm2-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) -C $(LVM2_DIR) uninstall
	-$(MAKE) -C $(LVM2_DIR) clean

lvm2-dirclean:
	rm -rf $(LVM2_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_LVM2),y)
TARGETS+=lvm2
endif
