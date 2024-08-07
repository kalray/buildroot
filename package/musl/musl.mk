################################################################################
#
# musl
#
################################################################################

MUSL_VERSION = $(call qstrip,$(BR2_MUSL_VERSION))
MUSL_SOURCE = musl-$(MUSL_VERSION).tar.gz
MUSL_LICENSE = MIT
MUSL_LICENSE_FILES = COPYRIGHT
MUSL_CPE_ID_VENDOR = musl-libc
ifeq ($(BR2_kvx),y)
MUSL_SITE = $(call kalray,musl,$(MUSL_VERSION))
ifneq ($(call qstrip,$(BR2_KALRAY_SITE)),)
BR_NO_CHECK_HASH_FOR += $(MUSL_SOURCE)
endif
else
MUSL_SITE = http://www.musl-libc.org/releases
endif

# Before musl is configured, we must have the first stage
# cross-compiler and the kernel headers
MUSL_DEPENDENCIES = host-gcc-initial linux-headers

# musl does not provide an implementation for sys/queue.h or sys/cdefs.h.
# So, add the musl-compat-headers package that will install those files,
# into the staging directory:
#   sys/queue.h:  header from NetBSD
#   sys/cdefs.h:  minimalist header bundled in Buildroot
MUSL_DEPENDENCIES += musl-compat-headers

# musl is part of the toolchain so disable the toolchain dependency
MUSL_ADD_TOOLCHAIN_DEPENDENCY = NO

MUSL_INSTALL_STAGING = YES

# Thumb build is broken, build in ARM mode, since all architectures
# that support Thumb1 also support ARM.
ifeq ($(BR2_ARM_INSTRUCTIONS_THUMB),y)
MUSL_EXTRA_CFLAGS += -marm
endif

define MUSL_CONFIGURE_CMDS
	(cd $(@D); \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(filter-out -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64,$(TARGET_CFLAGS)) $(MUSL_EXTRA_CFLAGS)" \
		CPPFLAGS="$(filter-out -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64,$(TARGET_CPPFLAGS))" \
		./configure \
			--target=$(GNU_TARGET_NAME) \
			--host=$(GNU_TARGET_NAME) \
			--prefix=/usr \
			--libdir=/lib \
			--disable-gcc-wrapper \
			--enable-static \
			$(if $(BR2_STATIC_LIBS),--disable-shared,--enable-shared))
endef

define MUSL_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)
endef

define MUSL_INSTALL_STAGING_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
		DESTDIR=$(STAGING_DIR) install-libs install-tools install-headers
	ln -sf libc.so $(STAGING_DIR)/lib/ld-musl*
endef

define MUSL_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
		DESTDIR=$(TARGET_DIR) install-libs
	$(RM) $(addprefix $(TARGET_DIR)/lib/,crt1.o crtn.o crti.o rcrt1.o Scrt1.o)
	ln -sf libc.so $(TARGET_DIR)/lib/ld-musl*
endef

$(eval $(generic-package))
