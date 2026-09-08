# OpenWRT-CI
云编译CR1000A OpenWRT固件
- 源码：
[yjy116/immortalwrt](https://github.com/yjy116/immortalwrt.git)
[tsg2k2/openwrt](https://github.com/tsg2k2/openwrt)

# 硬件配置：

- CPU: IPQ8072A
- RAM: 2GB
- EMMC: 4GB
- 10G-WAN: AQC113C（USXGMII/dp6_syn)
- Switch Chip: RTL9303(USXGMII/dp5_syn)
- 10G-LAN: AQC113C(port8)
- 2.5G-LAN: RTL8221B*2（port20/port24）
- 2.5G-MOCA: MXL3711(port25)
- Radio 1: QCN5054
- Radio 2: QCN5024 (4x4 5G 4800Mbps)
- Radio 3: QCN9024 (4x4 6G 4800Mbps)

# 固件简要说明：

- 这货的固件太少了，原版的OP用不习惯，把A佬的固件搬到了imm上，请V佬纳入支持，有时间就捣鼓几下，目前是勉强能用
- 10g WAN口识别正常,我只有2.5g,具体速率能跑到多少，我不知道
- 三频无线正常，国家选择US，能有30dB
- NSS 硬件加速正常
- 带HP、Mosdns等简单几个软件自己够用了，具体的自己看config，想自己加就改这里

# 固件问题：

- 9024用的默认驱动，降频5.2g或者5.8G使用，如果想使用6E自己换一下驱动
- 10gLAN和2.5glan都能用,这三个lan口是通过/lib/rtl/usrApp进行控制，rtl的命令自己找
- 首次开机rtl9303会记住每个lan口的mac，如果mac发生变化，需要通过/lib/rtl/usrApp进行重新绑定
- data分区通过解密，挂载以后可以使用
- 上述增加的RTL控制APP和data分区的脚本在files文件夹，内容自己看

# 目录简要说明：

workflows——自定义CI配置

Scripts——自定义脚本

Config——自定义配置

# 2026-09 上游适配

源码继续使用 `yjy116/immortalwrt` 的 `main` 分支。本轮核对的上游基线为
[VIKINGYFY/immortalwrt 90448ee](https://github.com/VIKINGYFY/immortalwrt/commit/90448eeb2b8f5d172caedfe6d96ab3bacb058c09)，内核为 6.18.44。

- 使用上游新增的 CR1000A 专用 QCN9074 板级文件、无线固件和 board-id 修复；QCN9024 第三射频使用 QCN9074 驱动路径。
- 纳入上游 NSS/EDMA 启动、DMA、NAPI/GRO 和 NSS 频率设置更新。
- 保留 `Patches/qca-nss-dp/08-cr1000a-no-phy-link.patch`、LAN 强制链路设置及 `yjy116/files` 中的 RTL9303/AQR 初始化脚本。
- 无线配置仅定制 SSID 和密码，保留上游国家码、加密表达式；实际国家码仍应按使用地区设置。
- HomeProxy 与 sing-box 继续使用官方 feed 配套版本，现有插件选择和定时编译逻辑保持不变。

补丁和配置检查不能替代刷机测试。本轮更新后的所有 LAN 口、第三射频及原生 6GHz 仍需实机验证。

# GitHub Actions Cache 清理说明

`CR1000A` 和 `CR1000A-TEST` 使用同一套缓存规则：按源码仓库、分支、平台、构建工具/内核源码、编译配置和构建主机生成兼容性指纹。
这些内容变化时会自动使用新缓存，不再匹配旧的宽泛缓存键；无需因为普通升级先手动清空全部缓存。

没有兼容缓存时，会在编译固件前预热 `tools` 和 `toolchain`，预热成功立即保存，完整编译成功后再保存完整缓存。
缓存仅包含 `.ccache`、`staging_dir/host` 和交叉工具链；跟随 feeds 变化的 `hostpkg` 重新构建。
本轮首次编译会重新预热，之后兼容的编译可恢复缓存。保留 `actions/cache@v5` 和手动一键清理，不增加自动缓存删除任务。

GitHub Actions 会自动删除超过 7 天未访问的 cache。平时不需要定期清理，缓存能加速工具链和 host 目录恢复。

遇到下面情况时，可以手动一键清空 cache：

- 上游源码、内核、NSS、工具链或重要包源有较大变更。
- 编译反复失败，怀疑旧 `staging_dir`、`toolchain`、`.ccache` 污染。
- 修改了缓存路径、缓存 key 或预热逻辑。
- 想让下一次编译从干净状态重新预热。

清理方式：

1. 打开仓库 `Actions` 页面。
2. 选择 `Cache-Clean`。
3. 点击 `Run workflow`。

这个 workflow 会清空本仓库的全部 GitHub Actions cache，不会删除 Release、固件文件、源码文件或 workflow 运行记录。清理后第一次编译会变慢，因为需要重新预热和保存缓存；后续再次编译会恢复加速。

# 本地适配检查

在 Bash 和 Python 3 环境中，指定已检出的上游源码目录运行：

```sh
WRT_SOURCE_CHECK=/path/to/immortalwrt python3 Tests/test_compatibility.py -v
```

检查真实设备树变换、第三射频板级数据、无线设置表达式及缓存兼容性；固件编译仍由 GitHub Actions 验证。
