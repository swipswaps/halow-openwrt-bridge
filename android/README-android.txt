Android Endpoint Connection
===========================

Path A: MM8108-RD17 (driverless CDC-NCM)
-----------------------------------------

If the interface is usbX and tethering does not enable:

    ./check-cdc-ncm.sh
    # if LOCAL_BIT=1:
    ./set-global-mac.sh usb0
    # interface should rename to eth0; tethering becomes available

The change is lost on replug.  For persistence, add a udev rule:
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="usb0", \
      RUN+="/sbin/ip link set %k address <global-mac>"

Path B: MM8108-RD09 (native driver)
------------------------------------

STA profile includes proto=RSN, pairwise=CCMP, ieee80211w=2.

Known MM8108 behaviour (release notes 2.11.12):
  - 1 MHz strong signal: receive degradation.
  - 2 MHz near -73 dBm: receive degradation.
  - Very close range: intermittent association failure.

If throughput collapses at close range, reduce bandwidth to 1 MHz
before suspecting hostapd.  See openwrt/tune-morse.sh.
