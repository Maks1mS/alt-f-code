#############################################################
#
# module-init-tools
#
#############################################################

MODULE_INIT_TOOLS_VERSION=3.2.2
#MODULE_INIT_TOOLS_VERSION=3.15
# not available, it will fallback to buildroot.net, which has a copy 
MODULE_INIT_TOOLS_SOURCE=module-init-tools-$(MODULE_INIT_TOOLS_VERSION).tar.bz2
MODULE_INIT_TOOLS_SITE=$(BR2_KERNEL_MIRROR)/linux/utils/kernel/module-init-tools
MODULE_INIT_TOOLS_CAT:=$(BZCAT)

# the debian snapshot contains th original, but...
#MODULE_INIT_TOOLS_SOURCE=module-init-tools_$(MODULE_INIT_TOOLS_VERSION).orig.tar.gz
#MODULE_INIT_TOOLS_SITE=http://snapshot.debian.org/archive/debian/20051212T000000Z/pool/main/m/module-init-tools
#MODULE_INIT_TOOLS_CAT:=$(ZCAT)

MODULE_INIT_TOOLS_DIR=$(BUILD_DIR)/module-init-tools-$(MODULE_INIT_TOOLS_VERSION)
MODULE_INIT_TOOLS_DIR2=$(TOOL_BUILD_DIR)/module-init-tools-$(MODULE_INIT_TOOLS_VERSION)
MODULE_INIT_TOOLS_BINARY=depmod
MODULE_INIT_TOOLS_TARGET_BINARY=$(TARGET_DIR)/sbin/$(MODULE_INIT_TOOLS_BINARY)

STRIPPROG=$(STRIPCMD)

$(DL_DIR)/$(MODULE_INIT_TOOLS_SOURCE):
	$(call DOWNLOAD,$(MODULE_INIT_TOOLS_SITE),$(MODULE_INIT_TOOLS_SOURCE))

$(MODULE_INIT_TOOLS_DIR)/.unpacked: $(DL_DIR)/$(MODULE_INIT_TOOLS_SOURCE)
	$(MODULE_INIT_TOOLS_CAT) $(DL_DIR)/$(MODULE_INIT_TOOLS_SOURCE) | tar -C $(BUILD_DIR) -xvf -
	toolchain/patch-kernel.sh $(MODULE_INIT_TOOLS_DIR) package/module-init-tools \*.patch
	$(CONFIG_UPDATE) $(MODULE_INIT_TOOLS_DIR)
	touch $(MODULE_INIT_TOOLS_DIR)/.unpacked

$(MODULE_INIT_TOOLS_DIR)/.configured: $(MODULE_INIT_TOOLS_DIR)/.unpacked
	(cd $(MODULE_INIT_TOOLS_DIR); rm -f config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		INSTALL=$(MODULE_INIT_TOOLS_DIR)/install-sh \
		CFLAGS=-DCONFIG_NO_BACKWARDS_COMPAT \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/ \
		--sysconfdir=/etc \
		--program-transform-name='' \
	)
	touch $(MODULE_INIT_TOOLS_DIR)/.configured

$(MODULE_INIT_TOOLS_DIR)/$(MODULE_INIT_TOOLS_BINARY): $(MODULE_INIT_TOOLS_DIR)/.configured
	$(MAKE) CC=$(TARGET_CC) -C $(MODULE_INIT_TOOLS_DIR)
	touch -c $(MODULE_INIT_TOOLS_DIR)/$(MODULE_INIT_TOOLS_BINARY)

ifeq ($(BR2_PACKAGE_MODUTILS),y)
$(MODULE_INIT_TOOLS_TARGET_BINARY): \
	$(MODULE_INIT_TOOLS_DIR)/$(MODULE_INIT_TOOLS_BINARY) \
	modutils
else
$(MODULE_INIT_TOOLS_TARGET_BINARY): \
	$(MODULE_INIT_TOOLS_DIR)/$(MODULE_INIT_TOOLS_BINARY)
