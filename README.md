# OpenWRT-CI
云编译CR1000A OpenWRT固件
- 源码：
[VIKINGYFY/immortalwrt](https://github.com/VIKINGYFY/immortalwrt.git)
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

GitHub Actions 会自动删除超过 7 天未访问的 cache，但本项目的 OpenWrt 编译缓存体积较大，源码 hash 更新后可能留下多份 `full` / `warm` 构建缓存。缓存接近仓库上限时会出现频繁创建、淘汰、再创建的情况，反而拖慢后续编译。

仓库已提供 `.github/workflows/Cache-Clean.yml`，默认每 10 天运行一次安全清理：

- 只处理 key 以 `CR1000A-` 开头的构建 cache。
- 按创建时间清理旧 cache，默认只清理创建超过 10 天的条目。
- 每个构建缓存组默认保留最新 1 个，避免把当前可用缓存全部删光。
- 不再使用 `gh cache delete --all`，避免误删所有 cache。

手动清理方式：

1. 打开仓库 `Actions` 页面。
2. 选择 `Cache-Clean`。
3. 点击 `Run workflow`。
4. 建议第一次保持 `DRY_RUN=true`，只预览将要删除的 cache。
5. 确认列表无误后再次运行，将 `DRY_RUN` 改为 `false` 执行删除。

参数说明：

- `CACHE_PREFIX`：默认 `CR1000A-`，只清理匹配此前缀的 cache。
- `OLDER_THAN_DAYS`：默认 `10`，只删除创建时间早于该天数的 cache。
- `KEEP_LATEST`：默认 `1`，每组保留最新几个 cache。
- `DRY_RUN`：默认 `true`，手动执行时建议先预览。
