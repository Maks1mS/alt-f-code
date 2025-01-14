#############################################################
#
# openssl
#
############################################################

OPENSSL_COMPAT_VERSION:=1.0.2u
OPENSSL_COMPAT_VERSION2:=1.0.2
OPENSSL_COMPAT_SITE:=https://www.openssl.org/source/old/$(OPENSSL_COMPAT_VERSION2)
OPENSSL_COMPAT_SOURCE:=openssl-$(OPENSSL_COMPAT_VERSION).tar.gz

OPENSSL_COMPAT_MAKE = $(MAKE1)

# Some architectures are optimized in OpenSSL
OPENSSL_COMPAT_TARGET_ARCH=generic32
ifeq ($(ARCH),avr32)
OPENSSL_COMPAT_TARGET_ARCH=avr32
endif
ifeq ($(ARCH),ia64)
OPENSSL_COMPAT_TARGET_ARCH=ia64
endif
ifeq ($(ARCH),powerpc)
OPENSSL_COMPAT_TARGET_ARCH=ppc
endif
ifeq ($(ARCH),x86_64)
OPENSSL_COMPAT_TARGET_ARCH=x86_64
endif

OPENSSL_COMPAT_INSTALL_STAGING = YES
OPENSSL_COMPAT_INSTALL_STAGING_OPT = INSTALL_PREFIX=$(STAGING_DIR)/compat install
#OPENSSL_COMPAT_INSTALL_TARGET_OPT = INSTALL_PREFIX=$(TARGET_DIR) install_sw

OPENSSL_COMPAT_DEPENDENCIES = openssl

# specific compiler optimization
OPENSSL_COMPAT_CFLAGS = $(TARGET_OPTIMIZATION)
ifneq ($(BR2_PACKAGE_OPENSSL_COMPAT_SIZEOPTIM),)
	OPENSSL_COMPAT_CFLAGS += $(BR2_PACKAGE_OPENSSL_COMPAT_SIZEOPTIM)
endif

OPENSSL_COMPAT_CONF_OPT = -DOPENSSL_SMALL_FOOTPRINT 
ifeq ($(BR2_PACKAGE_CRYPTODEV),y)
	OPENSSL_COMPAT_DEPENDENCIES += cryptodev
	OPENSSL_COMPAT_CONF_OPT += -DHAVE_CRYPTODEV -DUSE_CRYPTODEV_DIGESTS -DHASH_MAX_LEN=64
endif

OPENSSL_COMPAT_CFLAGS += $(OPENSSL_COMPAT_CONF_OPT)

$(eval $(call AUTOTARGETS,package,openssl-compat))

# load cryptodev.ko mv_cesa.ko
# MV-CESA:Could not register sha1 driver FIXME
# MV-CESA:Could not register hmac-sha1 driver FIXME
# 
# / # openssl engine cryptodev
# (cryptodev) cryptodev engine
# 
# /# openssl speed -evp aes-128-cbc
# type                    16 bytes        64 bytes     256 bytes    1024 bytes        8192 bytes
# aes-128-cbc       3462.90k      4104.75k      4306.43k       4356.28k       4205.59k (no mv_cesa)
# aes-128-cbc       3675.66k    14573.71k    43141.69k   286182.40k   375778.74k (mv_cesa)
# 
# / # openssl speed -evp sha1
# sha1               575.41k     1823.25k     4580.09k     7323.65k     8909.83k (no mv_cesa)
# sha1               541.06k     1754.84k     4469.86k     7254.65k     8866.47k (mv_cesa)

