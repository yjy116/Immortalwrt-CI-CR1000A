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

# GitHub Actions Cache 清理说明

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
