#############################################################
#
# pyopenssl
#
############################################################

# no need to be compiled, it is now pure python
# requires cryptography which requires compilation

#PYOPENSSL_VERSION = 17.5.0
PYOPENSSL_VERSION = 19.0.0
PYOPENSSL_SOURCE = pyopenssl-$(PYOPENSSL_VERSION).tar.gz
PYOPENSSL_SITE = https://github.com/pyca/pyopenssl/archive


PYOPENSSL_AUTORECONF = NO
PYOPENSSL_INSTALL_STAGING = NO
PYOPENSSL_INSTALL_TARGET = NO
PYOPENSSL_LIBTOOL_PATCH = NO

PYOPENSSL_DIR:=$(BUILD_DIR)/pyopenssl-$(PYOPENSSL_VERSION)
PYOPENSSL_CAT:=$(ZCAT)

PYOPENSSL_BINARY:=SSL.so
PYOPENSSL_SITE_PACKAGE_DIR=usr/lib/python$(PYTHON_VERSION_MAJOR)/site-packages/OpenSSL
PYOPENSSL_TARGET_BINARY:=$(PYOPENSSL_SITE_PACKAGE_DIR)/$(PYOPENSSL_BINARY)

PYOPENSSL_CFLAGS = CFLAGS+=" -I$(STAGING_DIR)/usr/include/python$(PYTHON_VERSION_MAJOR)"

$(DL_DIR)/$(PYOPENSSL_SOURCE):
	 #$(call DOWNLOAD,$(PYOPENSSL_SITE),$(PYOPENSSL_SOURCE))
	$(call DOWNLOAD,$(PYOPENSSL_SITE),$(PYOPENSSL_VERSION).tar.gz)
	(cd $(DL_DIR); ln -sf $(PYOPENSSL_VERSION).tar.gz $(PYOPENSSL_SOURCE) )
	mkdir -p $(BUILD_DIR)/pyopenssl-$(PYOPENSSL_VERSION)
	touch $@

$(PYOPENSSL_DIR)/.unpacked: $(DL_DIR)/$(PYOPENSSL_SOURCE)
	$(PYOPENSSL_CAT) $(DL_DIR)/$(PYOPENSSL_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $@

$(PYOPENSSL_DIR)/.patched: $(PYOPENSSL_DIR)/.unpacked
	toolchain/patch-kernel.sh $(PYOPENSSL_DIR) package/pyopenssl/ pyopenssl-$(PYOPENSSL_VERSION)-\*.patch
	touch $@

$(PYOPENSSL_DIR)/.build: python $(PYOPENSSL_DIR)/.patched
	(cd $(PYOPENSSL_DIR); \
		$(TARGET_CONFIGURE_OPTS) $(TARGET_CONFIGURE_ENV) LDSHARED="$(TARGET_CC) -shared" $(PYOPENSSL_CFLAGS) \
		LD_LIBRARY_PATH=$(HOST_DIR)/usr/lib/ $(HOST_DIR)/usr/bin/python setup.py \
		bdist_dumb --plat-name $(GNU_TARGET_NAME) --relative \
	)
	touch $@

$(TARGET_DIR)/$(PYOPENSSL_TARGET_BINARY): $(PYOPENSSL_DIR)/.build
	tar -C $(TARGET_DIR)/usr -xf $(PYOPENSSL_DIR)/dist/pyOpenSSL-$(PYOPENSSL_VERSION).$(GNU_TARGET_NAME).tar.gz
	find $(TARGET_DIR)/$(PYOPENSSL_SITE_PACKAGE_DIR) -name \*.pyc -delete
	touch $(TARGET_DIR)/$(PYOPENSSL_TARGET_BINARY)

pyopenssl: $(TARGET_DIR)/$(PYOPENSSL_TARGET_BINARY)

pyopenssl-source: $(DL_DIR)/$(PYOPENSSL_SOURCE)

pyopenssl-unpack: $(PYOPENSSL_DIR)/.unpacked

pyopenssl-build: $(PYOPENSSL_DIR)/.build

pyopenssl-install: $(TARGET_DIR)/$(PYOPENSSL_TARGET_BINARY)

pyopenssl-dirclean:
	rm -rf $(PYOPENSSL_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_PYOPENSSL),y)
TARGETS+=pyopenssl
endif
