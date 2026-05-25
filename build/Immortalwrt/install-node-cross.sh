#!/bin/bash
# 为 OpenWrt 目标架构安装「已交叉编译」的 node（sbwml 预编译 apk，非 feeds 源码编译）
# x86_64 固件对应 node_workflow 的 x86_64.tar.gz；编译 fileshare 时 Host 侧用 linux-x64 跑 npm install
install_node_cross() {
  local owrt="${HOME_PATH:-${GITHUB_WORKSPACE}/openwrt}}"
  local node_ver="22.22.3"
  local node_repo="https://github.com/sbwml/feeds_packages_lang_node-prebuilt.git"
  local node_pkg_dir="$owrt/feeds/packages/lang/node"
  local release_base="https://github.com/sbwml/node_workflow/releases/download/v${node_ver}"

  [[ -d "$owrt/feeds/packages/lang" ]] || {
    echo "install-node-cross: missing feeds/packages/lang"
    return 1
  }

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

  # 固定版本，避免 Makefile 在解析阶段 curl GitHub API 失败
  sed -i "s|^PKG_VERSION:=.*|PKG_VERSION:=${node_ver}|" "$mf"

  # 预检交叉编译产物是否存在（x86_64 机型）
  if ! curl -fsSL -o /dev/null -r "${release_base}/x86_64.tar.gz"; then
    echo "install-node-cross: warn: cannot reach ${release_base}/x86_64.tar.gz"
  else
    echo "install-node-cross: release asset x86_64.tar.gz OK"
  fi

  echo "install-node-cross: sbwml prebuilt node ${node_ver} (target ARCH_PACKAGES at make time)"
  return 0
}

install_node_cross
