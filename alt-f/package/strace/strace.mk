#############################################################
#
# strace
#
#############################################################

STRACE_VERSION:=4.5.18
#STRACE_VERSION:=5.18 last
#STRACE_VERSION:=4.21 nope
#STRACE_VERSION:=4.6
#STRACE_VERSION:=4.13

STRACE_SOURCE:=strace-$(STRACE_VERSION).tar.bz2
STRACE_SITE:=$(BR2_SOURCEFORGE_MIRROR)/project/strace/strace/$(STRACE_VERSION)

STRACE_AUTORECONF:=NO
STRACE_INSTALL_STAGING:=NO
STRACE_INSTALL_TARGET:=YES

STRACE_DEPENDENCIES:=uclibc

STRACE_CONF_ENV:= ac_cv_header_linux_if_packet_h=yes \
		  ac_cv_header_linux_netlink_h=yes \
	          $(if $(BR2_LARGEFILE),ac_cv_type_stat64=yes,ac_cv_type_stat64=no)

$(eval $(call AUTOTARGETS,package,strace))

$(STRACE_HOOK_POST_INSTALL): $(STRACE_TARGET_INSTALL_TARGET)
	$(STRIPCMD) $(STRIP_STRIP_ALL) $(TARGET_DIR)/usr/bin/strace
	rm -f $(TARGET_DIR)/usr/bin/strace-graph
ifeq ($(BR2_CROSS_TOOLCHAIN_TARGET_UTILS),y)
	mkdir -p $(STAGING_DIR)/usr/$(REAL_GNU_TARGET_NAME)/target_utils
	install -c $(TARGET_DIR)/usr/bin/strace \
		$(STAGING_DIR)/usr/$(REAL_GNU_TARGET_NAME)/target_utils/strace
endif
	touch $@
