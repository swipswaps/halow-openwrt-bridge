Wi-Fi HaLow (Sub-1 GHz) OpenWrt Bridge + Android Endpoint
=========================================================

1. SECURITY ADVISORY (MANDATORY READING)
-----------------------------------------

CVE-2026-7764: out-of-bounds read in morse.ko Vendor IE processing.
An unauthenticated attacker within radio range can leak kernel heap
memory or cause a denial of service via a crafted 802.11ah beacon or
probe response containing a malformed Vendor Information Element.
Fixed in Morse Micro HaLowLink 2 software 2.11.12 and later.
Advisory: https://www.morsemicro.com/security/advisories/mm-sa-2026-003/
Action: upgrade the morse driver and firmware to 2.11.12+ before
deploying in any environment where radio-range attackers are in scope.
Run `tune-morse.sh security` for the on-device reminder.

2. REGIONAL op_class TABLE (IEEE 802.11-2024, ANNEX E, TABLE E-5)
------------------------------------------------------------------

  Region  width  op_class  channel start (GHz)
  US      1 MHz  68        0.902
  US      2 MHz  69        0.902
  EU      1 MHz  66        0.863
  EU      2 MHz  67        0.863
  AU      1 MHz  68        0.902
  AU      2 MHz  69        0.902
  JP      1 MHz  68        0.902
  JP      2 MHz  69        0.902

Using US 68/69 in an EU deployment causes hostapd_s1g to fail with
"Invalid s1g config of oper class, country code and channel".
start-ap.sh validates the tuple and rejects mismatches with exit 5.

3. KNOWN LIMITATIONS (MM8108 RELEASE NOTES)
--------------------------------------------

  Symptom                                Action
  2 MHz near -73 dBm: receive drop       tune-morse.sh rssi-cliff
  1 MHz at strong signal: receive drop   tune-morse.sh strong-signal
  Close range: association fails         tune-morse.sh close-range
  WDS downlink imbalance                 tune-morse.sh wds
  Kernel >6.2 airtime fairness off       tune-morse.sh airtime
  TCP throughput ~10% below expectation  tune-morse.sh throughput
  Vendor IE OOB (CVE-2026-7764)          tune-morse.sh security

4. PROCESS MODEL
----------------

start-ap.sh prepares the PHY, bridge port, and DHCP suppression, then
execs hostapd_s1g in the foreground.  procd tracks the real hostapd
PID, so respawn 3600 1 0 restarts the daemon if it dies.  This matches
OpenWrt's own hostapd init: running hostapd without -B and letting
procd own the process.

5. ANDROID CDC-NCM
-------------------

Android names CDC-NCM usbX when bit 1 of the first MAC octet is set,
and the tethering regex matches ethX only.  check-cdc-ncm.sh prints
LOCAL_BIT and the set-global-mac.sh remediation command.

6. FILES
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
openwrt/tune-morse.sh
android/README-android.txt
android/check-cdc-ncm.sh
android/set-global-mac.sh

7. REFERENCES
-------------

CVE-2026-7764 (morse.ko Vendor IE OOB read):
https://www.morsemicro.com/security/advisories/mm-sa-2026-003/

IEEE 802.11-2024 Annex E, Table E-5 (S1G operating classes):
https://standards.ieee.org/ieee/802.11/10548/

OpenWrt hostapd respawn commit (respawn 3600 1 0):
https://git.openwrt.org/?p=openwrt/staging/ynezz.git;a=commit;h=ceb612e463fc0dc6fbd7be66dc1a244544213c24

Morse Micro hostapd_s1g configuration specification:
https://github.com/MorseMicro/hostap/blob/v1.14/hostapd_s1g_configuration.md

MM8108 Linux release notes:
https://www.morsemicro.com/resources/software_releases/linux/driver_source_code/MM8108-Linux-Software-Release-Notes.pdf

Android CDC-NCM locally-administered bit:
https://docs.rs/embassy-usb/0.5.1/embassy_usb/class/cdc_ncm/
