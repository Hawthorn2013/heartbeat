include $(TOPDIR)/rules.mk
PKG_NAME:=heartbeat
PKG_VERSION:=1.1.0
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
#PKG_SOURCE:=heartbeat-utils-$(PKG_VERSION).tar.gz
#PKG_SOURCE_URL:=@SF/heartbeat
#PKG_MD5SUM:=9b7dc52656f5cbec846a7ba3299f73bd
#PKG_CAT:=zcat

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Heartbeat send utility
  DEPENDS:=+mosquitto-client
endef

define Package/$(PKG_NAME)/description
  Send heartbeat to server.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./files/* $(PKG_BUILD_DIR)/
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/heartbeat
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/heartbeat $(1)/usr/sbin/heartbeat
	$(INSTALL_DIR)  $(1)/etc/init.d
	$(INSTALL_BIN)  $(PKG_BUILD_DIR)/heartbeat.init $(1)/etc/init.d/heartbeat
	$(INSTALL_DIR)  $(1)/etc/config
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/heartbeat.config $(1)/etc/config/heartbeat
	$(INSTALL_DIR)  $(1)/usr/lib/heartbeat
	$(INSTALL_BIN)  $(PKG_BUILD_DIR)/heartbeat_*.sh $(1)/usr/lib/heartbeat
endef
$(eval $(call BuildPackage,$(PKG_NAME)))
