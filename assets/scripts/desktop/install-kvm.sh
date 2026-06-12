#!/usr/bin/env bash

set -e

echo "=== KVM Workstation Bootstrap ==="

sudo apt update

sudo apt install -y \
qemu-kvm \
qemu-system \
qemu-utils \
libvirt-daemon-system \
libvirt-clients \
virt-manager \
virtinst \
virt-viewer \
bridge-utils \
ovmf \
dnsmasq-base \
spice-vdagent \
cpu-checker \
libguestfs-tools \
guestfs-tools \
cloud-image-utils \
genisoimage \
cockpit \
cockpit-machines \
btop \
fastfetch \
curl \
wget \
git

sudo systemctl enable --now libvirtd
sudo systemctl enable --now cockpit.socket

sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER

sudo virsh net-autostart default || true
sudo virsh net-start default || true

mkdir -p ~/VMs

echo
echo "================================="
echo " KVM installation complete"
echo "================================="
echo
echo "Virt-Manager: virt-manager"
echo "Cockpit: https://localhost:9090"
echo
echo "Log out and back in for group changes."
