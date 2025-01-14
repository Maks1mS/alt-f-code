#############################################################
#
# quota-tools
#
#############################################################

#QUOTA_TOOLS_VERSION = 4.01
#QUOTA_TOOLS_VERSION = 4.06
QUOTA_TOOLS_VERSION = 4.09
QUOTA_TOOLS_SOURCE = quota-$(QUOTA_TOOLS_VERSION).tar.gz
QUOTA_TOOLS_SITE = $(BR2_SOURCEFORGE_MIRROR)/project/linuxquota/quota-tools/$(QUOTA_TOOLS_VERSION)

QUOTA_TOOLS_AUTORECONF = NO 
QUOTA_TOOLS_LIBTOOL_PATCH = NO

QUOTA_TOOLS_INSTALL_STAGING = NO
QUOTA_TOOLS_INSTALL_TARGET = YES

QUOTA_TOOLS_DEPENDENCIES = e2fsprogs

QUOTA_TOOLS_CONF_OPT = --disable-nls --disable-rpc --disable-netlink
QUOTA_TOOLS_MAKE_ENV = CC="$(TARGET_CC)"

$(eval $(call AUTOTARGETS,package,quota-tools))
