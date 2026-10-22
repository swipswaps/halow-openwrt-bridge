Wi-Fi HaLow (Sub-1 GHz) OpenWrt Bridge + Android Endpoint
=========================================================

1. REGIONAL op_class TABLE
---------------------------

country_code, s1g_prim_chwidth, and op_class form a single tuple.
Morse Micro: "channel / frequency definitions change between different
countries and operating classes"; op_class is mandatory for S1G.

  Region  width  op_class
  US      1 MHz  68
  US      2 MHz  69
  EU      1 MHz  66
  EU      2 MHz  67
  AU      1 MHz  68
  AU      2 MHz  69
  JP      1 MHz  68
  JP      2 MHz  69

start-ap.sh rejects any other combination with exit 5 before hostapd
runs.  Edit all three values together.


2. MM8108 FIELD WORKAROUNDS (FROM RELEASE NOTES)
--------------------------------------------------

  Symptom                                Workaround
  2 MHz near -73 dBm: receive drop       Shift RSSI by ~2 dB (attenuator
                                         or reposition), or drop to 1 MHz.
  1 MHz at strong signal: receive drop   Move devices further apart;
                                         target below -50 dBm.
  Close range (<10 dBm): association    Keep at least 2 m separation
  fails intermittently                   before pairing.
  Multi-STA WDS downlink imbalance       insmod morse max_txq_len=0
  Kernel >6.2 airtime fairness off       insmod morse enable_airtime_fairness=1

tune-morse.sh prints the exact action for each symptom.  None of these
are hostapd misconfigurations.


3. ANDROID CDC-NCM NAMING MECHANISM
-------------------------------------

The Linux kernel names a CDC-NCM interface usbX when bit 1 of the first
MAC octet is set (locally administered).  Android's Ethernet service
regex matches ethX only, so tethering never enables on usbX.
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

Morse Micro hostapd_s1g configuration specification (op_class and
country_code semantics):
https://github.com/MorseMicro/hostap/blob/v1.14/hostapd_s1g_configuration.md

Morse Micro MM8108 Linux release notes (known issues and workarounds):
https://www.morsemicro.com/resources/software_releases/linux/driver_source_code/MM8108-Linux-Software-Release-Notes.pdf

OpenWrt hostapd respawn settings (respawn 3600 1 0):
https://git.openwrt.org/openwrt/staging/chunkeey/commit/?id=ceb612e463fc0dc6fbd7be66dc1a244544213c24

Android CDC-NCM locally-administered bit:
https://docs.rs/embassy-usb/0.1.0/x86_64-pc-windows-msvc/embassy_usb/class/cdc_ncm/index.html

IEEE 802.11ah-2016, ISBN 978-1-5044-3911-4.
