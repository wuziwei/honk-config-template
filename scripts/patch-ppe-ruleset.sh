#!/bin/sh
# ==============================================================================
# patch-ppe-ruleset.sh: 修复 Airoha AN7581 硬件加速在 PPPoE IPv6 校验和缺陷
# 项目地址: https://github.com/wuziwei/honk-config-template
# 
# 原理分析 (第一性原理):
#   Airoha AN7581 硬件 PPE 芯片在处理 PPPoE 封装的 IPv6 数据包时存在硬件校验和计算缺陷，
#   会导致 IPv6 TCP/UDP 报文通过 PPE 卸载时被对端协议栈判定校验和错误而直接丢弃（表现为 IPv6 断流）。
#   本补丁通过在 firewall4 的 ruleset.uc 模板中将 offload_ft 流表限制为仅针对 IPv4:
#       meta nfproto ipv4 jump offload_ft
#   由此实现:
#     - IPv4 100% 走芯片级硬件 PPE 加速 (千兆/2.5G 满血，0% CPU 占用)
#     - IPv6 走 Linux 内核软转发 (避开硬件缺陷，多核软中断负载极低，网络稳如磐石)
# ==============================================================================

set -e

RULESET_UC="/usr/share/firewall4/templates/ruleset.uc"

if [ ! -f "$RULESET_UC" ]; then
    echo "[!] 未检测到 $RULESET_UC，当前系统可能未采用 firewall4 (nftables)。"
    exit 1
fi

if grep -q "meta nfproto ipv4 jump offload_ft" "$RULESET_UC"; then
    echo "[✓] 补丁已存在，无需重复修改。"
    exit 0
fi

if grep -q "jump offload_ft" "$RULESET_UC"; then
    echo "[+] 正在应用 Airoha AN7581 硬件加速 IPv4 专属补丁..."
    cp -f "$RULESET_UC" "${RULESET_UC}.bak"
    sed -i 's/jump offload_ft/meta nfproto ipv4 jump offload_ft/g' "$RULESET_UC"
    /etc/init.d/firewall restart
    echo "[✓] 补丁应用成功！防火墙规则已重载。"
else
    echo "[!] 未能在 $RULESET_UC 中找到 'jump offload_ft' 锚点，请检查 firewall4 版本。"
    exit 1
fi
