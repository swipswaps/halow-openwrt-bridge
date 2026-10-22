Wi-Fi HaLow (Sub-1 GHz) OpenWrt Bridge + Android Endpoint
=========================================================

1. SECURITY ADVISORY (MANDATORY)
---------------------------------

CVE-2026-7764 / GHSA-7C7H-P74X-W3H5
Out-of-bounds read in morse.ko Vendor IE processing.
morse_vendor_find_vendor_ie() does not validate the IE length against the
expected structure size before the result is passed to
morse_vendor_rx_caps_ops_ie() and morse_vendor_fill_sta_vendor_info(),
which read at fixed offsets.  The length check only requires the IE to be
longer than 3 bytes, so a crafted 802.11ah beacon or probe response can
cause a heap out-of-bounds read of up to 9 bytes, disclosing kernel heap
memory or causing a kernel oops/panic.
CVSS 3.1 base score: 6.8.  Fixed in HaLowLink 2 software 2.11.12 and later.
Advisory: https://github.com/advisories/GHSA-7C7H-P74X-W3H5
Action: upgrade morse.ko and firmware to 2.11.12+ before deploying in any
environment where radio-range attackers are in scope.
Run `tune-morse.sh security` for the on-device reminder.

2. DEFAULT PSK AND ROTATION
----------------------------

Earlier revisions of this repository shipped
wpa_passphrase=ChangeMe_HaLow_2026 as a placeholder.  That value is in
git history and must be treated as public.  Any deployment that copied
a hostapd_s1g.conf from history and left the passphrase unchanged must
rotate the PSK on both AP and station before continuing.

The current hostapd_s1g.conf ships wpa_passphrase=__CHANGEME__, and
start-ap.sh rejects any passphrase that is empty or contains CHANGEME.
install.sh chmod 600s the installed configuration.

3. THERMAL PROTECTION (MM8108)
-------------------------------

The MM8108 PA delivers up to 26 dBm average power.  Over-temperature
protection disables the transmitter at the datasheet threshold.  Public
summaries commonly cite approximately 85 C; verify against the MM8108
datasheet for the specific silicon revision rather than this document.
Ensure enclosure airflow and duty-cycle headroom; avoid sustained
26 dBm operation in sealed enclosures.
Run `tune-morse.sh thermal` for the on-device reminder.

4. REGIONAL op_class TABLE
----------------------------

  Region  width  op_class  channel start (GHz)
  US      1 MHz  68        0.902
  US      2 MHz  69        0.902
  EU      1 MHz  66        0.863
  EU      2 MHz  67        0.863
  AU      1 MHz  68        0.902
  AU      2 MHz  69        0.902
  JP      1 MHz  68        0.902
  JP      2 MHz  69        0.902

start-ap.sh validates the tuple and rejects mismatches with exit 5.

5. S1G CAPABILITY FLAGS
------------------------

s1g_capab accepts [SHORT-GI-1] through [SHORT-GI-16] and [SHORT-GI-ALL].
[SHORT-GI-ALL] is the specification default.
Source: MorseMicro/hostapd_s1g_configuration.md v1.14.

6. DISABLING UCI FOR THE HaLOW RADIO
-------------------------------------

disable-uci-halow.sh requires HALOW_RADIO (for example radio1).  It does
not disable every radioN: on a multi-radio router that would remove the
management radio.  Run it as:
    HALOW_RADIO=radio1 ./openwrt/disable-uci-halow.sh

uci-defaults-halow does not disable any radioN; it only seeds the br-lan
port and lan firewall zone at first boot.

7. RELAYD ALTERNATIVE (CAVEAT)
------------------------------

setup-relayd.sh writes a modern relay interface:
    network.repeater_bridge=interface
    network.repeater_bridge.proto=relay
    network.repeater_bridge.ipaddr=192.168.4.1
    network.repeater_bridge.network='br-lan wlan0'
Caveat: relayd is not a full Layer-2 bridge.  DHCP, mDNS, and upstream
throughput may not match a wired bridge, and relayd is primarily IPv4.
WDS or 802.11s is preferred when both ends are controllable.

