#!/bin/bash
# ImmortalWrt 24.10：fileshare 不依赖 feeds/lang/node，在 fileshare 包内捆绑预编译 node
set -e
owrt="${HOME_PATH:-${GITHUB_WORKSPACE}/openwrt}"
fs_dir="${owrt}/feeds/fileshare/fileshare"
fs_mk="${fs_dir}/Makefile"
extract="${COMPILE_PATH:-${GITHUB_WORKSPACE}/operates/Immortalwrt}/extract-sbwml-node.sh"

[[ -f "$fs_mk" ]] || {
  echo "patch-fileshare: $fs_mk not found (feeds update/fileshare feed missing?)"
  exit 1
}
[[ -x "$extract" ]] || chmod +x "$extract"

python3 - "$fs_mk" "$extract" <<'PY'
import pathlib, re, sys

mf = pathlib.Path(sys.argv[1])
extract = sys.argv[2]
text = mf.read_text(encoding="utf-8", errors="replace")

text = re.sub(
    r"^\s*DEPENDS:=\+node \+node-npm\s*\n",
    "",
    text,
    count=1,
    flags=re.M,
)

build_prepare = """define Build/Prepare
\tmkdir -p $(PKG_BUILD_DIR)
\t$(CP) $(CURDIR)/files/* $(PKG_BUILD_DIR)/
\t$(CP) $(CURDIR)/server.js $(PKG_BUILD_DIR)/
\t$(CP) $(CURDIR)/package.json $(PKG_BUILD_DIR)/
\t$(CP) $(CURDIR)/public $(PKG_BUILD_DIR)/ -r
\t$(if $(wildcard $(CURDIR)/node_modules),$(CP) $(CURDIR)/node_modules $(PKG_BUILD_DIR)/ -r,$(error fileshare: run patch-fileshare npm install first))
endef"""

build_compile = f"""define Build/Compile
\t@mkdir -p $$(PKG_BUILD_DIR)/usr/bin
\tbash {extract} $$(PKG_BUILD_DIR) 22.22.3 $$(ARCH_PACKAGES)
\t-if [ -f $$(PKG_BUILD_DIR)/fileshare.init ]; then \\
\t\ttr -d '\\015' < $$(PKG_BUILD_DIR)/fileshare.init > $$(PKG_BUILD_DIR)/fileshare.init.tmp && \\
\t\tmv $$(PKG_BUILD_DIR)/fileshare.init.tmp $$(PKG_BUILD_DIR)/fileshare.init; \\
\tfi
\t-if [ -f $$(PKG_BUILD_DIR)/fileshare.config ]; then \\
\t\ttr -d '\\015' < $$(PKG_BUILD_DIR)/fileshare.config > $$(PKG_BUILD_DIR)/fileshare.config.tmp && \\
\t\tmv $$(PKG_BUILD_DIR)/fileshare.config.tmp $$(PKG_BUILD_DIR)/fileshare.config; \\
\tfi
\t-if [ -f $$(PKG_BUILD_DIR)/server.js ]; then \\
\t\ttr -d '\\015' < $$(PKG_BUILD_DIR)/server.js > $$(PKG_BUILD_DIR)/server.js.tmp && \\
\t\tmv $$(PKG_BUILD_DIR)/server.js.tmp $$(PKG_BUILD_DIR)/server.js; \\
\tfi
endef"""

install_block = """define Package/fileshare/install
\t$(INSTALL_DIR) $(1)/usr/lib/fileshare
\t$(INSTALL_DIR) $(1)/etc/init.d
\t$(INSTALL_DIR) $(1)/etc/config
\t$(INSTALL_DIR) $(1)/usr/lib/fileshare/public
\t$(INSTALL_DIR) $(1)/usr/lib/fileshare/uploads
\t$(INSTALL_DIR) $(1)/usr/bin

\t$(INSTALL_BIN) $(PKG_BUILD_DIR)/fileshare.init $(1)/etc/init.d/fileshare
\t$(INSTALL_CONF) $(PKG_BUILD_DIR)/fileshare.config $(1)/etc/config/fileshare
\t$(INSTALL_DATA) $(PKG_BUILD_DIR)/server.js $(1)/usr/lib/fileshare/
\t$(INSTALL_DATA) $(PKG_BUILD_DIR)/package.json $(1)/usr/lib/fileshare/
\t$(CP) $(PKG_BUILD_DIR)/public/. $(1)/usr/lib/fileshare/public/
\t$(CP) $(PKG_BUILD_DIR)/node_modules $(1)/usr/lib/fileshare/ -r
\t$(INSTALL_BIN) $(PKG_BUILD_DIR)/usr/bin/node $(1)/usr/bin/node
\t[ -f $(PKG_BUILD_DIR)/usr/bin/npm ] && $(INSTALL_BIN) $(PKG_BUILD_DIR)/usr/bin/npm $(1)/usr/bin/npm || true
\t[ -d $(PKG_BUILD_DIR)/usr/lib/node_modules/npm ] && \\
\t\t$(CP) $(PKG_BUILD_DIR)/usr/lib/node_modules/npm $(1)/usr/lib/node_modules/ -r || true
endef"""

text, np = re.subn(r"define Build/Prepare\n.*?^endef", build_prepare, text, count=1, flags=re.M | re.S)
text, n1 = re.subn(r"define Build/Compile\n.*?^endef", build_compile, text, count=1, flags=re.M | re.S)
text, n2 = re.subn(r"define Package/fileshare/install\n.*?^endef", install_block, text, count=1, flags=re.M | re.S)
if np != 1 or n1 != 1 or n2 != 1:
    raise SystemExit(f"patch-fileshare: Makefile patch failed (prepare={np}, build={n1}, install={n2})")

mf.write_text(text, encoding="utf-8", newline="\n")
print("patch-fileshare: fileshare no longer depends on feeds/lang/node; bundles sbwml node")
PY

# 在编译机（host）上安装 node_modules，避免 OpenWrt make 环境找不到 npm
if [[ -f "${fs_dir}/package.json" ]]; then
  export PATH="/usr/bin:/usr/local/bin:${PATH}"
  command -v npm >/dev/null || { echo "patch-fileshare: host npm not found"; exit 1; }
  rm -rf "${fs_dir}/node_modules"
  (cd "${fs_dir}" && npm install --production --no-save --prefix .)
  echo "patch-fileshare: host npm install OK ($(du -sh "${fs_dir}/node_modules" 2>/dev/null | cut -f1))"
fi

if [[ -f "${owrt}/.config" ]]; then
  sed -i '/^CONFIG_PACKAGE_node=y/d;/^CONFIG_PACKAGE_node-npm=y/d' "${owrt}/.config" 2>/dev/null || true
fi
if [[ -x "${owrt}/scripts/config" ]]; then
  (cd "${owrt}" && scripts/config --set PACKAGE_node=n PACKAGE_node-npm=n) 2>/dev/null || true
fi
rm -rf "${owrt}"/build_dir/target-*/node-* 2>/dev/null || true
