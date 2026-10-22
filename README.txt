Wi-Fi HaLow (Sub-1 GHz) OpenWrt Bridge + Android Endpoint
=========================================================

1. SECURITY
-----------

The MM810x driver referenced by Morse Micro release notes has an
out-of-bounds memory access in vendor Information Element handling.
Apply the Morse Micro OpenWrt patch sets from
https://github.com/MorseMicro/morse-feed before deploying in
untrusted environments.  tune-morse.sh security prints this warning.

2. KNOWN LIMITATIONS (MM8108 RELEASE NOTES)
--------------------------------------------

  Symptom                                Action
  2 MHz near -73 dBm: receive drop       tune-morse.sh rssi-cliff
  1 MHz at strong signal: receive drop   tune-morse.sh strong-signal
  Close range: association fails         tune-morse.sh close-range
  WDS downlink imbalance                 tune-morse.sh wds
  Kernel >6.2 airtime fairness off       tune-morse.sh airtime
  TCP throughput ~10% below expectation  tune-morse.sh throughput
  Vendor IE OOB vulnerability            tune-morse.sh security

3. PROCESS MODEL
----------------

start-ap.sh prepares the PHY, bridge port, and DHCP suppression, then
execs hostapd_s1g in the foreground.  procd tracks the real hostapd
PID, so respawn 3600 1 0 restarts the daemon if it dies.  This matches
OpenWrt's own hostapd init: running hostapd without -B and letting
procd own the process.

4. REGIONAL op_class TABLE
----------------------------

  Region  width  op_class
  US      1 MHz  68
  US      2 MHz  69
  EU      1 MHz  66
  EU      2 MHz  67

Source: IEEE 802.11-2024 Annex E, Table E-5.

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

OpenWrt hostapd respawn commit (respawn 3600 1 0):
https://git.openwrt.org/openwrt/staging/chunkeey/commit/?id=ceb612e463fc0dc6fbd7be66dc1a244544213c24

Morse Micro hostapd_s1g configuration specification:
https://github.com/MorseMicro/hostap/blob/v1.14/hostapd_s1g_configuration.md

MM8108 Linux release notes (max_txq_len, airtime fairness, RSSI, security):
https://www.morsemicro.com/resources/software_releases/linux/driver_source_code/MM8108-Linux-Software-Release-Notes.pdf

IEEE 802.11-2024 Annex E, Table E-5:
https://standards.ieee.org/ieee/802.11/10548/

Android CDC-NCM locally-administered bit:
https://docs.rs/embassy-usb/0.5.1/embassy_usb/class/cdc_ncm/