8. KNOWN LIMITATIONS (MM8108 RELEASE NOTES)
--------------------------------------------

  Symptom                                Action
  2 MHz near -73 dBm: receive drop       tune-morse.sh rssi-cliff
  1 MHz at strong signal: receive drop   tune-morse.sh strong-signal
  Close range: association fails         tune-morse.sh close-range
  WDS downlink imbalance                 tune-morse.sh wds
  Kernel >6.2 airtime fairness off       tune-morse.sh airtime
  Thermal shutdown near datasheet OTP    tune-morse.sh thermal
  TCP throughput ~10% below expectation  tune-morse.sh throughput
  Vendor IE OOB (CVE-2026-7764)          tune-morse.sh security

9. PROCESS MODEL
----------------

start-ap.sh execs hostapd_s1g in the foreground so procd tracks the
real daemon.  halow-ap.init uses respawn 3600 5 5, so a permanent
configuration error is retried five times and then left visible in
logread.  start-ap.sh refuses to start a second hostapd_s1g when one
is already running (exit 6); set FORCE=1 to stop and restart.

10. ANDROID CDC-NCM
--------------------

Linux usbnet_probe() names cdc_ncm, cdc_ether, and rndis_host
interfaces usbN (drivers/net/usb/usbnet.c).  Android's default
config_ethernet_iface_regex matches ethN, so the Ethernet service
ignores usbN and tethering does not enable.
The fix is an explicit rename, not a MAC change:
    ip link set dev usb0 down
    ip link set dev usb0 name eth0
    ip link set dev eth0 up
set-global-mac.sh performs this rename (the filename is historical).
It also clears the locally-administered MAC bit, which some vendor
forks additionally filter on, but that bit does not rename the
interface on stock Linux.

11. LINT GATE
--------------

lint.sh runs sh -n and, when available, shellcheck -s sh -e SC2034 on
every script.  push.sh runs lint.sh and aborts on failure unless
LINT_OVERRIDE=1 is set.  Use push.sh rather than raw git push so the
gate cannot be bypassed by habit.

12. LICENSE
------------

SPDX-License-Identifier: GPL-2.0-only.
LICENSE is a pointer; run ./fetch-license.sh to populate it with the
verbatim GPL-2.0 text before tagging or distributing.

13. FILES
----------

README.txt
CHANGELOG.txt
LICENSE
requirements.txt
.gitignore
lint.sh
push.sh
fetch-license.sh
install.sh
openwrt/disable-uci-halow.sh
openwrt/hostapd_s1g.conf
openwrt/start-ap.sh
openwrt/firewall-halow.sh
openwrt/stop-ap.sh
openwrt/setup-relayd.sh
openwrt/disable-dhcp-halow.sh
openwrt/uci-defaults-halow
openwrt/halow-ap.init
openwrt/tune-morse.sh
android/README-android.txt
android/check-cdc-ncm.sh
android/set-global-mac.sh

14. REFERENCES
--------------

GHSA-7C7H-P74X-W3H5 (CVE-2026-7764):
https://github.com/advisories/GHSA-7C7H-P74X-W3H5

Linux usbnet_probe() interface naming:
https://elixir.bootlin.com/linux/latest/source/drivers/net/usb/usbnet.c

AOSP Ethernet interface regex (config_ethernet_iface_regex):
https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/core/res/res/values/config.xml

Morse Micro hostapd_s1g configuration specification:
https://github.com/MorseMicro/hostap/blob/v1.14/hostapd_s1g_configuration.md

Gateworks GW16167 wiki:
https://trac.gateworks.com/wiki/expansion/gw16167

OpenWrt procd respawn parameters:
https://mintlify.wiki/openwrt/openwrt/system/procd

OpenWrt relayd UCI schema:
https://git.openwrt.org/?p=openwrt/openwrt.git;a=blob;f=package/network/services/relayd/files/relay.sh

IEEE 802.11-2024 Annex E, Table E-5:
https://standards.ieee.org/ieee/802.11/10548/

GPL-2.0 verbatim text:
https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
