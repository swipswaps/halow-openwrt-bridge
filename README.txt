Wi-Fi HaLow (Sub-1 GHz) OpenWrt Bridge + Android Endpoint
=========================================================

1. SECURITY ADVISORY (MANDATORY)
---------------------------------

CVE-2026-7764: out-of-bounds read in morse.ko Vendor IE processing.
An unauthenticated attacker within radio range can disclose up to 9
bytes of kernel heap or cause a kernel panic via a malformed 802.11ah
beacon or probe response.  CVSS 3.1 base score 6.8.  Fixed in
HaLowLink 2 software 2.11.12 and later.
Advisory: https://app.opencve.io/cve/CVE-2026-7764
Action: upgrade morse.ko and firmware to 2.11.12+ before deploying in
any environment where radio-range attackers are in scope.

2. REGIONAL op_class TABLE
----------------------------

  Region  width  op_class  band
  EU      1 MHz  66        863 MHz
  EU      2 MHz  67        863 MHz
  US      1 MHz  68        902 MHz
  US      2 MHz  69        902 MHz
  AU      1 MHz  68        902 MHz
  AU      2 MHz  69        902 MHz
  JP      1 MHz  68        902 MHz
  JP      2 MHz  69        902 MHz

EU 66/67 are global operating classes 0.863 GHz at 1 MHz and 2 MHz
spacing.  Source: IEEE 802.11-2020 Annex E, Table E-5, as reflected in
the Wireshark operating-class table.  start-ap.sh accepts US/AU/JP
0:68/1:69 and EU 0:66/1:67; any other country is refused unless
ALLOW_UNKNOWN_REGION=1 is set.

3. S1G CAPABILITY FLAGS
------------------------

s1g_capab accepts [SHORT-GI-1] through [SHORT-GI-16] and
[SHORT-GI-ALL].  [SHORT-GI-ALL] is the specification default and
enables short GI for the configured bandwidth including sub-bandwidths;
[SHORT-GI-1] would enable it at 1 MHz only.  This repository uses
[SHORT-GI-ALL].
Source: MorseMicro/hostapd_s1g_configuration.md v1.14, lines 42-61.

4. DISABLING UCI FOR THE HaLOW RADIO
-------------------------------------

disable-uci-halow.sh requires HALOW_RADIO (for example radio1).  It
does not disable every radioN: on a multi-radio router that would
remove the management radio and take the device off the network.
Run it as:
    HALOW_RADIO=radio1 ./openwrt/disable-uci-halow.sh

5. RELAYD ALTERNATIVE
---------------------

setup-relayd.sh writes a modern relay interface:
    network.repeater_bridge=interface
    network.repeater_bridge.proto='relay'
    network.repeater_bridge.ipaddr='192.168.4.1'
    network.repeater_bridge.network='br-lan wlan0'
Modern relayd reads ipaddr and the network list from the interface
section; there is no relayd.@relayd[0].local_ipaddr option.

6. KNOWN LIMITATIONS (MM8108 RELEASE NOTES)
--------------------------------------------

  Symptom                                Action
  2 MHz near -73 dBm: receive drop       tune-morse.sh rssi-cliff
  1 MHz at strong signal: receive drop   tune-morse.sh strong-signal
  Close range: association fails         tune-morse.sh close-range
  WDS downlink imbalance                 tune-morse.sh wds
  Kernel >6.2 airtime fairness off       tune-morse.sh airtime
  TCP throughput ~10% below expectation  tune-morse.sh throughput
  Vendor IE OOB (CVE-2026-7764)          tune-morse.sh security

7. PROCESS MODEL
----------------

start-ap.sh prepares the PHY, bridge port, and DHCP suppression, then
execs hostapd_s1g in the foreground.  procd tracks the real hostapd
PID.  halow-ap.init uses respawn 3600 5 5, so a permanent configuration
error is retried five times and then left visible in logread instead of
restarting forever.

8. ANDROID CDC-NCM
-------------------

The kernel names CDC-NCM usbX when bit 1 of the first MAC octet is set.
On many Android releases, notably before Android 14 (U), the tethering
configuration matches ethX only, so tethering does not enable.  Android
14 changed the regex to include usbX, then reverted it and re-landed it
for Android 15 (V); vendor forks vary.  check-cdc-ncm.sh prints
LOCAL_BIT and the set-global-mac.sh remediation command.

9. FILES
---------

README.txt
requirements.txt
lint.sh
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

10. REFERENCES
--------------

CVE-2026-7764:
https://app.opencve.io/cve/CVE-2026-7764

Morse Micro hostapd_s1g configuration specification (s1g_capab,
op_class, country_code):
https://github.com/MorseMicro/hostap/blob/v1.14/hostapd_s1g_configuration.md

Gateworks GW16167 wiki (channel mapping, UCI avoidance, firewall zone
warning):
https://trac.gateworks.com/wiki/expansion/gw16167

OpenWrt hostapd respawn settings:
https://git.openwrt.org/?p=openwrt/staging/chunkeey.git;a=commit;h=ceb612e463fc0dc6fbd7be66dc1a244544213c24

OpenWrt relayd UCI schema (ipaddr, network list):
https://git.openwrt.org/?p=openwrt/openwrt.git;a=blob;f=package/network/services/relayd/files/relay.sh

Android CDC-NCM locally-administered bit:
https://docs.rs/embassy-usb/0.1.0/x86_64-pc-windows-msvc/embassy_usb/class/cdc_ncm/index.html

IEEE 802.11-2020 Annex E, Table E-5 (global operating classes 66/67):
https://standards.ieee.org/ieee/802.11/7028/
