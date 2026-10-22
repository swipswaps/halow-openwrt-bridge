Android Endpoint Connection
===========================

Path A: MM8108-RD17 (driverless CDC-NCM)
-----------------------------------------

1. Plug the RD17 into USB-C (OTG).
2. It appears as a wired Ethernet interface.  Depending on the MAC
   address, the interface may be named usbX or ethX.
3. Android should obtain an IP from the upstream LAN DHCP.
4. No DHCP server runs on the HaLow link itself.

Interface naming caveat:
Android chooses usbX when the MAC address has the locally-administered
bit set (bit 1 of the first octet).  A globally assigned MAC makes the
interface appear as ethX, which the Android Ethernet service handles
more reliably.  Run ./check-cdc-ncm.sh and inspect first_octet.

If the interface appears but no IP is assigned:
    dumpsys ethernet
    settings get global tether_enable


Path B: MM8108-RD09 (native driver)
------------------------------------

1. Build the Morse Micro driver against the device kernel headers.
2. insmod morse.ko country=US
3. wpa_supplicant_s1g -i wlan0 -c /path/to/wpa_supplicant_s1g.conf

Minimal STA profile (WPA2-PSK):

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


Known MM8108 behaviour (from Morse Micro release notes)
--------------------------------------------------------

- 1 MHz at strong signal: receive degradation.
- 2 MHz near -73 dBm RSSI: receive degradation.
- Very close range: intermittent STA association failure.
