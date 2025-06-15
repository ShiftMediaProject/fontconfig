#! /bin/bash

set -ex

# Disable fedora-cisco-openh264 repo to avoid signature verification fail during
# signature migration for new release.
# We don't need it.
dnf --version|grep dnf5 > /dev/null || ret=$?
if [[ $ret -eq 0 ]]; then
  dnf -y install dnf5-plugins
  dnf -y config-manager setopt fedora-cisco-openh264.enabled=0
else
  dnf -y install dnf-plugins-core
  dnf -y config-manager --set-disabled fedora-cisco-openh264
fi

# workaround to avoid conflict between systemd and systemd-standalone-sysusers
dnf -y swap systemd-standalone-sysusers systemd
dnf -y install wine
