#!/bin/bash

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

	# HomeProxy relies on its uci-defaults script to register fw4 nftables includes.
	# On sysupgrade with preserved settings, package uci-defaults scripts may not rerun,
	# which leaves HomeProxy installed but without the firewall include sections.
	HP_DEFAULTS="./base-files/files/etc/uci-defaults/99_homeproxy_fw4_${WRT_DATE:-custom}"
	mkdir -p "$(dirname "$HP_DEFAULTS")"
	cat > "$HP_DEFAULTS" <<'EOF'
#!/bin/sh

[ -f "/www/luci-static/resources/icons/loading.gif" ] && \
	sed -i "s,/loading.svg,/loading.gif,g" "/www/luci-static/resources/view/homeproxy/status.js"

uci -q batch <<EOT >"/dev/null"
delete firewall.homeproxy_forward
set firewall.homeproxy_forward=include
set firewall.homeproxy_forward.type='nftables'
set firewall.homeproxy_forward.path='/var/run/homeproxy/fw4_forward.nft'
set firewall.homeproxy_forward.position='chain-pre'
set firewall.homeproxy_forward.chain='forward'
delete firewall.homeproxy_input
set firewall.homeproxy_input=include
set firewall.homeproxy_input.type='nftables'
set firewall.homeproxy_input.path='/var/run/homeproxy/fw4_input.nft'
set firewall.homeproxy_input.position='chain-pre'
set firewall.homeproxy_input.chain='input'
delete firewall.homeproxy_post
set firewall.homeproxy_post=include
set firewall.homeproxy_post.type='nftables'
set firewall.homeproxy_post.path='/var/run/homeproxy/fw4_post.nft'
set firewall.homeproxy_post.position='table-post'
commit firewall
EOT

exit 0
EOF
	chmod 0755 "$HP_DEFAULTS"

	cd $PKG_PATH && echo "homeproxy date has been updated!"
fi

#修改argon主题字体和颜色
if [ -d *"luci-theme-argon"* ]; then
	echo " "

	cd ./luci-theme-argon/

	sed -i "s/primary '.*'/primary '#31a1a1'/; s/'0.2'/'0.5'/; s/'none'/'bing'/; s/'600'/'normal'/" ./luci-app-argon-config/root/etc/config/argon

	cd $PKG_PATH && echo "theme-argon has been fixed!"
fi

#修改qca-nss-drv启动顺序
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

#修复DiskMan编译失败
DM_FILE="./luci-app-diskman/applications/luci-app-diskman/Makefile"
if [ -f "$DM_FILE" ]; then
	echo " "

	sed -i -E 's/fs-ntfs([^[:alnum:]_-]|$)/fs-ntfs3\1/g' "$DM_FILE"
	sed -i '/ntfs-3g-utils /d' "$DM_FILE"

	cd $PKG_PATH && echo "diskman has been fixed!"
fi

#移除sb内核回溯移植补丁
SB_PATCH="../feeds/packages/net/sing-box/patches"
if [ -d "$SB_PATCH" ]; then
	echo " "

	rm -rf $SB_PATCH

	cd $PKG_PATH && echo "sing-box patches has been fixed!"
fi
