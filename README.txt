Wi-Fi HaLow (Sub-1 GHz) OpenWrt Bridge + Android Endpoint
=========================================================

1. REGIONAL op_class TABLE (IEEE 802.11-2024, Annex E, Table E-5)
-----------------------------------------------------------------

  Region  width  op_class  channel start (GHz)
  US      1 MHz  68        0.902
  US      2 MHz  69        0.902
  EU      1 MHz  66        0.863
  EU      2 MHz  67        0.863
  AU      1 MHz  68        0.902
  AU      2 MHz  69        0.902

Morse Micro: "For IEEE 80211.ah (S1G), an operating class must be
specified" and "channel / frequency definitions change between
different countries and operating classes".  start-ap.sh rejects
any other country/width/op_class combination with exit 5.


2. MM8108 FIELD WORKAROUNDS (RELEASE NOTES 2.4.3)
--------------------------------------------------

  Symptom                                Action
  2 MHz near -73 dBm: receive drop       tune-morse.sh rssi-cliff
  1 MHz at strong signal: receive drop   tune-morse.sh strong-signal
  Close range (<-10 dBm): association    tune-morse.sh close-range
  fails intermittently
  Multi-STA WDS downlink imbalance       tune-morse.sh wds
  Kernel >6.2 airtime fairness off       tune-morse.sh airtime

None of these are hostapd misconfigurations.  The first three are
physical: attenuate, separate, or reduce bandwidth.  The last two
are module parameters.


3. ANDROID CDC-NCM MECHANISM
-----------------------------

The Linux kernel names a CDC-NCM interface usbX when bit 1 of the
first MAC octet is set (locally administered).  Android's Ethernet
service regex matches ethX only, so tethering never enables on usbX.
check-cdc-ncm.sh prints LOCAL_BIT and the resulting naming.
set-global-mac.sh clears bit 1 and renames the interface to ethX.


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
openwrt/tune-morse.sh
android/README-android.txt
android/check-cdc-ncm.sh
android/set-global-mac.sh


5. REFERENCES
-------------

IEEE 802.11-2024 Annex E, Table E-5 (S1G operating classes):
https://standards.ieee.org/ieee/802.11/10548/

Morse Micro hostapd_s1g configuration specification:
https://github.com/MorseMicro/hostap/blob/v1.14/hostapd_s1g_configuration.md

MM8108 Linux release notes 2.4.3:
https://www.morsemicro.com/resources/software_releases/linux/driver_source_code/MM8108-Linux-Software-Release-Notes.pdf

Android CDC-NCM locally-administered bit:
https://docs.rs/embassy-usb/0.5.0/embassy_usb/class/cdc_ncm/

OpenWrt procd init scripts:
https://openwrt.org/docs/guide-developer/procd-init-scripts
