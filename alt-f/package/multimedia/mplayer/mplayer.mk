#############################################################
#
# mplayer
#
#############################################################
#MPLAYER_VERSION:=1.0rc2
MPLAYER_VERSION:=1.2.1
MPLAYER_SOURCE:=MPlayer-$(MPLAYER_VERSION).tar.xz
MPLAYER_SITE:=http://www7.mplayerhq.hu/MPlayer/releases

MPLAYER_DIR:=$(BUILD_DIR)/MPlayer-$(MPLAYER_VERSION)
#MPLAYER_CAT:=$(BZCAT)
MPLAYER_CAT:=$(XZCAT)
MPLAYER_BINARY:=mplayer
MPLAYER_BINARY2:=mencoder
MPLAYER_TARGET_BINARY:=usr/bin/$(MPLAYER_BINARY)
MPLAYER_TARGET_BINARY2:=usr/bin/$(MPLAYER_BINARY2)

ifeq ($(BR2_ENDIAN),"BIG")
MPLAYER_ENDIAN:=--enable-big-endian
else
MPLAYER_ENDIAN:=--disable-big-endian
endif

# mplayer unfortunately uses --disable-largefileS, so we cannot use
# DISABLE_LARGEFILE
# ifeq ($(BR2_LARGEFILE),y)
# MPLAYER_LARGEFILE:=--enable-largefiles
# else
# MPLAYER_LARGEFILE:=--disable-largefiles
# endif
# 
# MPLAYER_CFLAGS := -fgnu89-inline -DHAVE_BYTESWAP_H
# ifeq ($(BR2_i386),y)
# # This seems to be required to compile some of the inline asm
# MPLAYER_CFLAGS+=-fomit-frame-pointer
# endif

$(DL_DIR)/$(MPLAYER_SOURCE):
	$(call DOWNLOAD,$(MPLAYER_SITE),$(MPLAYER_SOURCE))

$(MPLAYER_DIR)/.unpacked: $(DL_DIR)/$(MPLAYER_SOURCE)
	$(MPLAYER_CAT) $(DL_DIR)/$(MPLAYER_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(MPLAYER_DIR) package/multimedia/mplayer/ mplayer-$(MPLAYER_VERSION)\*.patch\*
	$(CONFIG_UPDATE) $(MPLAYER_DIR)
	$(SED) 's/^read _answer//' $(MPLAYER_DIR)/configure
	touch $@

#		--with-extraincdir=$(STAGING_DIR)/usr/include \
		--with-extralibdir=$(STAGING_DIR)/lib \
		--disable-gcc-check \
		--disable-dvdread-internal \
		--disable-libdvdcss-internal \
		--disable-ivtv \
		--disable-tv \
		--disable-live \

$(MPLAYER_DIR)/.configured: $(MPLAYER_DIR)/.unpacked
	(cd $(MPLAYER_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		CFLAGS="$(TARGET_CFLAGS) $(MPLAYER_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" \
		./configure \
		--prefix=/usr \
		--confdir=/etc \
		--target=$(GNU_TARGET_NAME) \
		--host-cc=$(HOSTCC) \
		--cc=$(TARGET_CC) \
		--as=$(TARGET_CROSS)as \
		--extra-cflags=-I$(STAGING_DIR)/usr/include \
		--extra-ldflags=-L$(STAGING_DIR)/usr/lib \
		--charset=UTF-8 \
		--enable-mad \
		--enable-fbdev \
		$(MPLAYER_ENDIAN) \
		$(MPLAYER_LARGEFILE) \
		--enable-cross-compile \
		--enable-dynamic-plugins \
	)
	touch $@

$(MPLAYER_DIR)/$(MPLAYER_BINARY): $(MPLAYER_DIR)/.configured
	$(MAKE) -C $(MPLAYER_DIR)
	touch -c $@

$(TARGET_DIR)/$(MPLAYER_TARGET_BINARY): $(MPLAYER_DIR)/$(MPLAYER_BINARY)
	$(INSTALL) -m 0755 -D $(MPLAYER_DIR)/$(MPLAYER_BINARY) $(TARGET_DIR)/$(MPLAYER_TARGET_BINARY)
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/$(MPLAYER_TARGET_BINARY)
	$(INSTALL) -m 0755 -D $(MPLAYER_DIR)/$(MPLAYER_BINARY2) $(TARGET_DIR)/$(MPLAYER_TARGET_BINARY2)
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/$(MPLAYER_TARGET_BINARY2)
	touch -c $@

mplayer: uclibc $(if $(BR2_PACKAGE_LIBMAD),libmad) $(if $(BR2_PACKAGE_ALSA_LIB),alsa-lib) $(TARGET_DIR)/$(MPLAYER_TARGET_BINARY)

mplayer-build: $(TARGET_DIR)/$(MPLAYER_TARGET_BINARY)

mplayer-configure: $(MPLAYER_DIR)/.configured

mplayer-source: $(DL_DIR)/$(MPLAYER_SOURCE)

mplayer-unpacked: $(MPLAYER_DIR)/.unpacked

mplayer-clean:
	rm -f $(TARGET_DIR)/$(MPLAYER_TARGET_BINARY)
	-$(MAKE) -C $(MPLAYER_DIR) clean

mplayer-dirclean:
	rm -rf $(MPLAYER_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_MPLAYER),y)
TARGETS+=mplayer
endif
