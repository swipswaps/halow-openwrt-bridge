Wi-Fi HaLow (Sub-1 GHz) OpenWrt Bridge + Android Endpoint
=========================================================

1. SECURITY ADVISORY (MANDATORY)
---------------------------------

CVE-2026-7764 / GHSA-7C7H-P74X-W3H5
Out-of-bounds read in morse.ko Vendor IE processing.
morse_vendor_find_vendor_ie() does not validate IE length against the
expected structure size.  A crafted 802.11ah beacon or probe response
can cause a heap out-of-bounds read of up to 9 bytes, disclosing kernel
heap memory or causing a kernel oops/panic.
CVSS 3.1: 6.8 (AV:L/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:H).  Attack vector is
local/proximity radio, not network-routable.
Fixed in HaLowLink 2 software 2.11.12 and later.
Advisory: https://github.com/advisories/GHSA-7C7H-P74X-W3H5
Action: upgrade morse.ko and firmware to 2.11.12+.

2. DEFAULT PSK
---------------

Earlier revisions shipped wpa_passphrase=ChangeMe_HaLow_2026.  That value
is in git history and must be treated as public.  Rotate it on both ends
if you copied a configuration from history.
hostapd_s1g.conf ships __CHANGEME__, and start-ap.sh rejects any
passphrase that is empty or contains CHANGEME.

3. THERMAL PROTECTION (MM8108)
-------------------------------

The MM8108 PA delivers up to 26 dBm.  Over-temperature protection
disables the transmitter at the datasheet threshold.  Public summaries
cite approximately 85 C; verify against the MM8108 datasheet for the
specific silicon revision.  Ensure enclosure airflow and duty-cycle
headroom; avoid sustained 26 dBm in sealed enclosures.

4. REGIONAL op_class TABLE
----------------------------

  Region  width  op_class
  US      1 MHz  68
  US      2 MHz  69
  EU      1 MHz  66
  EU      2 MHz  67
  AU      1 MHz  68
  AU      2 MHz  69
  JP      1 MHz  68
  JP      2 MHz  69

start-ap.sh validates the tuple and rejects mismatches with exit 5.

5. S1G CAPABILITY FLAGS
------------------------

s1g_capab=[SHORT-GI-ALL] is the specification default and matches the
Gateworks GW16167 and GW16159 examples.
Source: MorseMicro/hostapd_s1g_configuration.md v1.14.

6. EAPOL AND NAS FIELDS
------------------------

hostapd_s1g.conf includes eapol_key_index_workaround=0 and
own_ip_addr=127.0.0.1, both present in every Gateworks S1G AP example.
eapol_key_index_workaround controls the EAPOL-Key index bit associated
with station-side CVE-2017-13087; own_ip_addr is the NAS-IP-Address used
by RADIUS and accounting.

7. DISABLING UCI FOR THE HaLOW RADIO
-------------------------------------

disable-uci-halow.sh requires HALOW_RADIO (for example radio1).  It does
not disable every radioN.  Run it as:
    HALOW_RADIO=radio1 ./openwrt/disable-uci-halow.sh

uci-defaults-halow does not disable any radioN.

8. RELAYD CAVEAT
-----------------

setup-relayd.sh writes a modern relay interface:
    network.repeater_bridge.proto=relay
    network.repeater_bridge.ipaddr=192.168.4.1
    network.repeater_bridge.network='br-lan wlan0'
relayd is not a full Layer-2 bridge.  DHCP, mDNS, and upstream throughput
may not match a wired bridge.  WDS or 802.11s is preferred when both ends
are controllable.

9. PROCESS MODEL AND RESPAWN
-----------------------------

start-ap.sh holds /var/run/halow-ap.lock with flock so two invocations
cannot race.  It execs hostapd_s1g in the foreground; procd tracks the
real daemon.

halow-ap.init uses respawn 3600 5 5 (threshold 3600 s, timeout 5 s,
retry 5).  This is the procd default, chosen deliberately: a permanent
configuration error (for example an invalid regulatory tuple, exit 5)
is retried five times and then left visible in logread instead of
restarting forever.  OpenWrt's own hostapd init uses 3600 1 0 (infinite
retries) because hostapd failures are usually transient; a validation
failure is not, so bounded retries are correct here.

10. ANDROID CDC-NCM
--------------------

Linux names a cdc_ncm interface eth%d when the globally unique bit is
clear.  drivers/net/usb/cdc_ncm.c checks
    if ((dev->driver_info->flags & FLAG_ETHER) != 0 &&
        ((dev->driver_info->flags & FLAG_POINTTOPOINT) == 0 ||
         (net->dev_addr[0] & 0x02) == 0))
            strcpy(net->name, "eth%d");
The commit message for this change states that the interface naming is
either usb%d or eth%d based on the global uniqueness of the MAC address.
Bit 1 of the first octet is the locally administered bit.  Clearing it
makes the MAC globally unique, and the kernel assigns ethN at probe.

Android's EthernetTracker historically matched eth\d only
(config_ethernet_iface_regex=eth\d).  A 2023 Connectivity CL changed the
default to include usb\d+ and eth%d on Android U+ (14); Android T (13)
continues to match eth%d only.  Vendor forks vary.  On builds that
match eth\d only, a usbN interface is ignored and tethering does not
enable.

set-global-mac.sh clears the locally administered bit and then renames
usbN -> ethN as a deterministic fallback for interfaces that have
already probed.  The MAC bit is the primary mechanism; the rename is
the fallback.

11. LINT GATE
--------------

lint.sh runs sh -n and, when available, shellcheck -s sh on every script.
openwrt/halow-ap.init is listed explicitly because its .init extension
is not matched by the openwrt/*.sh glob.  SC2034 is excluded only for
halow-ap.init, where START, STOP, and USE_PROCD are read by rc.common
by indirection.  push.sh runs lint.sh and aborts on failure unless
LINT_OVERRIDE=1.

12. LICENSE
------------

SPDX-License-Identifier: GPL-2.0-only.
LICENSE is a pointer.  Run ./fetch-license.sh to populate it with the
verbatim GPL-2.0 text before tagging or distributing.  A tag without
the fetched text is not compliant with GPL-2.0 §1.

13. FILES
----------

README.txt
CHANGELOG.txt
LICENSE
requirements.txt
.gitignore
lint.sh
push.sh
fetch-license.sh
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

14. REFERENCES
--------------

CVE-2026-7764 (GHSA-7C7H-P74X-W3H5):
https://github.com/advisories/GHSA-7C7H-P74X-W3H5

Linux cdc_ncm eth%d naming (commit c1a3d406):
https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=c1a3d4067309451e68c33dbd356032549cc0bd8e

AOSP Connectivity CL: config_ethernet_iface_regex on Android U+:
https://gitea.com/ /merge/41d7e77128

Gateworks GW16167 S1G example:
https://trac.gateworks.com/wiki/expansion/gw16167?format=txt

Morse Micro hostapd_s1g configuration specification:
https://github.com/MorseMicro/hostap/blob/v1.14/hostapd_s1g_configuration.md

OpenWrt hostapd respawn commit (3600 1 0):
https://git.openwrt.org/openwrt/staging/chunkeey/commit/?id=ceb612e463fc0dc6fbd7be66dc1a244544213c24

OpenWrt procd respawn parameters (threshold timeout retry):
https://mintlify.wiki/openwrt/openwrt/system/procd

BusyBox flock enabled by default on OpenWrt:
https://git.openwrt.org/?p=openwrt/openwrt.git;a=commit;h=2277cd1249

GPL-2.0 verbatim text:
https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
