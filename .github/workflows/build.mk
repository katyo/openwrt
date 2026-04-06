TARGET ?=

TARGETS := ac2100 ax3000t

ifeq ($(findstring $(TARGET),$(TARGETS)),)
$(error Unknown target '$(TARGET)'. Expected one of $(TARGETS))
endif

define FEEDS
src-git;zapret;https://github.com/remittor/zapret-openwrt
src-git;easytier;https://github.com/katyo/luci-app-easytier
src-git;xray;https://github.com/yichya/luci-app-xray
endef

define TARGETS
MULTI_PROFILE=y
PER_DEVICE_ROOTFS=y
endef

define TARGETS.ax3000t
mediatek=y
mediatek_filogic=y
endef

define DEVICES.ax3000t
mediatek_filogic:xiaomi_mi-router-ax3000t=y
mediatek_filogic:xiaomi_mi-router-ax3000t-ubootmod=y
endef

define TARGETS.ac2100
ramips=y
ramips_mt7621=y
endef

define DEVICES.ac2100
ramips_mt7621:xiaomi_redmi-router-ac2100=y
endef

define MODULES
nf-nathelper=y
nf-nathelper-extra=y
nfnetlink=y
nfnetlink-queue=y
nft-queue=y
nft-compat=y
nft-conntrack=y
nft-nat=y
ipt-core=y
ipt-nfqueue=y
ipt-conntrack-extra=y
ip6tables=y
endef

define PACKAGES
iptables-mod-nfqueue=y
iptables-mod-conntrack-extra=y
wpad-basic-mbedtls=m
libwolfsslcpu-crypto=y
wpad-wolfssl=y
dnsmasq=m
dnsmasq-full=y
luci=y
luci-proto-wireguard=y
xl2tpd=y
mdio-tools=y
luci-theme-material=y
luci-app-upnp=y
luci-app-nft-qos=y
luci-app-wol=y
luci-app-ddns=y
luci-app-https-dns-proxy=y
luci-app-unbound=y
luci-app-adblock-fast=y
easytier=y
luci-app-easytier=y
luci-app-xray=y
luci-app-xray-status=y
gawk=y
grep=y
sed=y
nano=y
coreutils-sort=y
zapret=y
luci-app-zapret=y
curl=y
ca-certificates=y
endef

define LANGUAGES
ru
endef

NCPU := $(shell nproc)

.PHONY: defualt prepare config tools toolchain images clean

default: all

prepare: feeds.conf
feeds.conf: feeds.conf.default
	cp $< $@
	{ $(foreach feed,$(FEEDS),echo "$(subst ;, ,$(feed))";) } >> $@
	./scripts/feeds update -a
	./scripts/feeds install -a

config: .config
.config: prepare
	{ $(foreach target,$(TARGETS),echo 'CONFIG_TARGET_$(target)';) \
	  $(foreach target,$(TARGETS.$(TARGET)),echo 'CONFIG_TARGET_$(target)';) \
	  $(foreach device,$(DEVICES),echo 'CONFIG_TARGET_DEVICE_$(subst :,_DEVICE_,$(device))';) \
	  $(foreach device,$(DEVICES.$(TARGET)),echo 'CONFIG_TARGET_DEVICE_$(subst :,_DEVICE_,$(device))';) \
	  $(foreach module,$(MODULES),echo 'CONFIG_PACKAGE_kmod-$(module)';) \
	  $(foreach module,$(MODULES.$(TARGET)),echo 'CONFIG_PACKAGE_kmod-$(module)';) \
	  $(foreach package,$(PACKAGES),echo 'CONFIG_PACKAGE_$(package)';) \
	  $(foreach language,$(LANGUAGES),echo 'CONFIG_LUCI_LANG_$(language)=y';) \
	} > $@
	$(MAKE) defconfig

download:
	$(MAKE) download -j$(NCPU) V=s

tools toolchain:
	$(MAKE) $@/install -j$(NCPU) || \
	$(MAKE) $@/install -j1 V=s

all:
	$(MAKE) -j$(NCPU) || \
	$(MAKE) -j1 V=s

clean:
	git clean -xf
