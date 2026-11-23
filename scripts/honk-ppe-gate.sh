#!/bin/sh
# ==============================================================================
# honk-ppe-gate.sh: 动态协调 Honk (eBPF) 与硬件加速 (Airoha PPE / MTK WED / SFE)
# 项目地址: https://github.com/wuziwei/honk-config-template
# 部署路径: /usr/libexec/honk-ppe-gate.sh
# ==============================================================================

ACTION="$1"

enable_gate() {
    # 启用硬件流分流加速并重载防火墙
    uci set firewall.@defaults[0].flow_offloading='1' 2>/dev/null
    uci set firewall.@defaults[0].flow_offloading_hw='1' 2>/dev/null
    uci commit firewall 2>/dev/null
    /etc/init.d/firewall reload 2>/dev/null || true

    # 调优 PPE 硬件学习速率，提高连接绑定激进度
    if [ -w /sys/kernel/debug/ppe/bind_rate ]; then
        echo "30 30" > /sys/kernel/debug/ppe/bind_rate 2>/dev/null
    fi
}

disable_gate() {
    # 恢复防火墙配置
    uci set firewall.@defaults[0].flow_offloading='1' 2>/dev/null
    uci set firewall.@defaults[0].flow_offloading_hw='1' 2>/dev/null
    uci commit firewall 2>/dev/null
    /etc/init.d/firewall reload 2>/dev/null || true

    if [ -w /sys/kernel/debug/ppe/bind_rate ]; then
        echo "30 30" > /sys/kernel/debug/ppe/bind_rate 2>/dev/null
    fi
}

case "$ACTION" in
    enable)
        enable_gate
        ;;
    disable)
        disable_gate
        ;;
    *)
        echo "Usage: $0 {enable|disable}"
        exit 1
        ;;
esac