$(OPENSSL_COMPAT_TARGET_CONFIGURE):
	(cd $(OPENSSL_COMPAT_DIR); \
		$(TARGET_CONFIGURE_ARGS) \
		$(TARGET_CONFIGURE_OPTS) \
		./Configure \
			--prefix=/usr \
			--openssldir=/etc/ssl \
			threads shared \
			no-idea no-md2 no-mdc2 no-rc5 no-camellia no-seed \
			no-krb5 no-jpake no-store no-err \
 			no-zlib no-comp no-ssl2 no-ssl3 \
			$(OPENSSL_COMPAT_CONF_OPT) \
			linux-$(OPENSSL_COMPAT_TARGET_ARCH) \
	)
	$(SED) "s/build_tests //" $(OPENSSL_COMPAT_DIR)/Makefile
	mkdir -p $(OPENSSL_COMPAT_DIR)/include/crypto
	cp $(STAGING_DIR)/usr/include/crypto/cryptodev.h $(OPENSSL_COMPAT_DIR)/include/crypto/
	touch $@

$(OPENSSL_COMPAT_TARGET_BUILD):
	# libs compiled with chosen optimization
	$(SED) "s:-O[s0-9]:$(OPENSSL_COMPAT_CFLAGS):" $(OPENSSL_COMPAT_DIR)/Makefile
	$(OPENSSL_COMPAT_MAKE) CC=$(TARGET_CC) MAKEDEPPROG=$(TARGET_CC) -C $(OPENSSL_COMPAT_DIR) depend build_libs
	# openssl program compiled with -Os, saves 27KB
	# $(SED) "s:-O[0-9]:-Os:" $(OPENSSL_COMPAT_DIR)/Makefile
	# $(OPENSSL_COMPAT_MAKE) CC=$(TARGET_CC) MAKEDEPPROG=$(TARGET_CC) -C $(OPENSSL_COMPAT_DIR) build_apps
	touch $@

$(OPENSSL_COMPAT_TARGET_INSTALL_TARGET):
	cp $(OPENSSL_COMPAT_DIR)/libcrypto.so.1.0.0 $(OPENSSL_COMPAT_DIR)/libssl.so.1.0.0 $(TARGET_DIR)/usr/lib
	cp $(OPENSSL_COMPAT_DIR)/libcrypto.so.1.0.0 $(OPENSSL_COMPAT_DIR)/libssl.so.1.0.0 $(STAGING_DIR)/usr/lib
	touch $@

# $(OPENSSL_COMPAT_HOOK_POST_INSTALL):
# 	$(if $(BR2_HAVE_DEVFILES),,rm -rf $(TARGET_DIR)/usr/lib/ssl)
# # ifeq ($(BR2_PACKAGE_OPENSSL_COMPAT_BIN),y)
# # 	$(STRIPCMD) $(STRIP_STRIP_ALL) $(TARGET_DIR)/usr/bin/openssl
# # else
# # 	rm -f $(TARGET_DIR)/usr/bin/openssl
# # endif
# 	rm -f $(TARGET_DIR)/usr/bin/c_rehash
# 	# libraries gets installed read only, so strip fails
# 	for i in $(addprefix $(TARGET_DIR)/usr/lib/,libcrypto.so.* libssl.so.*); \
# 	do chmod +w $$i; $(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $$i; done
# ifneq ($(BR2_PACKAGE_OPENSSL_COMPAT_ENGINES),y)
# 	rm -rf $(TARGET_DIR)/usr/lib/engines
# else
# 	chmod +w $(TARGET_DIR)/usr/lib/engines/lib*.so
# 	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/usr/lib/engines/lib*.so
# endif
# 	touch $@

$(OPENSSL_COMPAT_TARGET_UNINSTALL):
	$(call MESSAGE,"Uninstalling")
	rm -rf $(addprefix $(TARGET_DIR)/,etc/ssl usr/bin/openssl usr/include/openssl)
	rm -rf $(addprefix $(TARGET_DIR)/usr/lib/,ssl engines libcrypto* libssl* pkgconfig/libcrypto.pc)
	rm -rf $(addprefix $(STAGING_DIR)/,etc/ssl usr/bin/openssl usr/include/openssl)
	rm -rf $(addprefix $(STAGING_DIR)/usr/lib/,ssl engines libcrypto* libssl* pkgconfig/libcrypto.pc)
	rm -f $(OPENSSL_COMPAT_TARGET_INSTALL_TARGET) $(OPENSSL_COMPAT_HOOK_POST_INSTALL)
