#!/bin/bash
# 为 OpenWrt 目标架构安装「已交叉编译」的 node（sbwml 预编译 apk，非 feeds 源码编译）
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
  # 有些 OpenWrt/ImmortalWrt 构建环境不会生成 $(STAGING_DIR_HOST)/bin/apk
  # 直接用 tar 解包 .apk（本质为 tar 包，包含 data.tar.gz）
  sed -i 's|\\$(STAGING_DIR_HOST)/bin/apk extract --allow-untrusted \\*\\.apk|for a in *.apk; do tar -xf $$a; tar -xf data.tar.gz; rm -f data.tar.gz .PKGINFO; done|' "$mf" 2>/dev/null || true

  if curl -fsSL -o /dev/null -I "${release_base}/x86_64.tar.gz"; then
    echo "install-node-cross: release x86_64.tar.gz OK (v${node_ver})"
  else
    echo "install-node-cross: warn: cannot reach ${release_base}/x86_64.tar.gz"
  fi

  echo "install-node-cross: sbwml prebuilt node ${node_ver} at feeds/packages/lang/node"
  return 0
}

install_node_cross
