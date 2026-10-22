Wi-Fi HaLow (Sub-1 GHz) OpenWrt Bridge + Android Endpoint
=========================================================

1. KNOWN FAILURE MODES (READ THIS FIRST)
-----------------------------------------

A. WiFi interfaces do not appear in /sys/class/net in OpenWrt.
   Gateworks states this explicitly.  Any script that checks
   /sys/class/net/wlan0 or /sys/class/net/br-lan will silently take
   the failure branch.  This repository uses iw dev and ip link show
   instead.

B. procd will mark a daemonised hostapd_s1g as a crash loop.
   When start-ap.sh runs "hostapd_s1g -B", the tracked shell exits
   immediately.  procd sees a fast exit and, after the retry
   threshold, refuses to restart the service.  OpenWrt's own hostapd
   init uses "respawn 3600 1 0" for this reason.  halow-ap.init now
   uses the same respawn settings and wraps the start script in
   "sleep infinity" so procd tracks a long-lived process.

C. Android Ethernet tethering does NOT enable when the CDC-NCM MAC
   has the locally-administered bit set (bit 1 of the first octet).
   The interface is named usbX instead of ethX, and Android's
   Ethernet service ignores it.  check-cdc-ncm.sh now prints
   LOCAL_BIT for each interface and warns explicitly.

D. The OpenWrt firewall blocks all traffic on wlan0 until the
   interface is assigned to a zone.  Without firewall-halow.sh
   succeeding, DHCP and ARP are silently dropped.

E. hw_mode=a is 5 GHz.  For S1G, hw_mode=ah is required by the
   upstream RFC and the hostapd source.  The shipped file now uses
   hw_mode=ah.


2. MANDATORY S1G PARAMETERS
----------------------------

hw_mode=ah, ieee80211ah=1.
op_class is mandatory and must match channel and s1g_prim_chwidth.
US 1 MHz: channel=33, op_class=68.
US 2 MHz: channel=10, op_class=69, s1g_prim_chwidth=1.
s1g_prim_chwidth=0 is 1 MHz; 1 is 2 MHz.


3. MM8108 HARDWARE LIMITATIONS
-------------------------------

From Morse Micro OpenWrt release notes:
  - Receive degradation at 2 MHz near -73 dBm RSSI.
  - Receive degradation at 1 MHz under strong signals.
  - Power saving disabled for USB radios.
  - MM8108 does not yet have full feature parity with MM6108.


4. FILES
---------

README.txt
requirements.txt
openwrt/disable-uci-halow.sh
openwrt/hostapd_s1g.conf
openwrt/start-ap.sh
openwrt/firewall-halow.sh
openwrt/stop-ap.sh
openwrt/setup-relayd.sh
openwrt/disable-dhcp-halow.sh
openwrt/uci-defaults-halow
openwrt/halow-ap.init
android/README-android.txt
android/check-cdc-ncm.sh


5. HOW TO USE
-------------

Manual:
  ./openwrt/disable-uci-halow.sh
  edit openwrt/hostapd_s1g.conf (country_code, channel, op_class)
  ./openwrt/start-ap.sh
  ./openwrt/firewall-halow.sh
  ./openwrt/disable-dhcp-halow.sh

Persistence:
  copy uci-defaults-halow to /etc/uci-defaults/99-halow
  install halow-ap.init as /etc/init.d/halow-ap
  copy start-ap.sh and stop-ap.sh to /usr/share/halow/
  /etc/init.d/halow-ap enable


6. REFERENCES
-------------

Gateworks GW16167 wiki: WiFi interfaces do not appear in /sys/class/net;
avoid UCI for HaLow.
https://trac.gateworks.com/wiki/expansion/gw16167

OpenWrt hostapd respawn settings (respawn 3600 1 0):
https://git.openwrt.org/openwrt/staging/chunkeey/commit/?id=ceb612e463fc0dc6fbd7be66dc1a244544213c24

Android CDC-NCM locally-administered MAC bit:
https://docs.rs/embassy-usb/0.5.1/embassy_usb/class/cdc_ncm/

Upstream S1G RFC (hw_mode=ah):
https://patchwork.ozlabs.org/project/hostap/patch/20260528063857.950556-5-lachlan.hodges@morsemicro.com/

Morse Micro OpenWrt release notes (MM8108 known issues):
https://www.morsemicro.com/zh-hans/download/openwrt-2-8-5-software-release-note/

IEEE 802.11ah-2016, ISBN 978-1-5044-3911-4.
