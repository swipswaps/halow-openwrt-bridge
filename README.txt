Wi-Fi HaLow (Sub-1 GHz) OpenWrt Bridge + Android Endpoint
=========================================================

Native Linux mac80211 on OpenWrt with Morse Micro MM8108.
1 - 4 Mbps, 1.5 - 10 miles line-of-sight.


FIXES APPLIED IN THIS VERSION
-----------------------------

1.  hostapd_s1g.conf now uses hw_mode=a (NOT hw_mode=ah).
    The Morse Micro / Gateworks example confirms hw_mode=a is the
    correct value for S1G hostapd.

2.  s1g_prim_chwidth=0 now correctly selects 1 MHz operation.
    Previous value 1 selected 2 MHz.
    Mapping: 0 = 1 MHz, 1 = 2 MHz.

3.  Bridge membership uses UCI (uci add_list network.@device[-1].ports)
    instead of raw ip link set master, so it survives reboot and
    wifi reload.

4.  Firewall zone membership uses uci add_list firewall.@zone[0].network
    instead of overwriting the string value of firewall.lan.network.

5.  Android wpa_supplicant_s1g STA config includes proto=RSN,
    pairwise=CCMP, ieee80211w=2 for stable WPA2 association.

6.  killall -q is used so other hostapd_s1g instances are not killed.

7.  The HaLow interface name is discovered dynamically from the PHY
    instead of assuming wlan0.

8.  DHCP is explicitly disabled on the HaLow interface in bridge mode.

9.  A relayd alternative script is included for deployments where
    Layer-2 bridging is not possible.


TOPOLOGY
--------

    [Android STA] --- 802.11ah sub-1 GHz --- [OpenWrt AP]
                                                 |
                                             br-lan
                                                 |
                                          upstream LAN DHCP


FILES
-----

README.txt                       This file.
requirements.txt                 Host build dependencies.
openwrt/disable-uci-halow.sh     Disables UCI radio control.
openwrt/hostapd_s1g.conf         AP configuration (1 MHz, hw_mode=a).
openwrt/start-ap.sh              Starts hostapd_s1g, adds port to br-lan via UCI.
openwrt/firewall-halow.sh        Adds HaLow netdev to LAN firewall zone via UCI.
openwrt/stop-ap.sh               Stops AP, removes UCI bridge port, kills safely.
openwrt/setup-relayd.sh          relayd / proxy-ARP alternative to bridging.
openwrt/disable-dhcp-halow.sh    Ensures no DHCP server runs on the HaLow iface.
android/README-android.txt       Android endpoint instructions.
android/check-cdc-ncm.sh         CDC-NCM detection script.


QUICK START
-----------

1.  Build or flash OpenWrt with the packages in requirements.txt.

2.  Copy the openwrt/ directory to the device.

3.  Run:
        ./openwrt/disable-uci-halow.sh

4.  Edit openwrt/hostapd_s1g.conf:
        country_code, channel, op_class, ssid, wpa_passphrase.

5.  Run:
        ./openwrt/start-ap.sh

6.  If using true Layer-2 bridge:
        ./openwrt/firewall-halow.sh
        ./openwrt/disable-dhcp-halow.sh

7.  If Layer-2 bridging is not possible:
        ./openwrt/setup-relayd.sh

8.  Connect Android via RD17 (CDC-NCM) or RD09 (native driver).
    See android/README-android.txt.


CRITICAL CONFIG NOTES
---------------------

hw_mode MUST be "a", not "ah".

s1g_prim_chwidth:
  0 = 1 MHz  (this configuration)
  1 = 2 MHz

op_class is mandatory for S1G.  US 1 MHz example:
  channel=33, op_class=68

OpenWrt bandwidth mapping:
  20 MHz -> 1 MHz sub-1G
  40 MHz -> 2 MHz sub-1G
  80 MHz -> 4 MHz sub-1G
  160 MHz -> 8 MHz sub-1G


REFERENCES
----------

Gateworks GW16159 wiki (hw_mode=a, op_class, s1g_prim_chwidth).
Morse Micro hostapd_s1g configuration specification (GitHub hostap v1.14).
Morse Micro OpenWrt fork: https://github.com/MorseMicro/openwrt
Morse Micro wpa_supplicant_s1g STA examples (proto=RSN, pairwise=CCMP).
OpenWrt UCI network and firewall list syntax.
