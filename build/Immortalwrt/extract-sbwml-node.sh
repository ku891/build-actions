#!/bin/bash
# 从 sbwml node_workflow release 解出 usr/ 到目标目录（供 fileshare 等使用，不依赖 feeds/lang/node）
set -e
DEST="${1:?dest dir}"
VER="${2:-22.22.3}"
ARCH="${3:-x86_64}"
BASE="https://github.com/sbwml/node_workflow/releases/download/v${VER}"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
cd "$WORKDIR"

if ! wget -q "${BASE}/${ARCH}.tar.gz" -O pkg.tar.gz; then
  echo "extract-sbwml-node: wget ${ARCH}.tar.gz failed, try x86_64"
  wget -q "${BASE}/x86_64.tar.gz" -O pkg.tar.gz
fi

tar -zxf pkg.tar.gz
for apk in node-*.apk; do
  [[ -f "$apk" ]] || continue
  tar -xf "$apk"
  [[ -f data.tar.gz ]] && tar -xzf data.tar.gz
  rm -f data.tar.gz .PKGINFO "$apk"
done

mkdir -p "$DEST"
if [[ -d usr ]]; then
  cp -a usr/. "$DEST/usr/"
  echo "extract-sbwml-node: installed to $DEST/usr (node $(test -x "$DEST/usr/bin/node" && echo OK || echo MISSING))"
else
  echo "extract-sbwml-node: no usr/ in archive"
  exit 1
fi
