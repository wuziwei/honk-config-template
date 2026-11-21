# Honk 客户端配置模板与规则集 (Honk Config Template)

本项目为 OpenWrt / Linux 环境下的 `honk`（基于 eBPF 的高性能透明代理内核）提供开箱即用的生产级客户端配置模板、脱敏范例、全套自定义 GeoData 规则集及自动化同步工作流。

---

## 🌟 核心特性

- **eBPF 内核级分流**：采用 TC / Netfilter Hook，零拷贝无损转发，极大降低软路由 CPU 负载。
- **硬件卸载协同**：天然适配 Airoha PPE、MediaTek WED 等硬件加速，内网与直连流量线速转发。
- **BT / P2P 零污染直通**：内置精准双向直通规则，彻底剥离 BT 分类，防封号、防连接池膨胀。
- **智能 DNS 调度**：国内阿里 DoH 直连与海外安全 DoH 分流，结合二次嗅探机制避免 CDN 调度偏差。
- **敏感信息完全脱敏**：无任何私人节点、密钥与私有域名，提供清晰的协议配置示例。
- **全自动 GeoData 构建**：集成 GitHub Actions 每日自动构建最新 `geosite.dat` 与 `geoip.dat`。

---

## 📂 仓库目录结构

```text
├── client-template/
│   ├── config.dae            # OpenWrt 客户端脱敏配置模板
│   ├── install.sh            # 一键安装与环境部署脚本
│   └── update-geodata.sh     # 规则集原子热更新脚本
├── honk-rule/
│   ├── build_geodata.py      # 纯 Python 标准库 GeoData 规则构建器
│   ├── custom/               # 自定义分流规则定义 (JSON)
│   ├── geoip.dat             # 编译生成的精简高效 GeoIP 规则包
│   ├── geosite.dat           # 编译生成的精简高效 GeoSite 规则包
│   └── README.md             # 规则集 Tag 清单与构建说明
├── rules/                    # 基础分流规则集 (Google, Meta, FakeIP)
├── .github/workflows/
│   └── sync-honk-geodata.yml # GitHub Actions 每日自动同步 CI
└── README.md
```

---

## 🚀 快速开始 (OpenWrt)

### 1. 部署规则集与配置文件
登录 OpenWrt 终端，执行以下命令快速拉取并部署：

```sh
# 创建所需目录
mkdir -p /etc/honk/data

# 下载最新客户端配置模板
curl -fsSL https://raw.githubusercontent.com/wuziwei/honk-config-template/main/client-template/config.dae -o /etc/honk/config.dae

# 下载预编译规则集
curl -fsSL https://raw.githubusercontent.com/wuziwei/honk-config-template/main/honk-rule/geosite.dat -o /etc/honk/data/geosite.dat
curl -fsSL https://raw.githubusercontent.com/wuziwei/honk-config-template/main/honk-rule/geoip.dat -o /etc/honk/data/geoip.dat
```

*(国内无代理环境可在 GitHub 链接前添加加速前缀 `https://ghfast.top/`)*

### 2. 配置节点信息
使用文本编辑器修改 `/etc/honk/config.dae` 中的 `node` 段落，填入您的真实节点信息：

```dae
node {
    'HK-Node-01': 'hysteria2://<PASSWORD>@<SERVER_IP>:2053?sni=<SNI>&obfs=salamander&obfs-password=<OBFS_PWD>'
    'JP-Node-01': 'vless://<UUID>@<SERVER_IP>:443?encryption=none&security=reality&sni=www.apple.com&fp=chrome&pbk=<PUB_KEY>&sid=<SID>&type=tcp'
}
```

### 3. 启动与管理服务
```sh
# 语法检查与启动
/etc/init.d/honk start

# 查看运行状态
/etc/init.d/honk status
```

---

## 🔄 规则集日常维护

本项目通过 GitHub Actions 每日自动同步上游更新，并执行以下优化逻辑：
1. 自动过滤所有 `TRACKERSLIST`、`BITTORRENT` 分类，保护软路由资源与节点合规；
2. 消除重复分类标签，杜绝运行日志中的 `duplicate code` 告警；
3. 合并自定义 Google、Meta、BlockHttpDNS、WebRTC-STUN 等加固规则。

如需在路由器上自动更新规则，可将 `client-template/update-geodata.sh` 写入定时任务：
```sh
# 每周日凌晨 4 点自动更新并重载规则
0 4 * * 0 /bin/sh /usr/bin/honk-update-geodata >/dev/null 2>&1
```

---

## 📄 开源许可证

本项目遵循 [MIT License](LICENSE) 协议。
