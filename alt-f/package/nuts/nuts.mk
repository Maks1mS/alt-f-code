#############################################################
#
# nuts
#
#############################################################

NUTS_VERSION = 2.6.1
NUTS_SOURCE = nut-$(NUTS_VERSION).tar.gz
NUTS_SITE = http://www.networkupstools.org/source/2.6

NUTS_AUTORECONF = NO
NUTS_INSTALL_STAGING = NO
NUTS_INSTALL_TARGET = YES
NUTS_LIBTOOL_PATCH = NO

NUTS_DEPENDENCIES = uclibc libusb netsnmp openssl-compat libgd neon

#--with-snmp-includes="-I$(STAGING_DIR)/usr/include"
#--with-gd-includes="-I$(STAGING_DIR)/usr/include"
#--with-gd-libs="-L$(STAGING_DIR)/usr/lib -lgd -ljpeg -lpng -lz"

NUTS_CONF_ENV = LIBS=-lm
NUTS_CONF_OPT = --with-user=ups --with-group=nut \
	--program-prefix="" --sysconfdir=/etc/nut --datadir=/usr/share/nut \
	--with-snmp-libs=-lnetsnmp \
	--with-gd-libs="-lgd -ljpeg -lpng -lz" \
	--with-ssl-includes="-I$(STAGING_DIR)/compat/usr/include" \
	--with-ssl-libs="-L$(STAGING_DIR)/compat/usr/lib -lcrypto -lssl" \
	--with-cgi --with-cgipath=/usr/www/cgi-bin/nut \
	--with-htmlpath=/usr/www/nut --with-drvpath=/usr/lib/nut/drivers

$(eval $(call AUTOTARGETS,package,nuts))

$(NUTS_HOOK_POST_INSTALL):
	(cd $(TARGET_DIR)/etc/nut; \
	for i in hosts.conf nut.conf ups.conf upsd.conf upsd.users upsmon.conf \
		upssched.conf upsset.conf upsstats.html upsstats-single.html; do \
		mv $$i.sample $$i; \
	done; \
	$(RM) -rf $(TARGET_DIR)/etc/udev; \
	)
	touch $@
