Android Endpoint Connection
===========================

Path A: MM8108-RD17 (driverless CDC-NCM)
-----------------------------------------

Linux names a cdc_ncm interface eth%d when the MAC address is globally
unique (bit 1 of the first octet clear).  drivers/net/usb/cdc_ncm.c
checks (net->dev_addr[0] & 0x02) == 0 with FLAG_ETHER | FLAG_POINTTOPOINT;
the commit message states the name is either usb%d or eth%d based on the
global uniqueness of the MAC address.

Android T (13) matches config_ethernet_iface_regex=eth%d only.
Android U+ (14) includes both usb\d+ and eth%d.  Vendor forks vary.
On builds that match eth%d only, a usbN interface is ignored and
tethering does not enable.

set-global-mac.sh clears the locally administered bit and then renames
usbN -> ethN as a deterministic fallback.  The MAC bit is the primary
mechanism; the rename is the fallback.

Steps:
1. Plug the RD17 into USB-C (OTG).
2. Check the interface name:
       ip -br link
       ./check-cdc-ncm.sh
3. If the interface is usbN and tethering is off:
       ./set-global-mac.sh usb0
4. Verify:
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
        psk="__CHANGEME__"
        key_mgmt=WPA-PSK
    }

Known MM8108 behaviour (release notes):
  - 1 MHz at strong signal: receive degradation.
  - 2 MHz near -73 dBm: receive degradation.
  - Very close range: intermittent association failure.
  - Thermal protection: Tp_on 90 C, Tp_off 85 C (Application Note 56).
