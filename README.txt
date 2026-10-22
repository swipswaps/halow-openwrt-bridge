Wi-Fi HaLow (Sub-1 GHz) OpenWrt Bridge + Android Endpoint
=========================================================

1. PROCESS MODEL (WHY HOSTAPD RUNS IN THE FOREGROUND)
------------------------------------------------------

start-ap.sh prepares the PHY, bridge port, and DHCP suppression, then
execs hostapd_s1g in the foreground.  procd tracks the real hostapd
PID, so respawn 3600 1 0 restarts the daemon if it dies.  OpenWrt’s
own hostapd init uses the same pattern: running hostapd without -B
and letting procd own the process.  A sleep-infinity wrapper would
mask hostapd failure and prevent respawn.

2. REGIONAL op_class TABLE
----------------------------

  Region  width  op_class  channel start (GHz)
  US      1 MHz  68        0.902
  US      2 MHz  69        0.902
  EU      1 MHz  66        0.863
  EU      2 MHz  67        0.863

Source: IEEE 802.11-2024 Annex E, Table E-5; confirmed in the Morse
Micro community for EU 66/67.

3. MM8108 FIELD WORKAROUNDS (RELEASE NOTES 2.4.3)
---------------------------------------------------

  Symptom                                Action
  2 MHz near -73 dBm: receive drop       tune-morse.sh rssi-cliff
  1 MHz at strong signal: receive drop   tune-morse.sh strong-signal
  Close range: association fails         tune-morse.sh close-range
  WDS downlink imbalance                 tune-morse.sh wds
  Kernel >6.2 airtime fairness off       tune-morse.sh airtime

tune-morse.sh checks modinfo before printing the insmod command, so a
missing parameter is reported instead of silently ignored.

4. ANDROID CDC-NCM
-------------------

Android names CDC-NCM usbX when bit 1 of the first MAC octet is set,
and the tethering regex matches ethX only.  check-cdc-ncm.sh prints
LOCAL_BIT and the set-global-mac.sh remediation command.

5. FILES
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

6. REFERENCES
-------------

OpenWrt hostapd respawn commit (respawn 3600 1 0):
https://git.openwrt.org/openwrt/staging/chunkeey/commit/?id=ceb612e463fc0dc6fbd7be66dc1a244544213c24

MM8108 Linux release notes 2.4.3 (max_txq_len, enable_airtime_fairness):
https://www.morsemicro.com/resources/software_releases/linux/driver_source_code/MM8108-Linux-Software-Release-Notes.pdf

IEEE 802.11-2024 Annex E, Table E-5 (S1G operating classes):
https://standards.ieee.org/ieee/802.11/10548/

Android CDC-NCM locally-administered bit:
https://docs.rs/embassy-usb/0.5.1/embassy_usb/class/cdc_ncm/
