#############################################################
#
# wpa_supplicant
#
############################################################

WPA_SUPPLICANT_VERSION = 2.9
WPA_SUPPLICANT_SOURCE = wpa_supplicant-$(WPA_SUPPLICANT_VERSION).tar.gz
#WPA_SUPPLICANT_SITE = http://hostap.epitest.fi/releases
WPA_SUPPLICANT_SITE = https://w1.fi/releases

WPA_SUPPLICANT_LIBTOOL_PATCH = NO
WPA_SUPPLICANT_INSTALL_TARGET_OPT = DESTDIR=$(TARGET_DIR) install
WPA_SUPPLICANT_DEPENDENCIES = uclibc libnl

WPA_SUPPLICANT_CONFIG = $(WPA_SUPPLICANT_DIR)/wpa_supplicant/.config
WPA_SUPPLICANT_SUBDIR = wpa_supplicant

WPA_SUPPLICANT_TARGET_BINS = wpa_cli wpa_supplicant wpa_passphrase
WPA_SUPPLICANT_DBUS_SERVICE = fi.epitest.hostap.WPASupplicant

ifeq ($(BR2_PACKAGE_WPA_SUPPLICANT_OPENSSL),y)
	WPA_SUPPLICANT_DEPENDENCIES += openssl
endif

#ifeq ($(BR2_PACKAGE_DBUS),y)
#	WPA_SUPPLICANT_DEPENDENCIES += dbus
#endif

$(eval $(call AUTOTARGETS,package,wpa-supplicant))

$(WPA_SUPPLICANT_TARGET_CONFIGURE):
	# openssl-1.1. compiled with no-ocsp. Is this possibly right?
	$(SED) 's/OPENSSL_NO_TLSEXT/OPENSSL_NO_OCSP/' $(WPA_SUPPLICANT_DIR)/src/crypto/tls_openssl.c
	cp $(WPA_SUPPLICANT_DIR)/wpa_supplicant/defconfig $(WPA_SUPPLICANT_CONFIG)
	$(SED) "s/^#CONFIG_LIBNL32/CONFIG_LIBNL32/g" \
		-e "s/^CONFIG_DRIVER_WIRED/#CONFIG_DRIVER_WIRED/g"  \
		$(WPA_SUPPLICANT_CONFIG)
	echo "LIBNL_INC = $(STAGING_DIR)/usr/include/libnl3" >> $(WPA_SUPPLICANT_CONFIG)
	echo "CFLAGS += $(TARGET_CFLAGS)" >> $(WPA_SUPPLICANT_CONFIG)
	echo "LDLAGS += $(TARGET_LDFLAGS) -L$(STAGING_DIR)/usr/lib" >> $(WPA_SUPPLICANT_CONFIG)
	echo "LIBS += -L$(STAGING_DIR)/usr/lib" >> $(WPA_SUPPLICANT_CONFIG)
	echo "CC = $(TARGET_CC)" >> $(WPA_SUPPLICANT_CONFIG)
	$(SED) "s/\/local//" $(WPA_SUPPLICANT_DIR)/wpa_supplicant/Makefile
ifneq ($(BR2_PACKAGE_WPA_SUPPLICANT_EAP),y)
	$(SED) "s/^CONFIG_EAP_*/#CONFIG_EAP_/g" $(WPA_SUPPLICANT_CONFIG)
	echo "CONFIG_TLS=none" >>$(WPA_SUPPLICANT_CONFIG)
else
ifeq ($(BR2_PACKAGE_WPA_SUPPLICANT_OPENSSL),y)
	echo "CONFIG_TLS=openssl" >>$(WPA_SUPPLICANT_CONFIG)
else
	echo "CONFIG_TLS=internal" >>$(WPA_SUPPLICANT_CONFIG)
	echo "CONFIG_INTERNAL_LIBTOMMATH=y" >>$(WPA_SUPPLICANT_CONFIG)
endif
endif
#ifeq ($(BR2_PACKAGE_DBUS),y)
#	echo "CONFIG_CTRL_IFACE_DBUS=y" >>$(WPA_SUPPLICANT_CONFIG)
#endif
	$(SED) 's/CONFIG_CTRL_IFACE_DBUS_NEW=y/#&/' \
		-e 's/CONFIG_CTRL_IFACE_DBUS_INTRO=y/#&/' $(WPA_SUPPLICANT_CONFIG)
	touch $@

$(WPA_SUPPLICANT_HOOK_POST_INSTALL):
ifneq ($(BR2_PACKAGE_WPA_SUPPLICANT_CLI),y)
	rm -f $(TARGET_DIR)/usr/sbin/wpa_cli
endif
ifneq ($(BR2_PACKAGE_WPA_SUPPLICANT_PASSPHRASE),y)
	rm -f $(TARGET_DIR)/usr/sbin/wpa_passphrase
endif
# ifeq ($(BR2_PACKAGE_DBUS),y)
# 	$(INSTALL) -D \
# 	  $(WPA_SUPPLICANT_DIR)/wpa_supplicant/dbus-wpa_supplicant.conf \
# 	  $(TARGET_DIR)/etc/dbus-1/system.d/wpa_supplicant.conf
# 	$(INSTALL) -D \
# 	  $(WPA_SUPPLICANT_DIR)/wpa_supplicant/dbus-wpa_supplicant.service \
# 	  $(TARGET_DIR)/usr/share/dbus-1/system-services/$(WPA_SUPPLICANT_DBUS_SERVICE).service
# endif

$(WPA_SUPPLICANT_TARGET_UNINSTALL):
	$(call MESSAGE,"Uninstalling")
	rm -f $(addprefix $(TARGET_DIR)/usr/sbin/, $(WPA_SUPPLICANT_TARGET_BINS))
	rm -f $(TARGET_DIR)/etc/dbus-1/system.d/wpa_supplicant.conf
	rm -f $(TARGET_DIR)/usr/share/dbus-1/system-services/$(WPA_SUPPLICANT_DBUS_SERVICE).service
	rm -f $(WPA_SUPPLICANT_TARGET_INSTALL_TARGET) $(WPA_SUPPLICANT_HOOK_POST_INSTALL)

