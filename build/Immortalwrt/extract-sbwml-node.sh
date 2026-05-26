#!/bin/bash
# 从 sbwml node_workflow release 解出 usr/（APK v3 格式，不能用 tar 直接解 .apk）
set -e
DEST="${1:?dest dir}"
VER="${2:-22.22.3}"
ARCH="${3:-x86_64}"
OWRT="${4:-${HOME_PATH:-}}"
BASE="https://github.com/sbwml/node_workflow/releases/download/v${VER}"
COMPILE_PATH="${COMPILE_PATH:-${GITHUB_WORKSPACE}/operates/Immortalwrt}"

WORKDIR="$(mktemp -d)"
ROOT="${WORKDIR}/root"
trap 'rm -rf "$WORKDIR"' EXIT
mkdir -p "$ROOT" "$DEST/usr"

if ! wget -q "${BASE}/${ARCH}.tar.gz" -O "${WORKDIR}/pkg.tar.gz"; then
  echo "extract-sbwml-node: wget ${ARCH}.tar.gz failed, try x86_64"
  wget -q "${BASE}/x86_64.tar.gz" -O "${WORKDIR}/pkg.tar.gz"
fi
tar -zxf "${WORKDIR}/pkg.tar.gz" -C "$WORKDIR"

apk_bin=""
for c in \
  "${OWRT}/staging_dir/host/bin/apk" \
  "${OWRT}/staging_dir/hostpkg/bin/apk" \
  "$(command -v apk 2>/dev/null || true)"; do
  if [[ -n "$c" && -x "$c" ]] && "$c" --help 2>/dev/null | grep -q extract; then
    apk_bin="$c"
    break
  fi
done

adumpk="${COMPILE_PATH}/adumpk.py"
if [[ ! -f "$adumpk" ]]; then
  wget -q -O "$adumpk" "https://raw.githubusercontent.com/7Ji/adumpk/master/adumpk.py" || true
fi

extract_one_apk() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  local hdr
  hdr="$(head -c 4 "$f" 2>/dev/null || true)"

  if [[ "$hdr" == "ADBd" ]]; then
    if [[ -n "$apk_bin" ]]; then
      echo "extract-sbwml-node: apk extract $f via $apk_bin"
      "$apk_bin" extract --allow-untrusted -o "$ROOT" "$f"
      return 0
    fi
    if [[ -f "$adumpk" ]]; then
      echo "extract-sbwml-node: adumpk $f"
      local t="${WORKDIR}/$(basename "$f" .apk).tar"
      python3 "$adumpk" "$f" --tar "$t"
      tar -xf "$t" -C "$ROOT"
      return 0
    fi
    echo "extract-sbwml-node: APK v3 but no apk/adumpk tool for $f"
    return 1
  fi

  # 旧式 tar 包（兼容）
  local sub="${WORKDIR}/sub"
  mkdir -p "$sub"
  tar -xf "$f" -C "$sub"
  if [[ -f "$sub/data.tar.gz" ]]; then
    tar -xzf "$sub/data.tar.gz" -C "$ROOT"
  elif [[ -d "$sub/usr" ]]; then
    cp -a "$sub/usr/." "$ROOT/usr/" 2>/dev/null || mkdir -p "$ROOT/usr" && cp -a "$sub/usr/." "$ROOT/usr/"
  fi
  rm -rf "$sub"
}

shopt -s nullglob
apks=( "$WORKDIR"/node-*.apk )
if [[ ${#apks[@]} -eq 0 ]]; then
  echo "extract-sbwml-node: no node-*.apk in archive"
  exit 1
fi
for f in "${apks[@]}"; do
  extract_one_apk "$f"
done

if [[ -d "$ROOT/usr" ]]; then
  cp -a "$ROOT/usr/." "$DEST/usr/"
  if [[ -x "$DEST/usr/bin/node" ]]; then
    echo "extract-sbwml-node: OK -> $DEST/usr/bin/node"
  else
    echo "extract-sbwml-node: usr/ copied but node binary missing"
    exit 1
  fi
else
  echo "extract-sbwml-node: no usr/ after extract"
  exit 1
fi
