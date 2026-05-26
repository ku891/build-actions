#!/bin/bash
# 24.10：优先给 fileshare 捆绑 node；不再维护 feeds/packages/lang/node（易与缓存/feeds 冲突）
set -e
COMPILE_PATH="${COMPILE_PATH:-${GITHUB_WORKSPACE}/operates/Immortalwrt}"
export HOME_PATH="${HOME_PATH:-${GITHUB_WORKSPACE}/openwrt}"
export COMPILE_PATH

if [[ -f "${COMPILE_PATH}/patch-fileshare-for-immortalwrt.sh" ]]; then
  bash "${COMPILE_PATH}/patch-fileshare-for-immortalwrt.sh"
  echo "install-node-cross: done (fileshare bundled node for ImmortalWrt 24.10)"
  exit 0
fi

echo "install-node-cross: patch-fileshare-for-immortalwrt.sh missing"
exit 1
