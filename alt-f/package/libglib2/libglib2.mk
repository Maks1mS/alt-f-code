#############################################################
#
# libglib2
#
#############################################################

# LIBGLIB2_MAJOR = 2.20
# LIBGLIB2_VERSION = 2.20.5  OK
# LIBGLIB2_SOURCE = glib-$(LIBGLIB2_VERSION).tar.bz2
# LIBGLIB2_SITE = https://download.gnome.org/sources/glib/$(LIBGLIB2_MAJOR)

# LIBGLIB2_MAJOR = 2.25
# LIBGLIB2_VERSION = $(LIBGLIB2_MAJOR).9 BAD -- but include sys/sysmacros.h
# LIBGLIB2_SOURCE = glib-$(LIBGLIB2_VERSION).tar.bz2
# LIBGLIB2_SITE = https://download.gnome.org/sources/glib/$(LIBGLIB2_MAJOR)

# minimum for cups-filters, OK if include sys/sysmacros.h in gio/gdbusmessage.c
# and disable tests in gio/Makefile
LIBGLIB2_MAJOR = 2.30
LIBGLIB2_VERSION = 2.30.3
LIBGLIB2_SOURCE = glib-$(LIBGLIB2_VERSION).tar.xz
LIBGLIB2_SITE = https://download.gnome.org/sources/glib/$(LIBGLIB2_MAJOR)

# LIBGLIB2_MAJOR = 2.34
# LIBGLIB2_VERSION = 2.34.3
# LIBGLIB2_SOURCE = glib-$(LIBGLIB2_VERSION).tar.xz
# LIBGLIB2_SITE = https://download.gnome.org/sources/glib/$(LIBGLIB2_MAJOR)

LIBGLIB2_AUTORECONF = NO
LIBGLIB2_LIBTOOL_PATCH = NO

LIBGLIB2_INSTALL_STAGING = YES
LIBGLIB2_INSTALL_TARGET = YES

LIBGLIB2_INSTALL_STAGING_OPT = DESTDIR=$(STAGING_DIR) LDFLAGS=-L$(STAGING_DIR)/usr/lib install

LIBGLIB2_CONF_ENV =	\
		ac_cv_func_qsort_r=no glib_cv_have_qsort_r=no \
		ac_cv_func_posix_getpwuid_r=yes glib_cv_stack_grows=no \
		glib_cv_uscore=no ac_cv_func_strtod=yes \
		ac_fsusage_space=yes fu_cv_sys_stat_statfs2_bsize=yes \
		ac_cv_func_closedir_void=no ac_cv_func_getloadavg=no \
		ac_cv_lib_util_getloadavg=no ac_cv_lib_getloadavg_getloadavg=no \
		ac_cv_func_getgroups=yes ac_cv_func_getgroups_works=yes \
		ac_cv_func_chown_works=yes ac_cv_have_decl_euidaccess=no \
		ac_cv_func_euidaccess=no ac_cv_have_decl_strnlen=yes \
		ac_cv_func_strnlen_working=yes ac_cv_func_lstat_dereferences_slashed_symlink=yes \
		ac_cv_func_lstat_empty_string_bug=no ac_cv_func_stat_empty_string_bug=no \
		vb_cv_func_rename_trailing_slash_bug=no ac_cv_have_decl_nanosleep=yes \
		jm_cv_func_nanosleep_works=yes gl_cv_func_working_utimes=yes \
		ac_cv_func_utime_null=yes ac_cv_have_decl_strerror_r=yes \
		ac_cv_func_strerror_r_char_p=no jm_cv_func_svid_putenv=yes \
		ac_cv_func_getcwd_null=yes ac_cv_func_getdelim=yes \
		ac_cv_func_mkstemp=yes utils_cv_func_mkstemp_limitations=no \
		utils_cv_func_mkdir_trailing_slash_bug=no \
		ac_cv_have_decl_malloc=yes gl_cv_func_malloc_0_nonnull=yes \
		ac_cv_func_malloc_0_nonnull=yes ac_cv_func_calloc_0_nonnull=yes \
		ac_cv_func_realloc_0_nonnull=yes jm_cv_func_gettimeofday_clobber=no \
		gl_cv_func_working_readdir=yes jm_ac_cv_func_link_follows_symlink=no \
		utils_cv_localtime_cache=no ac_cv_struct_st_mtim_nsec=no \
		gl_cv_func_tzset_clobber=no gl_cv_func_getcwd_null=yes \
		gl_cv_func_getcwd_path_max=yes ac_cv_func_fnmatch_gnu=yes \
		am_getline_needs_run_time_check=no am_cv_func_working_getline=yes \
		gl_cv_func_mkdir_trailing_slash_bug=no gl_cv_func_mkstemp_limitations=no \
		ac_cv_func_working_mktime=yes jm_cv_func_working_re_compile_pattern=yes \
		ac_use_included_regex=no gl_cv_c_restrict=no \
		ac_cv_path_GLIB_GENMARSHAL=$(HOST_DIR)/usr/bin/glib-genmarshal ac_cv_prog_F77=no \
		ac_cv_func_posix_getgrgid_r=no \
		gt_cv_c_wchar_t=$(if $(BR2_USE_WCHAR),yes,no)

