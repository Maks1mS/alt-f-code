#############################################################
#
# kexec
#
############################################################

KEXEC_VERSION = 2.0.28
KEXEC_SOURCE = kexec-tools-$(KEXEC_VERSION).tar.xz
KEXEC_SITE = https://mirrors.edge.kernel.org/pub/linux/utils/kernel/kexec

KEXEC_INSTALL_TARGET_OPT = DESTDIR=$(TARGET_DIR) install

KEXEC_DEPENDENCIES = uclibc

KEXEC_CONF_OPT = --without-xen

ifeq ($(BR2_PACKAGE_KEXEC_ZLIB),y)
KEXEC_CONF_OPT += --with-zlib
KEXEC_DEPENDENCIES += zlib
else
KEXEC_CONF_OPT += --without-zlib
endif

ifeq ($(BR2_PACKAGE_KEXEC_LZMA),y)
KEXEC_CONF_OPT += --with-lzma
KEXEC_DEPENDENCIES += xz
else
KEXEC_CONF_OPT += --without-lzma
endif

KEXEC_CONF_ENV = CC="$(TARGET_CC)" CFLAGS="$(TARGET_CFLAGS) $(BR2_PACKAGE_KEXEC_OPTIM)"

$(eval $(call AUTOTARGETS,package,kexec))

$(KEXEC_HOOK_POST_INSTALL): $(KEXEC_TARGET_INSTALL_TARGET)
ifneq ($(BR2_ENABLE_DEBUG),y)
	$(STRIPCMD) $(STRIP_STRIP_ALL) $(TARGET_DIR)/usr/sbin/kexec
	#$(STRIPCMD) $(STRIP_STRIP_ALL) $(TARGET_DIR)/usr/sbin/kdump
endif
	rm -rf $(TARGET_DIR)/usr/lib/kexec-tools
	rm -f $(TARGET_DIR)/usr/sbin/kdump
	rm -f $(TARGET_DIR)/usr/sbin/vmcore-dmesg
	touch $@
