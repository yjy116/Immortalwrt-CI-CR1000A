#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

PKG_PATH="$GITHUB_WORKSPACE/wrt/package/"

#预置HomeProxy数据
if [ -d *"homeproxy"* ]; then
	echo " "

	HP_RULE="surge"
	HP_PATH="homeproxy/root/etc/homeproxy"

	rm -rf ./$HP_PATH/resources/*

	git clone -q --depth=1 --single-branch --branch "release" "https://github.com/Loyalsoldier/surge-rules.git" ./$HP_RULE/
	cd ./$HP_RULE/ && RES_VER=$(git log -1 --pretty=format:'%s' | grep -o "[0-9]*")

	echo $RES_VER | tee china_ip4.ver china_ip6.ver china_list.ver gfw_list.ver
	awk -F, '/^IP-CIDR,/{print $2 > "china_ip4.txt"} /^IP-CIDR6,/{print $2 > "china_ip6.txt"}' cncidr.txt
	sed 's/^\.//g' direct.txt > china_list.txt ; sed 's/^\.//g' gfw.txt > gfw_list.txt
	mv -f ./{china_*,gfw_list}.{ver,txt} ../$HP_PATH/resources/

	cd .. && rm -rf ./$HP_RULE/

	cd $PKG_PATH && echo "homeproxy date has been updated!"
fi

#修改argon主题字体和颜色
if [ -d *"luci-theme-argon"* ]; then
	echo " " && cd ./luci-theme-argon/

	sed -i "s/primary '.*'/primary '#31a1a1'/; s/'0.2'/'0.5'/; s/'none'/'bing'/; s/'600'/'normal'/" ./luci-app-argon-config/root/etc/config/argon

	cd $PKG_PATH && echo "theme-argon has been fixed!"
fi

#修改aurora菜单式样
if [ -d *"luci-app-aurora-config"* ]; then
	echo " " && cd ./luci-app-aurora-config/

	sed -i "s/nav_submenu_type '.*'/nav_submenu_type 'boxed-dropdown'/g" $(find ./root/usr/share/aurora/ -type f -name "*.template")

	cd $PKG_PATH && echo "theme-aurora has been fixed!"
fi

#修改mini-diskmanager菜单位置
if [ -d *"luci-app-mini-diskmanager"* ]; then
	echo " " && cd ./luci-app-mini-diskmanager/

	sed -i "s/services/system/g" ./luci-app-mini-diskmanager/root/usr/share/luci/menu.d/luci-app-mini-diskmanager.json

	cd $PKG_PATH && echo "mini-diskmanager has been fixed!"
fi

# Fix luci-app-iperf3 include path when imported as a standalone package
IPERF3_FILE="./luci-app-iperf3/Makefile"
if [ -f "$IPERF3_FILE" ]; then
	echo " "

	sed -i 's#include ../../luci.mk#include $(TOPDIR)/feeds/luci/luci.mk#g' "$IPERF3_FILE"

	cd $PKG_PATH && echo "luci-app-iperf3 has been fixed!"
fi

# Fix CR1000A LAN probe: RTL9303 is initialized by userspace over SPI, so dp5
# must not block on an unreadable MDIO PHY during kernel nss-dp probing.
CR1000A_DTS="../target/linux/qualcommax/dts/ipq8072-cr1000a.dts"
if [ -f "$CR1000A_DTS" ]; then
	echo " "

	perl -0pi -e '
		my $replacement = qq{&dp5_syn {\n\tstatus = "okay";\n\tphy-mode = "usxgmii";\n\tqcom,no-phy;\n\tlabel = "lan";\n};};
		s/&dp5_syn\s*\{.*?\n\};/$replacement/s
			or die "failed to patch CR1000A dp5 no-phy link\n";
	' "$CR1000A_DTS"

	grep -q "qcom,no-phy" "$CR1000A_DTS"

	cd $PKG_PATH && echo "cr1000a lan dts has been fixed!"
fi

NSS_DP_PATCH_DIR="./kernel/qca-nss-dp/patches"
if [ -d "$NSS_DP_PATCH_DIR" ]; then
	echo " "

	cp -f "$GITHUB_WORKSPACE/Patches/qca-nss-dp/08-cr1000a-no-phy-link.patch" \
		"$NSS_DP_PATCH_DIR/08-cr1000a-no-phy-link.patch"
	grep -q "qcom,no-phy" "$NSS_DP_PATCH_DIR/08-cr1000a-no-phy-link.patch"

	cd $PKG_PATH && echo "qca-nss-dp cr1000a no-phy link patch has been added!"
fi

HOSTAPD_UC="./network/config/wifi-scripts/files-ucode/usr/share/ucode/wifi/hostapd.uc"
if [ -f "$HOSTAPD_UC" ]; then
	echo " "

	sed -i '/let band = wiphy_band(phy, config.band);/a\
\
	if (!band)\
		die(`${config.phy}: configured band ${config.band} is not exposed by nl80211; check CR1000A BDF/firmware and wireless band setting`);' "$HOSTAPD_UC"
	grep -q "configured band" "$HOSTAPD_UC"

	cd $PKG_PATH && echo "hostapd band diagnostics have been added!"
fi

# Fix qca-nss-drv start order
NSS_DRV="../feeds/nss_packages/qca-nss-drv/files/qca-nss-drv.init"
if [ -f "$NSS_DRV" ]; then
	echo " "

	sed -i 's/START=.*/START=85/g' $NSS_DRV

	cd $PKG_PATH && echo "qca-nss-drv has been fixed!"
fi

#修改qca-nss-pbuf启动顺序
NSS_PBUF="./kernel/mac80211/files/qca-nss-pbuf.init"
if [ -f "$NSS_PBUF" ]; then
	echo " "

	sed -i 's/START=.*/START=86/g' $NSS_PBUF

	cd $PKG_PATH && echo "qca-nss-pbuf has been fixed!"
fi

#修复TailScale配置文件冲突
TS_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
if [ -f "$TS_FILE" ]; then
	echo " "

	sed -i '/\/files/d' $TS_FILE

	cd $PKG_PATH && echo "tailscale has been fixed!"
fi

#修复Rust编译失败
RUST_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile")
if [ -f "$RUST_FILE" ]; then
	echo " "

	sed -i 's/ci-llvm=true/ci-llvm=false/g' $RUST_FILE

	cd $PKG_PATH && echo "rust has been fixed!"
fi
