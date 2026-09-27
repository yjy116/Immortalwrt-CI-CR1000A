# CR1000A OpenWrt CI

为 Verizon CR1000A 编译 ImmortalWrt，源码使用 [yjy116/immortalwrt](https://github.com/yjy116/immortalwrt)，跟随 [VIKINGYFY/immortalwrt](https://github.com/VIKINGYFY/immortalwrt)。

## 配置来源

本轮核对基线：

| 用途 | 仓库与提交 |
| --- | --- |
| 编译模板 | [VIKINGYFY/OpenWRT-CI · 48bf00d](https://github.com/VIKINGYFY/OpenWRT-CI/tree/48bf00d0194c7d5164bed5bb41de398cfcaf5851) |
| 固件源码 | [VIKINGYFY/immortalwrt · 6979f3c](https://github.com/VIKINGYFY/immortalwrt/commit/6979f3c67ae803b0fe4fcb7fce0dd1edd3755695)，Linux 6.18.52 |
| 补充插件 | [Immortalwrt-CI-JDC-AX6600 · 7cedfb8](https://github.com/yjy116/Immortalwrt-CI-JDC-AX6600/tree/7cedfb8b79528d461075bdbd8ac0a7eff7e0be5e) |

- `Config/GENERAL.txt`：完整采用上游模板的通用配置。
- `Config/CR1000A-WIFI-YES.txt`、`Config/CR1000A-WIFI-NO.txt`：分别采用上游 IPQ807X 的有无线/无无线配置，只选 CR1000A，均显式启用上游 `cr1000a-support`。
- `Config/EXTRA.txt`：AX6600 已启用、模板未启用的通用插件及所需依赖。以后增减这些插件优先修改此文件。
- 配置合并顺序：设备配置、GENERAL、EXTRA、Settings 中的 PRIVATE 和手动 PACKAGE；私有配置与手动参数仍可覆盖普通插件选项。
- `Scripts/Packages.sh`、`Handles.sh`、`Settings.sh` 使用上游模板结构，补入插件源和必要的插件兼容处理；处理失败会明确报错。
- 默认主题与模板一致，使用 Aurora。保留本项目的设备名称、网络默认值、Auto-Build 原有调度、预热缓存和手动缓存清理。不恢复 `apt full-upgrade`。

## 硬件支持

LAN、WAN、无线和 NSS 使用上游设备树、驱动及初始化服务，不再注入本地 no-PHY 补丁、强制链路、LAN 转发表或 VLAN 初始化逻辑，也不再克隆 `yjy116/files`。

上游在 `e5c7d22` 新增 `cr1000a-support`，但本轮检查的设备默认包列表及 2026-09-27 Release 未选择该包，因此这里显式启用。其依赖自动带入 `cryptsetup`、`kmod-spi-dev`、`KERNEL_DEVMEM` 等，使用上游 procd 服务启动 RTL9303、Aquantia 和 eMMC 辅助程序。配置阶段会检查它是否真的启用。

WiFi-YES 的第三射频继续采用上游 QCN9074 固件路径和 CR1000A 板级数据。WiFi-NO 按上游配置禁用 ath11k AHB/PCIe 驱动及 IPQ8074/QCN9074 无线固件，并使用 `ipq8074-nowifi.dtsi` 调整 Q6 预留内存，不提供板载 WiFi。两种模式均保留原生 LAN/WAN 支持。编译成功不等于原生 6GHz、全部 LAN 口或实际吞吐已通过验证。

**从旧固件迁移时注意：** 先备份设置。若保留配置刷机，请检查 `/etc/rc.local`，移除旧的 `/lib/rtl/init.sh`、`/lib/aqr/init.sh`、`/lib/mmc/init.sh` 调用以及旧 `exec-dir`/switch 启动调用，保留其他自定义命令，避免与新服务重复启动。不要把旧版硬件 overlay 再恢复进新固件。这里不自动删除路由器上的用户配置。

## 插件补充

在模板的 HomeProxy、GecoosAC、Mini DiskManager、NATMapT、Samba、UPnP、WOLUltra 等基础上，增加：

- 代理：DAE、DAED、统一 `luci-app-daede`、Nikki、Passwall、OpenClash。
- 联网与服务：AdGuardHome、EasyTier、Tailscale、ZeroTier、WireGuard、SQM/NSS、DDNS-Go、Lucky、USB 打印、VLMCSD、SoftEther VPN。
- 工具：qBittorrent、TTYD、CPUFreq、Statistics、VnStat2、Btop、Tcpdump，以及参考仓库的通用存储/诊断工具。
- GeoData 更新器：保留参考项目的功能和每周更新时间，数据包仍使用上游 feed，不重复定义；下载及 SHA256 校验失败返回非零，不替换旧数据，不使用第三方下载代理。

HomeProxy/sing-box 按模板从 `VIKINGYFY/packages` 配套获取，不再保留旧的“官方 feed 专供”处理，不单独强升 sing-box。

DAE/DAED 使用参考项目的 `kenzok8/openwrt-daede@0b0e5d6`，包括后端切换互斥、旧订阅任务迁移和错误上报修复。使用内核 BTF，不额外携带大型 `vmlinux-btf`；准确源码信息随 Release 的 `DAEDE-SOURCE.txt` 发布。迁移保留旧数据库/配置和订阅计划；自动更新凭据需在新界面中核对。

不引入 AX6600 的 Athena LED、内存/设备配置及其他硬件补丁；不恢复 netspeedtest 源，也不启用 MosDNS、speedtestcpp 或旧 luci-app-speedtest。测速采用模板的命令行 iperf3，不保留旧的独立 luci-app-iperf3。

新增插件会增加固件大小和编译耗时。最终镜像大小、设备分区容量和实际可用空间仍需在构建及刷机前核对，不能用 eMMC 总容量代替固件分区容量。

## 构建和缓存

手动运行 Actions 中的 `CR1000A` 或 `CR1000A-test`，**一次触发同时启动 WiFi-YES 和 WiFi-NO 两个并行任务**，不需要分别选择或触发。两种模式共用 GENERAL/EXTRA 插件清单，分别生成独立 Release，标签以 `CR1000A-WIFI-YES-` / `CR1000A-WIFI-NO-` 开头，固件文件名包含 `wifi-yes` / `wifi-no`。某个任务失败不会自动取消另一个任务。

将 `TEST` 设为 true 时仍会启动两个任务，但只生成两种配置，不编译固件。原有 Auto-Build 调度保持不变。WiFi-NO 请通过有线网络管理；不要通过手动 PACKAGE 或 PRIVATE 配置重新启用无线驱动，否则会与无无线内存布局冲突。

正式和测试工作流共用兼容性缓存规则：源码仓库/分支、平台、构建工具/内核源码、GENERAL/EXTRA/设备配置和构建主机共同生成指纹。WiFi-YES 与 WiFi-NO 使用各自的兼容性指纹，不混用缓存；首次切换到新配置名称需要重新预热。相关变化自动使用新缓存，不匹配旧的宽泛缓存键。

没有兼容缓存时，先预热 `tools` 和 `toolchain`，成功后立即保存；完整编译成功后再保存完整缓存。仅缓存 `.ccache`、`staging_dir/host` 和交叉工具链，feeds 的 `hostpkg` 重新构建。继续使用 `actions/cache@v5`。

怀疑缓存污染、重要源码变更后反复失败，或希望完整重新预热时：

1. 打开 Actions，选择 `Cache-Clean`。
2. 点击 `Run workflow`。

这会清空本仓库 Actions cache，不删除 Release、固件、源码或运行记录。首次重建较慢；无需另设周期性缓存清理。

## 本地验证

需要 Bash、Python 3 和 Node.js。准备上述固定版本的源码、CI 模板及 AX6600 参考仓库：

```sh
export WRT_SOURCE_CHECK=/path/to/immortalwrt
export WRT_CI_TEMPLATE=/path/to/VIKINGYFY-OpenWRT-CI
export WRT_PLUGIN_REFERENCE=/path/to/AX6600-CI
python3 -m pip install -r Tests/requirements.txt
python3 -m unittest discover -s Tests -v
export GITHUB_WORKSPACE="$PWD"
bash Scripts/Daede.sh /tmp/cr1000a-daede-check
bash Tests/test_daede_migration.sh
bash Tests/test_daede_service_guard.sh /tmp/cr1000a-daede-check
node Tests/test_daede_switch.cjs /tmp/cr1000a-daede-check
bash Tests/test_mihomo_conflicts.sh
bash Tests/test_geodata_updater.sh
```

检查覆盖双模式并行矩阵、WiFi-NO 上游禁用项和 Q6 调整、两种缓存隔离、模板/插件差集、原生 LAN/WAN 文件不被改写、第三射频板级数据、无线表达式，以及 DAE/DAED 迁移和切换。服务测试只替代路由器专有 I/O，不代表实机运行；完整固件仍由 GitHub Actions 验证。
