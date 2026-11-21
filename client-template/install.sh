#!/bin/sh
# ===========================================================================
# Honk OpenWrt 客户端一键安装与初始化脚本
# 项目地址: https://github.com/wuziwei/honk-config-template
# ===========================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== 开始安装与配置 Honk (OpenWrt Client) ===${NC}"

# 1. 检查内核 BTF 支持
if [ ! -f /sys/kernel/btf/vmlinux ]; then
    echo -e "${YELLOW}[警告] /sys/kernel/btf/vmlinux 不存在！当前固件内核可能未启用 CONFIG_DEBUG_INFO_BTF，eBPF CO-RE 模式可能需要额外的 BTF 补齐。${NC}"
else
    echo -e "${GREEN}[✓] 检测到内核 BTF 支持正常 (/sys/kernel/btf/vmlinux)${NC}"
fi

# 2. 创建目录结构
echo -e "${BLUE}[+] 创建 /etc/honk 与数据目录...${NC}"
mkdir -p /etc/honk/data
mkdir -p /var/log

# 3. 安装或备份配置文件
if [ -f /etc/honk/config.dae ]; then
    echo -e "${YELLOW}[!] 检测到已存在 /etc/honk/config.dae，正在备份至 /etc/honk/config.dae.bak...${NC}"
    cp -f /etc/honk/config.dae /etc/honk/config.dae.bak
fi

# 如果当前目录下存在 config.dae 则复制
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/config.dae" ]; then
    echo -e "${BLUE}[+] 部署客户端配置模板至 /etc/honk/config.dae...${NC}"
    cp -f "$SCRIPT_DIR/config.dae" /etc/honk/config.dae
fi

# 4. 下载或更新最新 GeoData 规则集
echo -e "${BLUE}[+] 下载精简优化的 geosite.dat 与 geoip.dat...${NC}"
GEOSITE_URL="https://raw.githubusercontent.com/wuziwei/honk-config-template/main/honk-rule/geosite.dat"
GEOIP_URL="https://raw.githubusercontent.com/wuziwei/honk-config-template/main/honk-rule/geoip.dat"
MIRROR_PREFIX="https://ghfast.top/"

# 优先尝试直连，失败回退到加速镜像
if ! curl -fsSL --connect-timeout 5 "$GEOSITE_URL" -o /etc/honk/data/geosite.dat 2>/dev/null; then
    echo -e "${YELLOW}[!] GitHub 直连超时，尝试使用加速镜像下载 geosite.dat...${NC}"
    curl -fsSL "$MIRROR_PREFIX$GEOSITE_URL" -o /etc/honk/data/geosite.dat
fi

if ! curl -fsSL --connect-timeout 5 "$GEOIP_URL" -o /etc/honk/data/geoip.dat 2>/dev/null; then
    echo -e "${YELLOW}[!] GitHub 直连超时，尝试使用加速镜像下载 geoip.dat...${NC}"
    curl -fsSL "$MIRROR_PREFIX$GEOIP_URL" -o /etc/honk/data/geoip.dat
fi

echo -e "${GREEN}[✓] 规则集部署完成 ($(ls -lh /etc/honk/data/geosite.dat | awk '{print $5}'), $(ls -lh /etc/honk/data/geoip.dat | awk '{print $5}'))${NC}"

# 5. 部署更新脚本到 /usr/bin/honk-update-geodata
if [ -f "$SCRIPT_DIR/update-geodata.sh" ]; then
    cp -f "$SCRIPT_DIR/update-geodata.sh" /usr/bin/honk-update-geodata
    chmod +x /usr/bin/honk-update-geodata
    echo -e "${GREEN}[✓] 已安装规则更新命令: /usr/bin/honk-update-geodata${NC}"
fi

echo -e "\n${GREEN}=== 安装部署就绪 ===${NC}"
echo -e "${YELLOW}请使用编辑器修改 /etc/honk/config.dae，填入您的真实节点信息后执行:${NC}"
echo -e "  /etc/init.d/honk restart"
echo -e "或使用 sb-bonk 工具管理:\n  sb-bonk status\n"
