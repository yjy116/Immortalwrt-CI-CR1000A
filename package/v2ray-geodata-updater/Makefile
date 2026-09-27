include $(TOPDIR)/rules.mk

PKG_NAME:=v2ray-geodata-updater
PKG_VERSION:=2026.09.27
PKG_RELEASE:=1
PKG_LICENSE:=GPL-3.0-only
PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/v2ray-geodata-updater
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=IP Addresses and Names
  TITLE:=Verified V2Ray geodata updater
  DEPENDS:=+curl +ca-bundle +coreutils-sha256sum +v2ray-geoip +v2ray-geosite
endef

define Build/Compile
endef

define Package/v2ray-geodata-updater/install
	$(INSTALL_DIR) $(1)/bin $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/v2ray-geodata-updater $(1)/bin/v2ray-geodata-updater
	$(INSTALL_BIN) ./files/90-v2ray-geodata-updater $(1)/etc/uci-defaults/90-v2ray-geodata-updater
endef

$(eval $(call BuildPackage,v2ray-geodata-updater))
