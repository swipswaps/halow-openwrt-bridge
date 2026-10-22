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

Morse Micro Application Note 56 (MM8108 Thermal Protection Mechanism)
states, for firmware 1.17.9:
  Tp_on  = 90 C  (transmitter disabled)
  Tp_off = 85 C  (transmitter re-enabled)
Gateworks notes the transmitter is disabled once the die reaches 85 C
internally.  Ensure enclosure airflow and duty-cycle headroom; avoid
sustained 26 dBm operation in sealed enclosures.
Run `tune-morse.sh thermal` for the on-device reminder.

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

8. RELAYD ALTERNATIVE (CAVEAT)
------------------------------

setup-relayd.sh writes a modern relay interface:
    network.repeater_bridge=interface
    network.repeater_bridge.proto=relay
    network.repeater_bridge.ipaddr=192.168.4.1
    network.repeater_bridge.network=br-lan
    network.repeater_bridge.network=wlan0

The network option is a UCI list, not a space-separated string.  relayd
validates it as list(string) and reads it with config_get, which expects
multiple list entries.  The script uses uci set for the first element
and uci add_list for the second, which is idempotent across re-runs.

The relay interface is not instantiated until netifd processes the
configuration, so the script runs /etc/init.d/network reload before
starting relayd.

relayd is installed with opkg on releases that use opkg, and with apk on
OpenWrt 24.10+ where apk is the package manager.

Caveat: relayd is not a full Layer-2 bridge.  DHCP, mDNS, and upstream
throughput may not match a wired bridge.  WDS or 802.11s is preferred
when both ends are controllable.

9. PROCESS MODEL AND RESPAWN
-----------------------------

start-ap.sh holds /var/run/halow-ap.lock with flock so two invocations
cannot race.  It execs hostapd_s1g in the foreground; procd tracks the
real daemon.

halow-ap.init uses respawn 3600 5 5 (threshold 3600 s, timeout 5 s,
retry 5), which is the procd default.  A permanent configuration error
(for example an invalid regulatory tuple, exit 5) is retried five times
and then left visible in logread instead of restarting forever.
OpenWrt's own hostapd init uses 3600 1 0 (infinite retries) specifically
to avoid procd classifying a transient daemon restart as a crash loop;
a validation failure is not transient, so bounded retries are correct
here.

10. ANDROID CDC-NCM
--------------------

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

11. LINT GATE
--------------

lint.sh runs sh -n and, when available, shellcheck -s sh on every script.
openwrt/halow-ap.init is listed explicitly because its .init extension
is not matched by the openwrt/*.sh glob.  SC2034 is excluded only for
halow-ap.init, where START, STOP, and USE_PROCD are read by rc.common by
indirection.  push.sh runs lint.sh and aborts on failure unless
LINT_OVERRIDE=1.

12. LICENSE
------------

SPDX-License-Identifier: GPL-2.0-only.
fetch-license.sh populates LICENSE with the verbatim GPL-2.0 text and
validates the download before replacing the pointer.  push.sh refuses
to push if LICENSE does not contain the full text, so a tagged release
cannot be non-compliant by omission.

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

GHSA-7C7H-P74X-W3H5 (CVE-2026-7764):
https://github.com/advisories/GHSA-7C7H-P74X-W3H5

Linux cdc_ncm eth%d naming:
"net: cdc_ncm: switch to eth%d interface naming" (drivers/net/usb/cdc_ncm.c)

AOSP Connectivity CL 41d7e77128 ("Include both eth%d and usb%d ethernet
interfaces on U+"):
https://android.googlesource.com/platform/packages/modules/Connectivity/+/refs/heads/main

Morse Micro hostapd_s1g configuration specification:
https://github.com/MorseMicro/hostap/blob/v1.14/hostapd_s1g_configuration.md

Gateworks GW16167 wiki:
https://trac.gateworks.com/wiki/expansion/gw16167

Morse Micro Application Note 56, MM8108 Thermal Protection Mechanism:
https://www.morsemicro.com/

OpenWrt procd init scripts:
https://openwrt.org/docs/guide-developer/procd-init-scripts

OpenWrt hostapd respawn commit (3600 1 0):
https://git.openwrt.org/openwrt/staging/chunkeey/commit/?id=ceb612e463fc0dc6fbd7be66dc1a244544213c24

relayd UCI validation (network:list(string), ipaddr):
package/network/services/relayd/files/relay.sh, OpenWrt

GPL-2.0 verbatim text:
https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
