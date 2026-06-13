"""Component manager - dependency resolution, package checking, backups."""

import logging
import shutil
import subprocess
from datetime import datetime
from pathlib import Path

from .components_db import check_conflicts, get_component, resolve_dependencies


class DependencyResolver:
    """Resolve dependencies and detect conflicts."""

    def resolve(self, selected: list[str]) -> list[str]:
        return resolve_dependencies(selected)

    def conflicts(self, selected: list[str]) -> list[tuple[str, str]]:
        return check_conflicts(selected)


class PackageChecker:
    """Check for required system packages."""

    @staticmethod
    def check(package_spec: str) -> bool:
        name = package_spec.split(">=")[0].split("==")[0].strip()
        if shutil.which(name):
            return True
        try:
            result = subprocess.run(
                ["dpkg", "-l", name],
                capture_output=True, text=True,
            )
            if result.returncode == 0 and "ii" in result.stdout:
                return True
        except FileNotFoundError:
            pass
        try:
            result = subprocess.run(
                ["pacman", "-Q", name],
                capture_output=True, text=True,
            )
            return result.returncode == 0
        except FileNotFoundError:
            pass
        return False

    @staticmethod
    def check_many(packages: list[str]) -> dict[str, bool]:
        return {pkg: PackageChecker.check(pkg) for pkg in packages}

    @staticmethod
    def install_command(missing: list[str]) -> str:
        if not missing:
            return ""
        if shutil.which("apt"):
            return f"sudo apt install {' '.join(missing)}"
        if shutil.which("pacman"):
            return f"sudo pacman -S {' '.join(missing)}"
        if shutil.which("dnf"):
            return f"sudo dnf install {' '.join(missing)}"
        return f"Install: {' '.join(missing)}"


class BackupManager:
    """Backup dotfiles before overwriting."""

    def __init__(self, backup_dir: Path | None = None) -> None:
        if backup_dir is None:
            ts = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_dir = Path.home() / ".dotfiles_backup" / ts
        self.backup_dir = backup_dir
        self.backup_dir.mkdir(parents=True, exist_ok=True)
        self.manifest: dict[str, str] = {}

    def backup(self, path: Path) -> bool:
        if not path.exists():
            return True
        try:
            dest = self.backup_dir / path.name
            if path.is_symlink():
                dest.symlink_to(path.readlink())
            else:
                shutil.copy2(path, dest)
            self.manifest[str(path)] = str(dest)
            return True
        except Exception as e:
            logging.error("Backup failed for %s: %s", path, e)
            return False

    def restore(self) -> bool:
        try:
            for original, backup in self.manifest.items():
                orig = Path(original)
                bak = Path(backup)
                if orig.exists():
                    orig.unlink()
                if bak.exists():
                    shutil.move(str(bak), str(orig))
            return True
        except Exception as e:
            logging.error("Restore failed: %s", e)
            return False

    def total_size_kb(self) -> int:
        return sum(
            Path(b).stat().st_size for b in self.manifest.values()
        ) // 1024
