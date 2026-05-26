#!/bin/bash
# 为 OpenWrt 目标架构安装 sbwml 预编译 node（下载 release 的 tar.gz + 解 apk，非源码编译）
install_node_cross() {
  local owrt="${HOME_PATH:-${GITHUB_WORKSPACE}/openwrt}"
  local node_ver="22.22.3"
  local node_repo="https://github.com/sbwml/feeds_packages_lang_node-prebuilt.git"
  local release_base="https://github.com/sbwml/node_workflow/releases/download/v${node_ver}"

  if [[ ! -d "$owrt" ]]; then
    echo "install-node-cross: openwrt dir not found: $owrt"
    return 1
  fi
  cd "$owrt" || return 1

  if [[ ! -d "./feeds/packages" ]]; then
    echo "install-node-cross: updating packages feed..."
    ./scripts/feeds update packages || {
      echo "install-node-cross: feeds update packages failed"
      return 1
    }
  fi
  mkdir -p "./feeds/packages/lang"

  local node_pkg_dir="./feeds/packages/lang/node"
  rm -rf "$node_pkg_dir"
  if ! git clone --depth=1 "$node_repo" "$node_pkg_dir"; then
    echo "install-node-cross: git clone failed"
    return 1
  fi

  local mf="$node_pkg_dir/Makefile"
  if [[ ! -f "$mf" ]]; then
    echo "install-node-cross: Makefile not found"
    return 1
  fi

  sed -i "s|^PKG_VERSION:=.*|PKG_VERSION:=${node_ver}|" "$mf"

  # 用 Python 重写 Build/Compile / Host/Compile（避免 sed 匹配失败；不依赖 apk-tools）
  python3 - "$mf" "$node_ver" <<'PY'
import pathlib, re, sys

mf = pathlib.Path(sys.argv[1])
ver = sys.argv[2]
text = mf.read_text(encoding="utf-8", errors="replace")
text = re.sub(r"^PKG_VERSION:=.*$", f"PKG_VERSION:={ver}", text, count=1, flags=re.M)

build_compile = r"""define Build/Compile
	( \
		pushd $(PKG_BUILD_DIR) ; \
			base="https://github.com/sbwml/node_workflow/releases/download/v$(PKG_VERSION)" ; \
			wget -q "$$base/$(ARCH_PACKAGES).tar.gz" -O pkg.tar.gz || \
			wget -q "$$base/x86_64.tar.gz" -O pkg.tar.gz || \
			wget -q "$$base/aarch64_generic.tar.gz" -O pkg.tar.gz ; \
			$(TAR) -zxf pkg.tar.gz ; \
			for f in *.apk; do \
				[ -f "$$f" ] || continue ; \
				$(TAR) -xf "$$f" ; \
				$(TAR) -xzf data.tar.gz ; \
				rm -f data.tar.gz .PKGINFO "$$f" ; \
			done ; \
			$(RM) pkg.tar.gz *.tar.gz ; \
			test -f usr/bin/node ; \
		popd ; \
	)
endef"""

host_compile = r"""define Host/Compile
	( \
		pushd $(HOST_BUILD_DIR) ; \
			$(RM) node-v* ; \
			wget -q https://nodejs.org/dist/v$(PKG_VERSION)/node-v$(PKG_VERSION)-linux-$(NODE_HOST_ARCH).tar.xz ; \
			$(TAR) -xf node-v$(PKG_VERSION)-linux-$(NODE_HOST_ARCH).tar.xz ; \
		popd ; \
	)
endef"""

text, n1 = re.subn(r"define Build/Compile\n.*?^endef", build_compile, text, count=1, flags=re.M | re.S)
text, n2 = re.subn(r"define Host/Compile\n.*?^endef", host_compile, text, count=1, flags=re.M | re.S)
if n1 != 1 or n2 != 1:
    raise SystemExit(f"install-node-cross: Makefile patch failed (Build={n1}, Host={n2})")
mf.write_text(text, encoding="utf-8", newline="\n")
print(f"install-node-cross: patched Makefile (Build/Compile Host/Compile)")
PY
  if [[ $? -ne 0 ]]; then
    echo "install-node-cross: failed to patch Makefile"
    return 1
  fi

  # 清掉可能缓存的失败构建产物
  rm -rf ./build_dir/target-*/node-* ./staging_dir/target-*/pkginfo/node.* 2>/dev/null || true

  if curl -fsSL -o /dev/null -I "${release_base}/x86_64.tar.gz"; then
    echo "install-node-cross: release x86_64.tar.gz OK (v${node_ver})"
  else
    echo "install-node-cross: warn: HEAD ${release_base}/x86_64.tar.gz failed (build may still wget)"
  fi

  echo "install-node-cross: sbwml prebuilt node ${node_ver} at feeds/packages/lang/node"
  return 0
}

install_node_cross
