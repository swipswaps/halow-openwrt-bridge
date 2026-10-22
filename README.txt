Wi-Fi HaLow (Sub-1 GHz) OpenWrt Bridge + Android Endpoint
=========================================================

Hardware: Morse Micro MM8108 (or MM6108)
Kernel: Native Linux mac80211 on OpenWrt
Topology: OpenWrt AP bridged to upstream LAN; Android endpoint as STA


1. HOW WE GOT HERE
------------------

The first iteration assumed OpenWrt UCI could configure the HaLow radio
like any other Wi-Fi radio. That assumption failed. Gateworks states
plainly that OpenWrt UCI is "not yet fully compatible with all features
(i.e. WPA3 setup) out-of-the-box" for HaLow and recommends that UCI not
configure the HaLow radio at all; the interface should be driven manually
with hostapd_s1g and wpa_supplicant_s1g [1][2].

The first correction was hw_mode. The Morse Micro hostapd fork accepts
hw_mode=a, not hw_mode=ah. Gateworks example configurations for both the
GW16167 and GW16159 use hw_mode=a [3][4].

The second correction was bridge membership. The initial script used
"ip link set wlan0 master br-lan". That is not persistent across reboot
or wifi reload. OpenWrt's netifd has used the "ports" list on the bridge
device for years, and the supported migration is
  uci add_list network.@device[-1].ports='wlan0'
followed by uci commit network [5].

The third correction was firewall-zone membership. The initial script
overwrote firewall.lan.network with a concatenated string. OpenWrt
firewall zone network membership is a UCI list. Overwriting it destroys
the list structure. The corrected form is
  uci add_list firewall.@zone[0].network='wlan0' [6].

The fourth correction was the Android STA configuration. A bare
SSID/PSK block is not enough for stable S1G association. The STA profile
now includes proto=RSN, pairwise=CCMP, and ieee80211w=2, which are the
parameters used in working Morse Micro STA examples [7].

The fifth correction was DHCP suppression. In a true Layer-2 bridge,
neither the AP side nor the STA side should run a DHCP server on the
HaLow interface; address assignment belongs to the upstream LAN router.
The scripts now explicitly set ignore=1 on any DHCP section bound to
the HaLow interface.


2. WHERE WE ARE
---------------

The repository is in a working, reviewable state. The current tree is:

  README.txt
  requirements.txt
  openwrt/disable-uci-halow.sh
  openwrt/hostapd_s1g.conf
  openwrt/start-ap.sh
  openwrt/firewall-halow.sh
  openwrt/stop-ap.sh
  openwrt/setup-relayd.sh
  openwrt/disable-dhcp-halow.sh
  android/README-android.txt
  android/check-cdc-ncm.sh

The configuration follows the Gateworks operating-class mapping: US 1 MHz
channel 33 / op_class 68 is 918.5 MHz; US 2 MHz channel 10 / op_class 69
is 907 MHz [1][8]. The OpenWrt bandwidth mapping (20 MHz -> 1 MHz sub-1G,
40 MHz -> 2 MHz sub-1G, 80 MHz -> 4 MHz sub-1G, 160 MHz -> 8 MHz sub-1G)
is documented in the AP configuration file and in the Gateworks wiki [2].

The AP profile uses hw_mode=a, s1g_prim_chwidth=0 for 1 MHz operation,
and s1g_prim_1mhz_chan_index=0. The bridge is configured through UCI
ports, the firewall through uci add_list, and DHCP is suppressed on the
HaLow interface. The relayd path is present for deployments where a
hard Layer-2 bridge is not possible.


3. WHAT TO DO NEXT
------------------

Step 1: Validate the radio on real hardware.
  Run the scripts on the target OpenWrt device with the MM8108 attached.
  Confirm that the PHY appears, that hostapd_s1g starts, and that the
  Android endpoint obtains an address from the upstream DHCP server.
  Use android/check-cdc-ncm.sh for the RD17 path.

Step 2: Confirm the regulatory domain.
  country_code, channel, and op_class must match the deployment region.
  The current file is set to US. Change all three together; an op_class
  that does not match the channel width will be rejected or will operate
  outside the intended regulatory limits [1][8].

Step 3: Harden persistence.
  The current scripts are manual and reviewable. If the deployment must
  survive reboot without operator intervention, move the UCI changes
  into /etc/uci-defaults or a procd init script rather than calling the
  shell scripts at runtime. This keeps the manual s1g tooling while
  letting OpenWrt own the boot sequence.

Step 4: Test the relayd path.
  setup-relayd.sh is included but has not been exercised end-to-end.
  Validate that ARP and DHCP are forwarded correctly between the HaLow
  segment and the upstream LAN when Layer-2 bridging is not possible.

Step 5: Watch upstream driver progress.
  A rewrite of the Morse Micro driver for upstream inclusion was
  discussed in the OpenWrt forum in October 2026, but it lacks features
  present in the Morse Micro fork [9]. Do not migrate to the upstream
  driver until the feature gap is closed. Track the Morse Micro OpenWrt
  fork as the supported path.

Step 6: Do not reintroduce UCI Wi-Fi control for the HaLow radio.
  Gateworks is explicit that UCI should not configure the HaLow
  interface [1][2]. Keep UCI limited to bridge ports, firewall zones,
  and DHCP suppression. If a future OpenWrt release changes this,
  re-evaluate against the Gateworks recommendation and the Morse Micro
  fork before switching.


4. REFERENCES
-------------

[1] Gateworks GW16167 wiki: UCI avoidance, hw_mode=a, channel mapping.
    https://trac.gateworks.com/wiki/expansion/gw16167

[2] Gateworks GW16167 / GW16170 wiki: morse_driver, morse-fw, UCI
    incompatibility, bandwidth mapping.
    https://trac.gateworks.com/wiki/expansion/gw16167?version=51

[3] Gateworks GW16159 wiki: hostapd_s1g.conf example with hw_mode=a.
    https://trac.gateworks.com/wiki/expansion/gw16159

[4] Morse Micro hostapd fork, hostapd_s1g.conf at v1.14.
    https://github.com/MorseMicro/hostap

[5] OpenWrt netifd bridge "ports" migration: uci add_list
    network.@device[-1].ports.
    https://git.openwrt.org/?p=openwrt/staging/neocturne.git;a=commitdiff;h=c8e68dce61140460ff38ac04fa84e57246f8ae63

[6] OpenWrt firewall zone network list semantics: uci add_list
    firewall.@zone[0].network.

[7] Morse Micro community STA examples: proto=RSN, pairwise=CCMP,
    ieee80211w=2.

[8] IEEE 802.11ah-2016, Sub 1 GHz License Exempt Operation.
    ISBN 978-1-5044-3911-4.
    DOI 10.1109/IEEESTD.2017.7920364.

[9] OpenWrt forum, "802.11ah Wi-Fi HaLow - Hardware Questions and
    Recommendations", October 2026.
    https://forum.openwrt.org
