#############################################################
#
# lsof
#
#############################################################

#LSOF_VERSION:=4.84 # patches have LSOF_VERSION hardcoded
LSOF_VERSION:=4.81
LSOF_SOURCE:=lsof_$(LSOF_VERSION).tar.gz
LSOF_SITE:=ftp://ftp.fu-berlin.de/pub/unix/tools/lsof/OLD/
# since 4.93 https://github.com/lsof-org/lsof/releases/download/4.99.0/lsof-4.99.0.tar.gz

LSOF_CAT:=$(ZCAT)
LSOF_DIR:=$(BUILD_DIR)/lsof_$(LSOF_VERSION)
LSOF_BINARY:=lsof
LSOF_TARGET_BINARY:=usr/bin/lsof
LSOF_INCLUDE:=$(STAGING_DIR)/usr/include

BR2_LSOF_CFLAGS:=
ifeq ($(BR2_LARGEFILE),)
BR2_LSOF_CFLAGS+=-U_FILE_OFFSET_BITS
endif
ifeq ($(BR2_INET_IPV6),)
BR2_LSOF_CFLAGS+=-UHASIPv6
endif

$(DL_DIR)/$(LSOF_SOURCE):
	 $(call DOWNLOAD,$(LSOF_SITE),$(LSOF_SOURCE))

lsof-source: $(DL_DIR)/$(LSOF_SOURCE)

lsof-unpacked: $(LSOF_DIR)/.unpacked

$(LSOF_DIR)/.unpacked: $(DL_DIR)/$(LSOF_SOURCE)
	$(LSOF_CAT) $(DL_DIR)/$(LSOF_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	(cd $(LSOF_DIR);tar xf lsof_$(LSOF_VERSION)_src.tar;rm -f lsof_$(LSOF_VERSION)_src.tar; chmod -R +w lsof_$(LSOF_VERSION)_src )
	toolchain/patch-kernel.sh $(LSOF_DIR) package/lsof/ \*.patch
	touch $(LSOF_DIR)/.unpacked

$(LSOF_DIR)/.configured: $(LSOF_DIR)/.unpacked
	(cd $(LSOF_DIR)/lsof_$(LSOF_VERSION)_src; echo n | $(TARGET_CONFIGURE_OPTS) DEBUG="$(TARGET_CFLAGS) $(BR2_LSOF_CFLAGS)" LSOF_INCLUDE="$(LSOF_INCLUDE)" ./Configure linux)
	touch $(LSOF_DIR)/.configured

$(LSOF_DIR)/lsof_$(LSOF_VERSION)_src/$(LSOF_BINARY): $(LSOF_DIR)/.configured
ifeq ($(BR2_USE_WCHAR),)
	$(SED) 's,^#define[[:space:]]*HASWIDECHAR.*,#undef HASWIDECHAR,' $(LSOF_DIR)/lsof_$(LSOF_VERSION)_src/machine.h
	$(SED) 's,^#define[[:space:]]*WIDECHARINCL.*,,' $(LSOF_DIR)/lsof_$(LSOF_VERSION)_src/machine.h
endif
ifeq ($(BR2_ENABLE_LOCALE),)
	$(SED) 's,^#define[[:space:]]*HASSETLOCALE.*,#undef HASSETLOCALE,' $(LSOF_DIR)/lsof_$(LSOF_VERSION)_src/machine.h
endif
	$(MAKE) $(TARGET_CONFIGURE_OPTS) DEBUG="$(TARGET_CFLAGS) $(BR2_LSOF_CFLAGS)" -C $(LSOF_DIR)/lsof_$(LSOF_VERSION)_src

$(TARGET_DIR)/$(LSOF_TARGET_BINARY): $(LSOF_DIR)/lsof_$(LSOF_VERSION)_src/$(LSOF_BINARY)
	if test -h $(TARGET_DIR)/$(LSOF_TARGET_BINARY); then rm $(TARGET_DIR)/$(LSOF_TARGET_BINARY); fi
	cp $(LSOF_DIR)/lsof_$(LSOF_VERSION)_src/$(LSOF_BINARY) $@
	$(STRIPCMD) $@

lsof-build: $(LSOF_DIR)/lsof_$(LSOF_VERSION)_src/$(LSOF_BINARY)

lsof: uclibc $(TARGET_DIR)/$(LSOF_TARGET_BINARY)

lsof-clean:
	-rm -f $(TARGET_DIR)/$(LSOF_TARGET_BINARY)
	-$(MAKE) -C $(LSOF_DIR)/lsof_$(LSOF_VERSION)_src clean

lsof-dirclean:
	rm -rf $(LSOF_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_LSOF),y)
TARGETS+=lsof
endif
