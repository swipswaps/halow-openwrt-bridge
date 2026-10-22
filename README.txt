Wi-Fi HaLow (Sub-1 GHz) OpenWrt Bridge + Android Endpoint
=========================================================

1. RESIDUAL FAILURE CLASSES
----------------------------

A. Regulatory tuple mismatch.
   s1g_prim_chwidth, op_class, and channel must agree.
   1 MHz (chwidth=0) pairs with op_class 67/68.
   2 MHz (chwidth=1) pairs with op_class 69/70/71.
   start-ap.sh now rejects mismatches with exit 5 before hostapd runs.
   Source: hostapd_s1g_configuration.md v1.14 (Morse Micro).

B. MM8108 receive degradation.
   Documented in Morse Micro OpenWrt release notes 2.11.12:
     - 2 MHz near -73 dBm RSSI: receive degradation.
     - 1 MHz at strong signals: receive degradation.
     - Very close range: intermittent STA association failure.
   Workaround path is tune-morse.sh:
     bandwidth 1      reduce from 2 MHz to 1 MHz (recommended first).
     mcs N            opt-in fixed MCS; warn about packet loss.
     rssi-offset      not a module parameter; use physical attenuation.
   Forcing MCS is not the default because the community reports
   increased packet loss when the rate is wrong for the channel.

C. Android CDC-NCM MAC bit.
   Android assigns usbX (not ethX) when the locally-administered bit
   is set, and the Ethernet tethering option then does not enable.
   check-cdc-ncm.sh reports LOCAL_BIT.
   set-global-mac.sh clears bit 1 of the first octet and renames the
   interface to ethX.  The change is not persistent across replug;
   add a udev rule if persistence is required.

D. UCI list duplication.
   start-ap.sh and firewall-halow.sh now token-match the interface
   name so repeated runs do not append a second entry.  uci-defaults
   applies the same guard.  A duplicate port survives netifd but
   breaks stop-ap.sh's del_list (which removes one instance only).


2. WHAT THIS VERSION FIXES
---------------------------

start-ap.sh:   regulatory tuple validation, exact port match,
               hostapd exit code propagated.
firewall-halow.sh: token-wise dedup.
uci-defaults-halow: guards on both lists.
tune-morse.sh: new; bandwidth-first MM8108 workaround.
set-global-mac.sh: new; CDC-NCM MAC remediation.
README.txt:    this section.
android/README-android.txt: remediation commands.


3. FILES
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


4. REFERENCES
-------------

Morse Micro hostapd_s1g configuration specification:
https://github.com/MorseMicro/hostap/blob/v1.14/hostapd_s1g_configuration.md

Morse Micro OpenWrt release notes 2.11.12 (MM8108 known issues):
https://www.morsemicro.com/zh-hans/download/openwrt-software-release-notes/

Android CDC-NCM locally-administered MAC bit:
https://docs.rs/embassy-usb/0.5.0/embassy_usb/class/cdc_ncm/

IEEE 802.11ah-2016, ISBN 978-1-5044-3911-4.
