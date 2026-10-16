"""Preload Guix native libs for manylinux wheels (NumPy / Aer).

Guix CPython does not search /usr/lib. Wheels still dlopen libz / libstdc++
by soname. Exporting LD_LIBRARY_PATH in the login shell (or the Jupyter
unit) makes Ubuntu ls/date load Guix libm and die with GLIBC_2.43.

Install this as ``sitecustomize.py`` in a Guix-CPython venv's site-packages
(see scripts/install-guix-wheel-shim.sh) so only that interpreter preloads
the libs. Subprocesses (!ls in a notebook) keep the Ubuntu dynamic linker
path.

Override the profile with ``QIMONO_GUIX_PROFILE``. Do not import this from
an interactive host python.
"""

from __future__ import annotations

import ctypes
import os
from pathlib import Path

_GUIX_LIB = Path(
    os.environ.get("QIMONO_GUIX_PROFILE", str(Path.home() / ".guix-profile"))
) / "lib"
_SONAMES = (
    "libz.so.1",
    "libstdc++.so.6",
    "libgcc_s.so.1",
    "libgomp.so.1",
)


def _preload() -> None:
    if not _GUIX_LIB.is_dir():
        return
    for name in _SONAMES:
        path = _GUIX_LIB / name
        if not path.is_file():
            continue
        try:
            ctypes.CDLL(str(path), mode=ctypes.RTLD_GLOBAL)
        except OSError:
            pass


_preload()
