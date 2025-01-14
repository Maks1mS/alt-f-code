#############################################################
#
# PCRE
#
#############################################################

PCRE_VERSION = 8.20
PCRE_SOURCE = pcre-$(PCRE_VERSION).tar.bz2
PCRE_SITE = $(BR2_SOURCEFORGE_MIRROR)/project/pcre/pcre/$(PCRE_VERSION)
PCRE_INSTALL_STAGING = YES
PCRE_INSTALL_TARGET = YES
PCRE_LIBTOOL_PATCH = NO
PCRE_CONF_OPT = --enable-utf8

ifneq ($(BR2_INSTALL_LIBSTDCPP),y)
# pcre will use the host g++ if a cross version isn't available
PCRE_CONF_OPT += --disable-cpp
endif

PCRE_DEPENDENCIES = uclibc

$(eval $(call AUTOTARGETS,package,pcre))

$(PCRE_HOOK_POST_INSTALL): $(PCRE_TARGET_INSTALL_TARGET)
	$(SED) 's,^prefix=.*,prefix=$(STAGING_DIR)/usr,' \
		-e 's,^exec_prefix=.*,exec_prefix=$(STAGING_DIR)/usr,' \
		-e 's,-L/usr/lib$libR,,' \
		$(STAGING_DIR)/usr/bin/pcre-config
	rm -rf $(TARGET_DIR)/usr/share/doc/pcre
	touch $@
