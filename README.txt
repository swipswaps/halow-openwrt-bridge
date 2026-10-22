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

2. THERMAL PROTECTION (MM8108)
-------------------------------

The MM8108 on-chip PA delivers up to 26 dBm average power.  Over-temperature
protection (OTP) disables the transmitter when the die exceeds the datasheet
threshold.  Public summaries commonly cite approximately 85 C; the exact
threshold, hysteresis and duration should be taken from the MM8108 datasheet
for the specific silicon revision, not from this document.  Operating beyond
the limit can cause an unstable state, permanent hardware failure, or link
disconnection.  Ensure enclosure airflow and duty-cycle headroom, and avoid
sustained 26 dBm operation in sealed enclosures.
Run `tune-morse.sh thermal` for the on-device reminder.

3. REGIONAL op_class TABLE
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
An unknown region is refused unless ALLOW_UNKNOWN_REGION=1 is set; that
override is the operator's regulatory responsibility.

4. S1G CAPABILITY FLAGS
------------------------

s1g_capab accepts [SHORT-GI-1] through [SHORT-GI-16] and [SHORT-GI-ALL].
[SHORT-GI-ALL] is the specification default and enables short GI for the
configured bandwidth including sub-bandwidths.  This repository uses
[SHORT-GI-ALL], matching the Gateworks example configurations.
Source: MorseMicro/hostapd_s1g_configuration.md v1.14, lines 42-61.

5. DISABLING UCI FOR THE HaLOW RADIO
-------------------------------------

disable-uci-halow.sh requires HALOW_RADIO (for example radio1).  It does not
disable every radioN: on a multi-radio router that would remove the
management radio and take the device off the network.  Run it as:
    HALOW_RADIO=radio1 ./openwrt/disable-uci-halow.sh

uci-defaults-halow does NOT disable any radioN; it only adds wlan0 to the
br-lan ports list and to the lan firewall zone at first boot.

6. RELAYD ALTERNATIVE (CAVEAT)
------------------------------

setup-relayd.sh writes a modern relay interface:
    network.repeater_bridge=interface
    network.repeater_bridge.proto=relay
    network.repeater_bridge.ipaddr=192.168.4.1
    network.repeater_bridge.network='br-lan wlan0'
Modern relayd reads ipaddr and the network list from the interface section.

Caveat: relayd is not a full Layer-2 bridge.  DHCP, mDNS, and upstream
throughput may not behave identically to a wired bridge, and relayd
primarily handles IPv4.  When both ends are controllable, WDS or 802.11s is
preferred over relayd.  Use the hard bridge (start-ap.sh + firewall-halow.sh)
whenever a true Layer-2 segment is required.

7. KNOWN LIMITATIONS (MM8108 RELEASE NOTES)
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

8. PROCESS MODEL
----------------

start-ap.sh prepares the PHY, bridge port, and DHCP suppression, then execs
hostapd_s1g in the foreground.  procd tracks the real hostapd PID.
halow-ap.init uses respawn 3600 5 5 (threshold 3600 s, timeout 5 s, retry 5),
so a permanent configuration error is retried five times and then left
visible in logread instead of restarting forever.

9. ANDROID CDC-NCM
-------------------

The kernel names CDC-NCM usbX when bit 1 of the first MAC octet is set
(locally administered).  On many Android releases, notably before Android
14 (U), the tethering configuration matches ethX only, so tethering does
not enable.  Android 14 changed the regex to include usbX, then reverted it
and re-landed it for Android 15 (V); vendor forks vary.  check-cdc-ncm.sh
prints LOCAL_BIT and the set-global-mac.sh remediation command.

10. LINT GATE
--------------

lint.sh runs sh -n and (when available) shellcheck -s sh -e SC2034 on every
script.  A push script that calls lint.sh should treat a non-zero exit as
fatal.  The canonical push pattern is:

    sh lint.sh
    LINT_RC=$?
    if [ "$LINT_RC" -ne 0 ]; then
        if [ "${LINT_OVERRIDE:-0}" != "1" ]; then
            echo "lint failed; review before pushing."
            exit 3
        fi
        echo "LINT_OVERRIDE=1; proceeding after lint failure."
    fi

The override exists for deliberate edge-case pushes; it should not be used
to route around a red lint by default.

11. LICENSE
------------

GNU General Public License v2.0.  See LICENSE.

12. FILES
----------

README.txt
CHANGELOG.txt
LICENSE
requirements.txt
.gitignore
lint.sh
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

13. REFERENCES
--------------

GHSA-7C7H-P74X-W3H5 (CVE-2026-7764):
https://github.com/advisories/GHSA-7C7H-P74X-W3H5

Morse Micro hostapd_s1g configuration specification:
https://github.com/MorseMicro/hostap/blob/v1.14/hostapd_s1g_configuration.md

Gateworks GW16167 wiki (channel mapping, UCI avoidance, firewall zone):
https://trac.gateworks.com/wiki/expansion/gw16167

OpenWrt procd respawn parameters:
https://mintlify.wiki/openwrt/openwrt/system/procd

OpenWrt relayd UCI schema (proto=relay, ipaddr, network list):
https://git.openwrt.org/?p=openwrt/openwrt.git;a=blob;f=package/network/services/relayd/files/relay.sh

Android CDC-NCM locally-administered bit:
https://docs.rs/embassy-usb/0.5.0/embassy_usb/class/cdc_ncm/

IEEE 802.11-2024 Annex E, Table E-5 (global operating classes 66/67):
https://standards.ieee.org/ieee/802.11/10548/
