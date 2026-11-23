#!/bin/sh
# ===========================================================================
# Honk GeoData 规则集原子无缝热更新脚本
# 项目地址: https://github.com/wuziwei/honk-config-template
# ===========================================================================

set -e

DATA_DIR="/etc/honk/data"
TMP_DIR="/tmp/honk-geodata-update"
GEOSITE_URL="https://raw.githubusercontent.com/wuziwei/honk-config-template/main/honk-rule/geosite.dat"
GEOIP_URL="https://raw.githubusercontent.com/wuziwei/honk-config-template/main/honk-rule/geoip.dat"
GEOSITE_SHA="https://raw.githubusercontent.com/wuziwei/honk-config-template/main/honk-rule/geosite.dat.sha256sum"
GEOIP_SHA="https://raw.githubusercontent.com/wuziwei/honk-config-template/main/honk-rule/geoip.dat.sha256sum"
MIRROR_PREFIX="https://cdn.jsdelivr.net/gh/wuziwei/honk-config-template@main/honk-rule/"

mkdir -p "$TMP_DIR"
mkdir -p "$DATA_DIR"

download_with_fallback() {
    local file_name="$1"
    local raw_url="$2"
    local output="$3"
    if ! curl -fsSL --connect-timeout 8 "${MIRROR_PREFIX}${file_name}" -o "$output" 2>/dev/null; then
        curl -fsSL "$raw_url" -o "$output"
    fi
}

echo "[*] 正在下载最新 GeoData 规则集校验和..."
download_with_fallback "geosite.dat.sha256sum" "$GEOSITE_SHA" "$TMP_DIR/geosite.dat.sha256sum"
download_with_fallback "geoip.dat.sha256sum" "$GEOIP_SHA" "$TMP_DIR/geoip.dat.sha256sum"

echo "[*] 正在下载最新 geosite.dat..."
download_with_fallback "geosite.dat" "$GEOSITE_URL" "$TMP_DIR/geosite.dat"

echo "[*] 正在下载最新 geoip.dat..."
download_with_fallback "geoip.dat" "$GEOIP_URL" "$TMP_DIR/geoip.dat"

# 校验 SHA256 确保完整性
echo "[*] 正在校验 SHA256 哈希..."
EXPECTED_GEOSITE_SHA=$(awk '{print $1}' "$TMP_DIR/geosite.dat.sha256sum")
ACTUAL_GEOSITE_SHA=$(sha256sum "$TMP_DIR/geosite.dat" | awk '{print $1}')

if [ "$EXPECTED_GEOSITE_SHA" != "$ACTUAL_GEOSITE_SHA" ]; then
    echo "[错误] geosite.dat 哈希校验失败！取消替换。"
    rm -rf "$TMP_DIR"
    exit 1
fi

EXPECTED_GEOIP_SHA=$(awk '{print $1}' "$TMP_DIR/geoip.dat.sha256sum")
ACTUAL_GEOIP_SHA=$(sha256sum "$TMP_DIR/geoip.dat" | awk '{print $1}')

if [ "$EXPECTED_GEOIP_SHA" != "$ACTUAL_GEOIP_SHA" ]; then
    echo "[错误] geoip.dat 哈希校验失败！取消替换。"
    rm -rf "$TMP_DIR"
    exit 1
fi

# 原子替换
echo "[*] 校验通过，执行原子热替换..."
mv -f "$TMP_DIR/geosite.dat" "$DATA_DIR/geosite.dat"
mv -f "$TMP_DIR/geoip.dat" "$DATA_DIR/geoip.dat"
rm -rf "$TMP_DIR"

echo "[+] 规则集替换成功！正在通知 honk-core 重载..."
if command -v honk-core >/dev/null 2>&1; then
    honk-core reload 2>/dev/null || /etc/init.d/honk reload 2>/dev/null || true
elif [ -x /etc/init.d/honk ]; then
    /etc/init.d/honk reload 2>/dev/null || true
fi

echo "[✓] GeoData 规则集更新完成！"