endif
ifeq ($(BR2_PACKAGE_MODUTILS),y)
	$(MAKE) prefix=$(TARGET_DIR) -C $(MODULE_INIT_TOOLS_DIR) moveold
endif
	STRIPPROG='$(STRIPPROG)' \
	$(MAKE) prefix=$(TARGET_DIR) -C $(MODULE_INIT_TOOLS_DIR) install-exec
	rm -Rf $(TARGET_DIR)/usr/man
	rm -f $(TARGET_DIR)/sbin/generate-modprobe.conf
	rm -f $(TARGET_DIR)/sbin/insmod.static
	touch -c $(MODULE_INIT_TOOLS_TARGET_BINARY)

module-init-tools: uclibc $(MODULE_INIT_TOOLS_TARGET_BINARY)

module-init-tools-clean:
	$(MAKE) prefix=$(TARGET_DIR)/usr -C $(MODULE_INIT_TOOLS_DIR) uninstall
	-$(MAKE) -C $(MODULE_INIT_TOOLS_DIR) clean

module-init-tools-dirclean:
	rm -rf $(MODULE_INIT_TOOLS_DIR)

#############################################################


$(MODULE_INIT_TOOLS_DIR2)/.source: $(DL_DIR)/$(MODULE_INIT_TOOLS_SOURCE)
	$(MODULE_INIT_TOOLS_CAT) $(DL_DIR)/$(MODULE_INIT_TOOLS_SOURCE) | tar -C $(TOOL_BUILD_DIR) -xf -
	toolchain/patch-kernel.sh $(MODULE_INIT_TOOLS_DIR2) package/module-init-tools \*.patch
	$(CONFIG_UPDATE) $(MODULE_INIT_TOOLS_DIR2)
	touch $(MODULE_INIT_TOOLS_DIR2)/.source

	# install glibc-devel-static

$(MODULE_INIT_TOOLS_DIR2)/.configured: $(MODULE_INIT_TOOLS_DIR2)/.source
	(cd $(MODULE_INIT_TOOLS_DIR2); \
		CC="$(HOSTCC)" \
		CFLAGS=-DCONFIG_NO_BACKWARDS_COMPAT \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_HOST_NAME) \
		--build=$(GNU_HOST_NAME) \
		--sysconfdir=/etc \
		--program-transform-name='' \
	)
	touch $(MODULE_INIT_TOOLS_DIR2)/.configured

$(MODULE_INIT_TOOLS_DIR2)/$(MODULE_INIT_TOOLS_BINARY): $(MODULE_INIT_TOOLS_DIR2)/.configured
	$(MAKE) -C $(MODULE_INIT_TOOLS_DIR2)
	touch -c $(MODULE_INIT_TOOLS_DIR2)/$(MODULE_INIT_TOOLS_BINARY)

$(STAGING_DIR)/bin/$(GNU_TARGET_NAME)-depmod26: $(MODULE_INIT_TOOLS_DIR2)/$(MODULE_INIT_TOOLS_BINARY)
	$(INSTALL) -D $(MODULE_INIT_TOOLS_DIR2)/$(MODULE_INIT_TOOLS_BINARY) $(STAGING_DIR)/bin/$(GNU_TARGET_NAME)-depmod26

cross-depmod26: $(STAGING_DIR)/bin/$(GNU_TARGET_NAME)-depmod26

module-init-tools-source cross-depmod26-source: $(DL_DIR)/$(MODULE_INIT_TOOLS_SOURCE)

cross-depmod26-clean:
	rm -f $(STAGING_DIR)/bin/$(GNU_TARGET_NAME)-depmod26
	-$(MAKE) -C $(MODULE_INIT_TOOLS_DIR2) clean

cross-depmod26-dirclean:
	rm -rf $(MODULE_INIT_TOOLS_DIR2)

ifeq ($(BR2_PACKAGE_LINUX),y)
HOST_SOURCE+=module-init-tools-source
endif

#############################################################
#
## Toplevel Makefile options
#
##############################################################
ifeq ($(BR2_PACKAGE_MODULE_INIT_TOOLS),y)
TARGETS+=module-init-tools
endif
