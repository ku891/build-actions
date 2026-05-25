#!/bin/bash
# 用 sbwml 预编译 node 替换 feeds/packages/lang/node（勿用 packages-24.10 源码分支）
install_node_prebuilt() {
  local owrt="${HOME_PATH:-${GITHUB_WORKSPACE}/openwrt}}"
  [[ -d "$owrt/feeds/packages/lang" ]] || return 0
  rm -rf "$owrt/feeds/packages/lang/node"
  if ! git clone --depth=1 https://github.com/sbwml/feeds_packages_lang_node-prebuilt \
      "$owrt/feeds/packages/lang/node" 2>/dev/null; then
    echo "install-node-prebuilt: clone failed"
    return 1
  fi
  echo "install-node-prebuilt: using feeds_packages_lang_node-prebuilt"
}
install_node_prebuilt
