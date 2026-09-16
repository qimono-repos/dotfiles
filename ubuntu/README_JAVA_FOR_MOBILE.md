# README_JAVA_FOR_MOBILE — Java alignment across the fleet

**Authoritative reference machine:** Windows 11 Snapdragon ARM64
(`windows11` pack, host "Yin").
**Captured:** 2026-09-16 via `windows11/scripts/machine-discovery.ps1`.

## Reference Java on the reference machine

| Field | Value |
|-------|-------|
| Runtime | Android Studio bundled JBR (JetBrains Runtime) |
| `JAVA_HOME` | `C:\Program Files\Android\Android Studio\jbr` |
| `java -version` | **OpenJDK 25.0.3** (build 25.0.3+-15898627-b508.16, 64-bit server VM, mixed mode) |
| Source | Installed by Android Studio; **no Temurin / no system OpenJDK** |
| Policy | **FROZEN** — the Java on this Windows machine must not be upgraded,
  replaced, or redirected. It is the **reference** for aligning other hosts. |

## Goal

Where a Qimono Linux host installs OpenJDK via Guix or apt, pin the major
version to **25** whenever a stable 25.x release is available in the package
manager, so the Java version used for Android development is fleet-consistent.

If a Linux host's package manager does not carry 25 yet, fall back to
**LTS 21** (the previous stable LTS) and document the version explicitly in the
host's `MACHINE.md` under a `## Java` section.

## Alignment checklist

### ubuntu-len-yog-ARM64 (guix-first)

- [ ] Confirm Guix `openjdk` package version → `guix package -I | grep openjdk`
- [ ] If Guix carries OpenJDK 25: `guix install openjdk` (preferred manifest
      path: `profile-full.scm`)
- [ ] If Guix only carries 21: note in `MACHINE.md` as the interim JDK and
      leave guix installed until 25 ships

### ubuntu-len-yog-AMD64

- [ ] Same check: `guix package -I | grep openjdk`
- [ ] Align to 25 when available; note interim version in that pack's MACHINE.md

### ubuntu-hp-pro

- [ ] apt list `openjdk-*-jdk` → if `openjdk-25-jdk` available, apt pin to 25

### Any new Qimono Linux host

- [ ] `MACHINE.md` records the installed JDK version explicitly
- [ ] `profile-full.scm` (or equivalent) carries the JDK entry

## Why Java 25?

Java 25 is the first post-LTS non-LTS release aligned with Android Studio's
JBR 25 in 2026. Aligning the Linux hosts to 25 means `javac` output and
classpath behavior match the Windows/Android build exactly, avoiding the subtle
cross-compilation surprises that arise from mismatched JDKs (e.g., newer sealed
class rules, classfile version mismatches).

## Notes for Windows hosts

Windows hosts ship the JDK with Android Studio and use `JAVA_HOME` at
`%ProgramFiles%\Android\Android Studio\jbr` (as on the reference machine).
No system-wide JDK install should be performed alongside Android Studio; the
Studio JBR is sufficient and stays in sync with Studio updates.