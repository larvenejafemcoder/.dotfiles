#!/usr/bin/env python3
"""Distro detection and management utilities."""

import shutil
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Dict, Optional, Tuple


class DistroFamily(Enum):
    ARCH = "arch"
    DEBIAN = "debian"
    UBUNTU = "ubuntu"
    FEDORA = "fedora"
    RHEL = "rhel"
    OPENSUSE = "opensuse"
    GENTOO = "gentoo"
    UNKNOWN = "unknown"


@dataclass
class DistroInfo:
    name: str
    family: DistroFamily
    version: str
    version_id: str
    codename: str
    package_manager: str
    package_manager_cmd: str
    aur_helper: Optional[str] = None
    flatpak_available: bool = False

    @property
    def is_arch_based(self) -> bool:
        return self.family == DistroFamily.ARCH

    @property
    def is_debian_based(self) -> bool:
        return self.family in (DistroFamily.DEBIAN, DistroFamily.UBUNTU)

    @property
    def is_redhat_based(self) -> bool:
        return self.family in (DistroFamily.FEDORA, DistroFamily.RHEL)


class DistroDetector:
    COMPONENT_AVAILABILITY: Dict[DistroFamily, Dict[str, str]] = {
        DistroFamily.ARCH: {
            "docker": "docker (AUR or community)",
            "kvm": "libvirt (extra/libvirt)",
            "hyprland": "hyprland (AUR)",
            "nvidia_drivers": "nvidia-dkms (AUR)",
        },
        DistroFamily.DEBIAN: {
            "docker": "docker.io (older) or Docker CE repo",
            "kvm": "qemu-kvm + libvirt",
            "hyprland": "Not available (need backports/build)",
            "nvidia_drivers": "nvidia-driver",
        },
        DistroFamily.UBUNTU: {
            "docker": "docker.io or Docker CE repo",
            "kvm": "qemu-kvm + libvirt",
            "hyprland": "Not available (use Wayland other options)",
            "nvidia_drivers": "nvidia-driver-*",
        },
        DistroFamily.FEDORA: {
            "docker": "docker (RPM Fusion) or podman-docker",
            "kvm": "virt-manager + libvirt",
            "hyprland": "Copr repo available",
            "nvidia_drivers": "akmod-nvidia (RPM Fusion)",
        },
    }

    @classmethod
    def detect(cls) -> DistroInfo:
        os_release = Path("/etc/os-release")
        if not os_release.exists():
            return cls._fallback_detection()

        info = {}
        with open(os_release) as f:
            for line in f:
                if "=" in line:
                    key, value = line.strip().split("=", 1)
                    info[key] = value.strip('"')

        name = info.get("NAME", "Unknown").lower()
        version = info.get("VERSION", "")
        version_id = info.get("VERSION_ID", "")
        codename = info.get("VERSION_CODENAME", info.get("UBUNTU_CODENAME", ""))

        if "arch" in name:
            family = DistroFamily.ARCH
            pm = "pacman"
            pm_cmd = "pacman -S"
            aur_helper = cls._detect_aur_helper()
        elif "ubuntu" in name:
            family = DistroFamily.UBUNTU
            pm = "apt"
            pm_cmd = "apt install -y"
        elif "debian" in name:
            family = DistroFamily.DEBIAN
            pm = "apt"
            pm_cmd = "apt install -y"
        elif "fedora" in name:
            family = DistroFamily.FEDORA
            pm = "dnf"
            pm_cmd = "dnf install -y"
        elif "rhel" in name or "red hat" in name:
            family = DistroFamily.RHEL
            pm = "dnf"
            pm_cmd = "dnf install -y"
        elif "opensuse" in name or "suse" in name:
            family = DistroFamily.OPENSUSE
            pm = "zypper"
            pm_cmd = "zypper install -y"
        elif "gentoo" in name:
            family = DistroFamily.GENTOO
            pm = "emerge"
            pm_cmd = "emerge"
        else:
            family = DistroFamily.UNKNOWN
            pm = cls._detect_package_manager()
            pm_cmd = f"{pm} install" if pm != "unknown" else "unknown"
            aur_helper = None

        flatpak_available = shutil.which("flatpak") is not None

        return DistroInfo(
            name=name,
            family=family,
            version=version,
            version_id=version_id,
            codename=codename,
            package_manager=pm,
            package_manager_cmd=pm_cmd,
            aur_helper=aur_helper,
            flatpak_available=flatpak_available,
        )

    @classmethod
    def _detect_aur_helper(cls) -> Optional[str]:
        for helper in ["paru", "yay", "pikaur", "trizen"]:
            if shutil.which(helper):
                return helper
        return None

    @classmethod
    def _detect_package_manager(cls) -> str:
        for pm in ["apt", "pacman", "dnf", "yum", "zypper", "emerge", "xbps"]:
            if shutil.which(pm):
                return pm
        return "unknown"

    @classmethod
    def _fallback_detection(cls) -> DistroInfo:
        pm = cls._detect_package_manager()
        return DistroInfo(
            name="unknown",
            family=DistroFamily.UNKNOWN,
            version="", version_id="", codename="",
            package_manager=pm,
            package_manager_cmd=f"{pm} install" if pm != "unknown" else "unknown",
        )

    @classmethod
    def get_component_availability(cls, distro: DistroInfo, component_name: str) -> Tuple[bool, str]:
        if distro.family in cls.COMPONENT_AVAILABILITY:
            family_info = cls.COMPONENT_AVAILABILITY[distro.family]
            if component_name in family_info:
                return True, family_info[component_name]
        return True, f"Available via {distro.package_manager}"
