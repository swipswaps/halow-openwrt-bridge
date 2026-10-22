Wi-Fi HaLow (Sub-1 GHz) OpenWrt Bridge + Android Endpoint
=========================================================

Hardware: Morse Micro MM8108 (or MM6108)
Kernel:   Native Linux mac80211 on OpenWrt
Topology: OpenWrt AP bridged to upstream LAN; Android endpoint as STA


1. MANDATORY S1G PARAMETERS
----------------------------

hw_mode=ah is mandatory for 802.11ah.  hw_mode=a is standard 5 GHz
and is semantically wrong for S1G.  The Morse Micro hostapd_s1g
specification and the upstream S1G RFC both define hw_mode=ah for
the sub-1 GHz band.

op_class is mandatory for S1G.  It must match channel and
s1g_prim_chwidth together.  For US 1 MHz: channel=33, op_class=68.
For US 2 MHz: channel=10, op_class=69, with s1g_prim_chwidth=1.
An op_class that does not match the width is rejected or operates
outside the intended regulatory envelope.

s1g_prim_chwidth=0 means 1 MHz (default); 1 means 2 MHz.


2. MM8108 HARDWARE LIMITATIONS (FROM MORSE MICRO RELEASE NOTES)
----------------------------------------------------------------

These are documented hardware/firmware behaviours, not hostapd
misconfigurations:

  - Receive degradation at 2 MHz near -73 dBm RSSI.
  - Receive degradation at 1 MHz under strong signals.
  - Intermittent STA association failure at very close range.
  - Power saving disabled for USB radios in the referenced release.

If throughput falls at close range on 1 MHz, suspect the known
strong-signal behaviour before re-checking hostapd parameters.


3. ANDROID CDC-NCM NAMING CAVEAT
---------------------------------

Android's USB Ethernet stack chooses usbX naming when the MAC
address has the locally-administered bit set (bit 1 of the first
octet).  Setting the MAC to a globally assigned address makes the
interface appear as ethX, which the Android Ethernet service
recognises more reliably.  The check script prints the first octet
of each interface MAC for this reason.


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

Manual path:
  ./openwrt/disable-uci-halow.sh
  edit openwrt/hostapd_s1g.conf for your regulatory domain
  ./openwrt/start-ap.sh

Persistence path:
  copy openwrt/uci-defaults-halow to /etc/uci-defaults/99-halow
  install openwrt/halow-ap.init as /etc/init.d/halow-ap
  place start-ap.sh and stop-ap.sh under /usr/share/halow/
  /etc/init.d/halow-ap enable

Do not reintroduce UCI Wi-Fi control for the HaLow radio.  Keep UCI
limited to bridge ports, firewall zones, and DHCP suppression.


6. REFERENCES
-------------

Morse Micro hostapd_s1g configuration specification:
https://github.com/MorseMicro/hostap/blob/v1.14/hostapd_s1g_configuration.md

OpenWrt netifd bridge ports migration (uci add_list network.ports):
https://git.openwrt.org/?p=openwrt/staging/neocturne.git;a=commitdiff;h=c8e68dce61140460ff38ac04fa84e57246f8ae63

OpenWrt firewall zone list notation:
https://git.openwrt.org/openwrt/staging/adrian/commit/?id=3bb397c99700b4645445cc0cc0955078a7b35d02

Morse Micro OpenWrt release notes (MM8108 known issues):
https://www.morsemicro.com/zh-hans/download/openwrt-software-release-notes/

IEEE 802.11ah-2016, Sub 1 GHz License Exempt Operation.
ISBN 978-1-5044-3911-4. DOI 10.1109/IEEESTD.2017.7920364.