LIBGLIB2_CONF_OPT = --enable-shared -enable-static \
	--with-pcre=system --with-libiconv=native --enable-gtk-doc-html=no


LIBGLIB2_HOST_CONF_OPT = --enable-shared -disable-static --enable-debug=no

LIBGLIB2_DEPENDENCIES = uclibc pcre gettext libintl libffi zlib libiconv host-pkgconfig libglib2-host
LIBGLIB2_HOST_DEPENDENCIES = host-pkgconfig

ifneq ($(BR2_ENABLE_LOCALE),y)
LIBGLIB2_DEPENDENCIES+=libiconv
endif

ifeq ($(BR2_PACKAGE_LIBICONV),y)
LIBGLIB2_CONF_OPT += --with-libiconv=gnu
LIBGLIB2_DEPENDENCIES+=libiconv
endif

$(eval $(call AUTOTARGETS,package,libglib2))
$(eval $(call AUTOTARGETS_HOST,package,libglib2))

# "patches" for 2.30.3.
# Notice that AUTOTARGETS_HOST don't have patches applied by default
$(LIBGLIB2_HOST_HOOK_POST_EXTRACT):
	#NAMEVER=$($(PKG)_NAME)-$($(PKG)_VERSION)
	NAMEVER=$($(PKG)_NAME)-$($(PKG)_VERSION) && toolchain/patch-kernel.sh $(@D) $($(PKG)_DIR_PREFIX)/$($(PKG)_NAME) $(NAMEVER)\*.patch $(NAMEVER)\*.patch.$(ARCH)
	touch $@
	
$(LIBGLIB2_HOST_HOOK_POST_CONFIGURE) $(LIBGLIB2_HOOK_POST_CONFIGURE):
	sed -i '/\<stat.h\>/a #include \<sys/sysmacros.h\>' $(@D)/gio/gdbusmessage.c
	sed -i '\|SUBDIRS =|{n;s/tests//}' $(@D)/gio/Makefile.in $(@D)/gio/Makefile
	touch $@

$(LIBGLIB2_HOOK_POST_INSTALL):
	mv $(TARGET_DIR)/usr/bin/gdbus-codegen $(STAGING_DIR)/usr/bin/gdbus-codegen
	rm -rf $(TARGET_DIR)/usr/share/gtk-doc \
		$(TARGET_DIR)/usr/share/aclocal/ \
		$(TARGET_DIR)/usr/lib/glib-2.0 \
		$(TARGET_DIR)/usr/lib/gdbus-2.0 \
		$(TARGET_DIR)/usr/share/glib-2.0 \
		$(TARGET_DIR)/etc/bash_completion.d \
		$(TARGET_DIR)/usr/share/gdb
		# PKG_CONFIG_SYSROOT_DIR is defined by build root, .pc files don't need patch, only <pkg>-config
		#for i in glib-2.0.pc gobject-2.0.pc gmodule-2.0.pc gio-2.0.pc gthread-2.0.pc; do \
		#$(SED) "s|^prefix=.*|prefix=\'$(STAGING_DIR)/usr\'|g" \
		#	-e "s|^exec_prefix=.*|exec_prefix=\'$(STAGING_DIR)/usr\'|g" \
		#	-e "s|^libdir=.*|libdir=\'$(STAGING_DIR)/usr/lib\'|g" \
		#	$(STAGING_DIR)/usr/lib/pkgconfig/$$i; \
		#done
	touch $@
