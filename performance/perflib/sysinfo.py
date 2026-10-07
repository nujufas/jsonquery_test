"""What is known about the machine a run was made on, kept with its results so that a later run can
tell whether it is comparable. Nothing in it names a person or a computer: no user name, no host
name, no paths."""

from __future__ import annotations

import hashlib
import os
import platform
import re
import shutil
import subprocess
import time
from pathlib import Path
from typing import Dict, List, Optional


def _read(path: str) -> Optional[str]:
    try:
        return Path(path).read_text().strip()
    except OSError:
        return None


def _run(*cmd: str) -> Optional[str]:
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=20)
    except (OSError, subprocess.SubprocessError):
        return None
    return out.stdout.strip() if out.returncode == 0 else None


def _meminfo() -> Dict[str, int]:
    """/proc/meminfo, in MiB."""
    info: Dict[str, int] = {}
    text = _read("/proc/meminfo") or ""
    for line in text.splitlines():
        match = re.match(r"(\w+):\s+(\d+)\s*kB", line)
        if match:
            info[match.group(1)] = int(match.group(2)) // 1024
    return info


def memory_state() -> Dict[str, object]:
    """How much memory there is to use right now, and how busy the machine is."""
    mem = _meminfo()
    load = os.getloadavg() if hasattr(os, "getloadavg") else (0.0, 0.0, 0.0)
    return {
        "loadavg": [round(x, 2) for x in load],
        "mem_available_mib": mem.get("MemAvailable"),
        "mem_free_mib": mem.get("MemFree"),
        "page_cache_mib": mem.get("Cached"),
        "swap_used_mib": (mem.get("SwapTotal", 0) - mem.get("SwapFree", 0)) if "SwapTotal" in mem else None,
    }


def _cpu_model() -> str:
    text = _read("/proc/cpuinfo") or ""
    for line in text.splitlines():
        if line.lower().startswith("model name"):
            return line.split(":", 1)[1].strip()
    return platform.processor() or "unknown"


def _lscpu() -> Dict[str, str]:
    out = _run("lscpu") or ""
    fields: Dict[str, str] = {}
    for line in out.splitlines():
        if ":" in line:
            key, _, value = line.partition(":")
            fields[key.strip()] = value.strip()
    return fields


def _cpu_freq(name: str) -> Optional[int]:
    text = _read(f"/sys/devices/system/cpu/cpu0/cpufreq/{name}")
    return int(text) // 1000 if text and text.isdigit() else None


def _distro() -> str:
    text = _read("/etc/os-release") or ""
    for line in text.splitlines():
        if line.startswith("PRETTY_NAME="):
            return line.split("=", 1)[1].strip().strip('"')
    return platform.system()


def _block_device(path: Path) -> Dict[str, object]:
    """The file system and disk the datasets are on: what reads of a big file are limited by."""
    info: Dict[str, object] = {"fs": None, "device": None, "rotational": None, "model": None}
    out = _run("findmnt", "-n", "-o", "SOURCE,FSTYPE", "-T", str(path))
    if not out:
        return info
    parts = out.split()
    if len(parts) < 2:
        return info
    source, info["fs"] = parts[0], parts[1]
    # The disk a partition is on (/dev/nvme0n1p3 -> nvme0n1); a device that is no partition is the disk.
    parent = (_run("lsblk", "-no", "pkname", source) or "").splitlines()
    disk = parent[0].strip() if parent and parent[0].strip() else os.path.basename(source)
    info["device"] = disk
    rotational = _read(f"/sys/block/{disk}/queue/rotational")
    info["rotational"] = {"0": False, "1": True}.get(rotational or "")
    info["model"] = _read(f"/sys/block/{disk}/device/model")
    return info


def _thp() -> Optional[str]:
    """Transparent huge pages: `[madvise]` in the kernel's list is `madvise`."""
    match = re.search(r"\[(\w+)\]", _read("/sys/kernel/mm/transparent_hugepage/enabled") or "")
    return match.group(1) if match else None


def machine_fingerprint(machine: Dict[str, object]) -> str:
    """A short id of the hardware: the same on the same machine, whatever is installed on it, so that a
    comparison can say when two runs were not made on one."""
    basis = "|".join(str(machine.get(k)) for k in ("cpu_model", "cpu_threads", "ram_total_gib"))
    return hashlib.sha256(basis.encode()).hexdigest()[:12]


def collect(data_dir: Path, label: Optional[str] = None) -> Dict[str, object]:
    lscpu = _lscpu()
    mem = _meminfo()
    machine: Dict[str, object] = {
        "label": label,
        "cpu_model": _cpu_model(),
        "cpu_threads": os.cpu_count(),
        "cpu_cores": (int(lscpu["Core(s) per socket"]) * int(lscpu.get("Socket(s)", "1"))
                      if "Core(s) per socket" in lscpu else None),
        "cpu_max_mhz": _cpu_freq("cpuinfo_max_freq"),
        "cpu_min_mhz": _cpu_freq("cpuinfo_min_freq"),
        "cpu_governor": _read("/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"),
        "turbo_disabled": _read("/sys/devices/system/cpu/intel_pstate/no_turbo"),
        "cpu_l2_cache": lscpu.get("L2 cache"),
        "cpu_l3_cache": lscpu.get("L3 cache"),
        "ram_total_mib": mem.get("MemTotal"),
        "ram_total_gib": round((mem.get("MemTotal") or 0) / 1024),
        "swap_total_mib": mem.get("SwapTotal"),
    }
    machine["fingerprint"] = machine_fingerprint(machine)
    return {
        "machine": machine,
        "os": {
            "system": platform.system(),
            "distro": _distro(),
            "kernel": platform.release(),
            "arch": platform.machine(),
            "thp": _thp(),
            "swappiness": _read("/proc/sys/vm/swappiness"),
            "overcommit_memory": _read("/proc/sys/vm/overcommit_memory"),
        },
        "storage": _block_device(data_dir),
        "toolchain": {
            "rustc": _run("rustc", "-V"),
            "cargo": _run("cargo", "-V"),
            "python": platform.python_version(),
            "systemd_run": shutil.which("systemd-run") is not None,
        },
        "state_at_start": memory_state(),
        "captured_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    }


def describe(system: Dict[str, object]) -> str:
    """One line on the machine, for a report."""
    machine = system["machine"]
    return "{cpu}, {threads} threads, {ram} GiB RAM, {os}, kernel {kernel}".format(
        cpu=machine["cpu_model"], threads=machine["cpu_threads"], ram=machine["ram_total_gib"],
        os=system["os"]["distro"], kernel=system["os"]["kernel"],  # type: ignore[index]
    )
