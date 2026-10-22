Wi-Fi HaLow (Sub-1 GHz) OpenWrt Bridge + Android Endpoint
=========================================================

Hardware: Morse Micro MM8108 (or MM6108)
Kernel:   Native Linux mac80211 on OpenWrt
Topology: OpenWrt AP bridged to upstream LAN; Android endpoint as STA


1. HOW WE GOT HERE
------------------

The first iteration assumed OpenWrt UCI could configure the HaLow radio
like any other Wi-Fi radio. That assumption did not survive contact with
the Gateworks documentation, which states that OpenWrt UCI is not fully
compatible with all HaLow features (notably WPA3) and that the HaLow
interface should be driven manually with hostapd_s1g and
wpa_supplicant_s1g rather than through UCI [1].

Correction 1: hw_mode.
The hostapd_s1g configuration must use hw_mode=a. The Gateworks HaLow
expansion-card wikis for the GW16167 and GW16159 both show hw_mode=a in
their hostapd_s1g.conf examples [1][2]. hw_mode=ah is not accepted.

Correction 2: bridge membership.
The first script used "ip link set wlan0 master br-lan". That is not
persistent across reboot or wifi reload. OpenWrt netifd treats bridge
membership as a list named "ports" on the bridge device section, so the
persistent form is:
    uci add_list network.@device[-1].ports='wlan0'
    uci commit network
    /etc/init.d/network reload
This matches the netifd bridge configuration model used in OpenWrt
21.02 and later [3].

Correction 3: firewall-zone membership.
The first script overwrote firewall.lan.network with a concatenated
string. OpenWrt firewall zone network membership is a UCI list. The
persistent form is:
    uci add_list firewall.@zone[0].network='wlan0'
    uci commit firewall
    /etc/init.d/firewall reload
This is the documented OpenWrt UCI list semantics for firewall zones
[4].

Correction 4: Android STA profile.
A bare ssid/psk block is not enough for stable S1G association. The STA
profile now includes proto=RSN, pairwise=CCMP, and ieee80211w=2, which
are the parameters used in working Morse Micro STA examples shared on
the Morse Micro community site [5]. The exact behaviour of a given
Android kernel will vary; these are the values observed to associate
reliably.

Correction 5: DHCP suppression.
In a true Layer-2 bridge, neither the AP side nor the STA side runs a
DHCP server on the HaLow interface. Address assignment belongs to the
upstream LAN router. The scripts now set ignore=1 on any DHCP section
bound to the HaLow interface, which matches the OpenWrt dhcp UCI schema
[4].


2. WHERE WE ARE
---------------

The repository is in a working, reviewable state:

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

Configuration follows the Gateworks operating-class mapping. US 1 MHz
channel 33 / op_class 68 is 918.5 MHz; US 2 MHz channel 10 / op_class 69
is 907 MHz [1][6]. OpenWrt reports the HaLow radio as a generic 5 GHz
radio; the bandwidth mapping is 20 MHz -> 1 MHz sub-1G, 40 MHz -> 2 MHz,
80 MHz -> 4 MHz, 160 MHz -> 8 MHz [1].

The AP profile uses hw_mode=a, s1g_prim_chwidth=0 for 1 MHz operation,
and s1g_prim_1mhz_chan_index=0. Bridge ports, firewall membership, and
DHCP suppression are all done through UCI list operations so they are
persistent. The relayd path is present for deployments where a hard
Layer-2 bridge is not possible.

The formal reference for sub-1 GHz channelisation and operating classes
is IEEE 802.11ah-2016, ISBN 978-1-5044-3911-4 [7].


3. WHAT TO DO NEXT
------------------

Step 1: Validate on real hardware.
  Run the scripts on the target OpenWrt device with the MM8108 attached.
  Confirm the PHY appears, hostapd_s1g starts, and the Android endpoint
  obtains an address from the upstream DHCP server. Use
  android/check-cdc-ncm.sh for the RD17 (CDC-NCM) path.

Step 2: Confirm the regulatory domain.
  country_code, channel, and op_class must match the deployment region.
  The shipped file is set to US (channel 33 / op_class 68). Change all
  three together; an op_class that does not match the channel width is
  rejected or operates outside the intended limits [1][6].

Step 3: Harden persistence.
  The scripts are manual and reviewable by design. If the deployment
  must survive reboot without operator action, move the UCI changes
  into /etc/uci-defaults or a procd init script. This keeps the manual
  s1g tooling while letting OpenWrt own the boot sequence.

Step 4: Test the relayd path.
  setup-relayd.sh is included but has not been exercised end-to-end.
  Validate that ARP and DHCP are forwarded correctly between the HaLow
  segment and the upstream LAN when Layer-2 bridging is not possible.

Step 5: Track the supported driver.
  The Morse Micro OpenWrt fork is the supported path for MM8108 on
  OpenWrt [8]. Do not migrate to any upstream mac80211 driver until
  feature parity is confirmed against the fork's release notes.

Step 6: Do not reintroduce UCI Wi-Fi control for the HaLow radio.
  Gateworks is explicit that UCI should not configure the HaLow
  interface [1]. Keep UCI limited to bridge ports, firewall zones, and
  DHCP suppression. If a future OpenWrt release changes this, re-check
  against the Gateworks guidance and the Morse Micro fork before
  switching.


4. REFERENCES
-------------

[1] Gateworks GW16167 M.2 E-Key 802.11ah (HaLow) radio wiki.
    https://trac.gateworks.com/wiki/expansion/gw16167

[2] Gateworks GW16159 M.2 E-Key 802.11ah (HaLow) radio wiki.
    https://trac.gateworks.com/wiki/expansion/gw16159

[3] OpenWrt netifd bridge configuration model (device sections with
    a "ports" list). See the network configuration documentation at
    https://openwrt.org/docs/guide-user/network/network_configuration

[4] OpenWrt UCI configuration reference for /etc/config/firewall and
    /etc/config/dhcp (list semantics for zone network membership and
    dhcp ignore). See
    https://openwrt.org/docs/guide-user/firewall/firewall_configuration

[5] Morse Micro Community forum, HaLow configuration and MCS
    discussions (STA profiles with proto=RSN, pairwise=CCMP,
    ieee80211w=2).
    https://community.morsemicro.com

[6] Gateworks GW16167 wiki, US channel / operating-class table
    (channel 33 / op_class 68 at 1 MHz; channel 10 / op_class 69 at
    2 MHz). Same page as [1].

[7] IEEE Standard for Information technology--Telecommunications and
    information exchange between systems--Local and metropolitan area
    networks--Specific requirements--Part 11: Wireless LAN Medium
    Access Control (MAC) and Physical Layer (PHY) Specifications--
    Amendment 2: Sub 1 GHz License Exempt Operation.
    IEEE 802.11ah-2016. ISBN 978-1-5044-3911-4.
    DOI 10.1109/IEEESTD.2017.7920364.

[8] Morse Micro OpenWrt fork (supported build environment for MM8108
    packages: mm8108-firmware, kmod-mm8108_usb, hostapd_s1g,
    wpa_supplicant_s1g, libwpa_client_s1g, morse_cli).
    https://github.com/MorseMicro/openwrt
