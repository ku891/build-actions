#!/bin/bash
# 用预编译 node 替换 feeds/packages/lang/node，避免云编译从源码编 node 失败（fileshare 依赖）
install_node_prebuilt() {
  local owrt="${HOME_PATH:-${GITHUB_WORKSPACE}/openwrt}}"
  [[ -d "$owrt/feeds/packages/lang" ]] || return 0
  rm -rf "$owrt/feeds/packages/lang/node"
  if git clone --depth=1 -b packages-24.10 https://github.com/sbwml/feeds_packages_lang_node \
      "$owrt/feeds/packages/lang/node" 2>/dev/null; then
    return 0
  fi
  git clone --depth=1 https://github.com/sbwml/feeds_packages_lang_node-prebuilt \
    "$owrt/feeds/packages/lang/node" 2>/dev/null || true
}
install_node_prebuilt
