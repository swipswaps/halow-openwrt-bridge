Android Endpoint Connection
===========================

Path A: MM8108-RD17 (driverless CDC-NCM)
-----------------------------------------

1. Plug the RD17 into USB-C (OTG).
2. It appears as a wired Ethernet interface.
3. Android obtains an IP from the upstream LAN DHCP.
4. No DHCP server should run on the HaLow link itself.

Check interface:
    ip -br link
    dmesg | grep -i -E 'cdc_ncm|cdc_ether'


Path B: MM8108-RD09 (native driver)
------------------------------------

1. Build the Morse Micro driver against the device kernel headers.
2. insmod morse.ko country=US
3. Run wpa_supplicant_s1g in STA mode.

Minimal wpa_supplicant_s1g.conf (WPA2-PSK, CORRECTED):
-------------------------------------------------------

    country=US
    ctrl_interface=/var/run/wpa_supplicant_s1g
    proto=RSN
    pairwise=CCMP
    ieee80211w=2
    network={
        ssid="HaLow-Bridge"
        psk="ChangeMe_HaLow_2026"
        key_mgmt=WPA-PSK
    }

The proto=RSN, pairwise=CCMP, and ieee80211w=2 lines are required for
stable S1G association.  Without them the STA may associate but drop
intermittently.

Minimal WPA3-SAE variant:

    country=US
    ctrl_interface=/var/run/wpa_supplicant_s1g
    proto=RSN
    pairwise=CCMP
    ieee80211w=2
    pmf=2
    sae_pwe=1
    network={
        ssid="HaLow-Bridge"
        sae_password="ChangeMe_HaLow_2026"
        key_mgmt=SAE
    }


Bridge mode note
----------------

AP side: wlan0 is a port of br-lan.  No IP on wlan0.  DHCP not run on it.
STA side: IP comes from upstream LAN DHCP via the bridge.

If Layer-2 bridging is impossible, use setup-relayd.sh on OpenWrt.
relayd forwards ARP and DHCP without a hard bridge.
