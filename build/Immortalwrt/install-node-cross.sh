#!/bin/bash
# sbwml 预编译 node：写入完整 Makefile（TAB 缩进），不依赖 host apk-tools
install_node_cross() {
  local owrt="${HOME_PATH:-${GITHUB_WORKSPACE}/openwrt}"
  local node_ver="22.22.3"
  local release_base="https://github.com/sbwml/node_workflow/releases/download/v${node_ver}"

  if [[ ! -d "$owrt" ]]; then
    echo "install-node-cross: openwrt dir not found: $owrt"
    return 1
  fi
  cd "$owrt" || return 1

  if [[ ! -d "./feeds/packages" ]]; then
    ./scripts/feeds update packages || {
      echo "install-node-cross: feeds update packages failed"
      return 1
    }
  fi
  mkdir -p "./feeds/packages/lang"

  local node_pkg_dir="./feeds/packages/lang/node"
  rm -rf "$node_pkg_dir"
  mkdir -p "$node_pkg_dir"

  # 完整 Makefile（recipe 行必须用 TAB）
  cat > "$node_pkg_dir/Makefile" <<MAKEFILE
include \$(TOPDIR)/rules.mk

PKG_NAME:=node
PKG_VERSION:=${node_ver}
PKG_RELEASE:=1

PKG_MAINTAINER:=sbwml prebuilt
PKG_LICENSE:=MIT
PKG_BUILD_DIR:=\$(BUILD_DIR)/\$(PKG_NAME)-\$(PKG_VERSION)

include \$(INCLUDE_DIR)/host-build.mk
include \$(INCLUDE_DIR)/package.mk

define Package/node
  SECTION:=lang
  CATEGORY:=Languages
  SUBMENU:=Node.js
  TITLE:=Node.js (sbwml prebuilt)
  URL:=https://nodejs.org/
  DEPENDS:=@USE_MUSL @HAS_FPU @(i386||x86_64||arm||aarch64) \\
	   +libstdcpp +libopenssl +zlib +libnghttp2 \\
	   +libcares +libatomic
endef

define Package/node-npm
  SECTION:=lang
  CATEGORY:=Languages
  SUBMENU:=Node.js
  TITLE:=Node.js npm (sbwml prebuilt)
  URL:=https://www.npmjs.com/
  DEPENDS:=+node
endef

ifeq (\$(HOST_ARCH),x86_64)
  NODE_HOST_ARCH:=x64
endif
ifeq (\$(HOST_ARCH),aarch64)
  NODE_HOST_ARCH:=arm64
endif

define Host/Compile
	( \\
		pushd \$(HOST_BUILD_DIR) ; \\
			\$(RM) node-v* ; \\
			wget -q https://nodejs.org/dist/v\$(PKG_VERSION)/node-v\$(PKG_VERSION)-linux-\$(NODE_HOST_ARCH).tar.xz ; \\
			\$(TAR) -xf node-v\$(PKG_VERSION)-linux-\$(NODE_HOST_ARCH).tar.xz ; \\
		popd ; \\
	)
endef

define Host/Install
	\$(CP) \$(HOST_BUILD_DIR)/node-v\$(PKG_VERSION)-linux-\$(NODE_HOST_ARCH)/* \$(STAGING_DIR_HOST)/
endef

define Build/Compile
	( \\
		pushd \$(PKG_BUILD_DIR) ; \\
			base="${release_base}" ; \\
			wget -q "\$\$base/\$(ARCH_PACKAGES).tar.gz" -O pkg.tar.gz || \\
			wget -q "\$\$base/x86_64.tar.gz" -O pkg.tar.gz ; \\
			\$(TAR) -zxf pkg.tar.gz ; \\
			for f in *.apk; do \\
				[ -f "\$\$f" ] || continue ; \\
				\$(TAR) -xf "\$\$f" ; \\
				\$(TAR) -xzf data.tar.gz ; \\
				rm -f data.tar.gz .PKGINFO "\$\$f" ; \\
			done ; \\
			\$(RM) pkg.tar.gz *.tar.gz ; \\
			test -f usr/bin/node ; \\
		popd ; \\
	)
endef

define Package/node/install
	\$(INSTALL_DIR) \$(1)/usr/bin
	\$(INSTALL_BIN) \$(PKG_BUILD_DIR)/usr/bin/node \$(1)/usr/bin/
endef

define Package/node-npm/install
	\$(INSTALL_DIR) \$(1)/usr/lib/node_modules/npm
	\$(CP) \$(PKG_BUILD_DIR)/usr/lib/node_modules/npm/{package.json,LICENSE} \\
		\$(1)/usr/lib/node_modules/npm/
	\$(CP) \$(PKG_BUILD_DIR)/usr/lib/node_modules/npm/README.md \\
		\$(1)/usr/lib/node_modules/npm/ 2>/dev/null || true
	\$(CP) \$(PKG_BUILD_DIR)/usr/lib/node_modules/npm/{node_modules,bin,lib} \\
		\$(1)/usr/lib/node_modules/npm/
	\$(INSTALL_DIR) \$(1)/usr/bin
	\$(LN) ../lib/node_modules/npm/bin/npm-cli.js \$(1)/usr/bin/npm
	\$(LN) ../lib/node_modules/npm/bin/npx-cli.js \$(1)/usr/bin/npx
endef

\$(eval \$(call HostBuild))
\$(eval \$(call BuildPackage,node))
\$(eval \$(call BuildPackage,node-npm))
MAKEFILE

  # 清缓存的失败产物（含 ccache 恢复的旧目录）
  rm -rf ./build_dir/target-*/node-* ./staging_dir/target-*/pkginfo/node.* 2>/dev/null || true

  if curl -fsSL -o /dev/null -I "${release_base}/x86_64.tar.gz"; then
    echo "install-node-cross: release x86_64.tar.gz OK (v${node_ver})"
  else
    echo "install-node-cross: warn: cannot HEAD ${release_base}/x86_64.tar.gz"
  fi

  echo "install-node-cross: wrote prebuilt Makefile at feeds/packages/lang/node"
  return 0
}

install_node_cross
