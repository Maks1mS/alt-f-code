#############################################################
#
# bridge-utils - User Space Program For Controlling Bridging
#
#############################################################

BRIDGE_VERSION:=1.5
BRIDGE_SOURCE:=bridge-utils-$(BRIDGE_VERSION).tar.gz
BRIDGE_SITE=$(BR2_SOURCEFORGE_MIRROR)/projects/bridge/files/bridge
BRIDGE_AUTORECONF:=YES
BRIDGE_INSTALL_STAGING:=NO
BRIDGE_INSTALL_TARGET:=YES
BRIDGE_INSTALL_TARGET_OPT:=DESTDIR=$(TARGET_DIR) install
BRIDGE_CONF_OPT:=--with-linux-headers=$(LINUX_HEADERS_DIR)
BRIDGE_DEPENDENCIES:=uclibc

$(eval $(call AUTOTARGETS,package,bridge))

ifeq ($(BR2_ENABLE_DEBUG),)
# bridge has no install-strip target
$(BRIDGE_HOOK_POST_INSTALL): $(BRIDGE_TARGET_INSTALL_TARGET)
	$(STRIPCMD) $(STRIP_STRIP_ALL) $(TARGET_DIR)/usr/sbin/brctl
	touch $@
endif

# bridge has no uninstall target
$(BRIDGE_TARGET_UNINSTALL):
	$(call MESSAGE,"Uninstalling")
	rm -f $(addprefix $(TARGET_DIR)/usr/,lib/libbridge.a \
		include/libbridge.h man/man8/brctl.8 sbin/brctl)
	rm -f $(BRIDGE_TARGET_INSTALL_TARGET) $(BRIDGE_HOOK_POST_INSTALL)
