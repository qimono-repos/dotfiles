# Filename: install-build-toolchain.ps1
# Description: Prepare the Rust + linker toolchain needed to source-build
#   qiskit / rustworkx on Windows ARM64 WITHOUT Visual Studio Build Tools.
#   This is the resume path for the deferred quantum build (see
#   doc/BUILD-QUANTUM-WIN_ARM64.md).
#
# What it does (idempotent — safe to re-run):
#   1. Install RustUP (winget) + stable aarch64-pc-windows-gnullvm toolchain.
#      NOTE: aarch64-pc-windows-gnu does NOT exist for ARM64; gnullvm is the
#      LLVM-MinGW flavour whose default linker is rust-lld. Building MSVC-ABI
#      extensions would need VS Build Tools (~1-2 GB) — this pack deliberately
#      avoids that via llvm-mingw instead.
#   2. Ensure llvm-mingw (aarch64, ucrt) is downloaded & extracted to
#      C:\Users\<you>\Tools\llvm-mingw. Provides clang + Windows UCRT import
#      libs used as the GNU linker for aarch64-pc-windows-gnullvm.
#   3. Emit the environment block needed for $env:CARGO_* before any
#      `uv sync`/`maturin build` that must compile Rust.
#
# Requires network the first time (rustup + llvm-mingw downloads ~ 250 MB).
# CHECK YOUR BUDGET: .\scripts\check-network-budget.ps1 before & after.
#
# Usage:
#   .\windows11\scripts\install-build-toolchain.ps1            (install + env show)
#   .\windows11\scripts\install-build-toolchain.ps1 -ShowEnv    (env block only)
#   .\windows11\scripts\install-build-toolchain.ps1 -SkipRustup (only llvm-mingw)

param(
    [switch]$ShowEnv,
    [switch]$SkipRustup
)

$ErrorActionPreference = 'Stop'

$LLVM_MINGW_VERSION = '20260908'
$LLVM_MINGW_ZIP     = "llvm-mingw-$LLVM_MINGW_VERSION-ucrt-aarch64.zip"
$LLVM_MINGW_URL     = "https://github.com/mstorsjo/llvm-mingw/releases/download/$LLVM_MINGW_VERSION/$LLVM_MINGW_ZIP"
$LLVM_MINGW_SHA256  = '7fe35f60407473c420ac72b25137f54385b0affd2c42efd507c0062fc626ab56'
$TOOLS_DIR          = Join-Path $HOME 'Tools'
$LLVM_HOME          = Join-Path $TOOLS_DIR 'llvm-mingw'

if ($ShowEnv) {
    Write-Host "`n[Cargo env for qtum source-builds]`n" -ForegroundColor Cyan
    Write-Host '  $env:RUSTUP_TOOLCHAIN = "stable-aarch64-pc-windows-gnullvm"'
    Write-Host '  $env:CARGO_BUILD_TARGET = "aarch64-pc-windows-gnullvm"'
    Write-Host ("  `$env:CARGO_TARGET_AARCH64_PC_WINDOWS_GNULLVM_LINKER = `"{0}`"" -f (Join-Path $LLVM_HOME 'bin\aarch64-w64-mingw32-clang.exe'))
    Write-Host ("  `$env:CC = `"{0}`"" -f (Join-Path $LLVM_HOME 'bin\aarch64-w64-mingw32-clang.exe'))
    Write-Host ("  `$env:CC_aarch64_pc_windows_gnullvm = `"{0}`"" -f (Join-Path $LLVM_HOME 'bin\aarch64-w64-mingw32-clang.exe'))
    Write-Host '  $env:RUSTFLAGS = ""'
    Write-Host "`n  Path: prepend `$HOME\.rustup\toolchains\stable-aarch64-pc-windows-gnullvm\bin and $LLVM_HOME\bin`n"
    exit 0
}

# ---- 1. RustUP + gnullvm toolchain ----------------------------------------
if (-not $SkipRustup) {
    $rustup = Get-Command rustup -ErrorAction SilentlyContinue
    if (-not $rustup) {
        Write-Host '==> installing RustUP via winget' -ForegroundColor Yellow
        winget install --id Rustlang.Rustup --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
        # rustup lands in ~\.cargo\bin
        $env:PATH = "$env:USERPROFILE\.cargo\bin;$env:PATH"
    }

    $list = & (Join-Path $env:USERPROFILE '.cargo\bin\rustup.exe') toolchain list 2>$null
    if ($list -notmatch 'gnullvm') {
        Write-Host '==> installing stable-aarch64-pc-windows-gnullvm toolchain' -ForegroundColor Yellow
        & (Join-Path $env:USERPROFILE '.cargo\bin\rustup.exe') toolchain install stable-aarch64-pc-windows-gnullvm
        if ($LASTEXITCODE -ne 0) { Write-Error 'rustup gnullvm toolchain install failed' }
    } else {
        Write-Host '==> gnullvm toolchain present' -ForegroundColor DarkGray
    }
} else {
    Write-Host '==> -SkipRustup: leaving rustup alone' -ForegroundColor DarkGray
}

# ---- 2. llvm-mingw ---------------------------------------------------------
if (Test-Path (Join-Path $LLVM_HOME 'bin\aarch64-w64-mingw32-clang.exe')) {
    Write-Host '==> llvm-mingw present' -ForegroundColor DarkGray
}
else {
    New-Item -ItemType Directory -Force -Path $TOOLS_DIR | Out-Null
    $zip = Join-Path (Join-Path $env:USERPROFILE 'Downloads') $LLVM_MINGW_ZIP
    if (-not (Test-Path $zip)) {
        Write-Host "==> downloading $LLVM_MINGW_ZIP (~177 MB)" -ForegroundColor Yellow
        Invoke-WebRequest -Uri $LLVM_MINGW_URL -OutFile $zip
    }
    $h = (Get-FileHash $zip -Algorithm SHA256).Hash
    if ($h -ne $LLVM_MINGW_SHA256) { throw "llvm-mingw hash mismatch: $h" }
    Write-Host '==> hash OK, extracting' -ForegroundColor Yellow
    $staging = Join-Path $TOOLS_DIR ($LLVM_MINGW_ZIP -replace '.zip$', '')
    Expand-Archive -LiteralPath $zip -DestinationPath $TOOLS_DIR -Force
    if (Test-Path $LLVM_HOME) { Remove-Item $LLVM_HOME -Recurse -Force }
    if (Test-Path $staging)   { Move-Item $staging $LLVM_HOME }
    if (-not (Test-Path (Join-Path $LLVM_HOME 'bin\aarch64-w64-mingw32-clang.exe'))) {
        throw 'llvm-mingw extraction: clang binary not found at expected path'
    }
}

# ---- 3. Show the env block ------------------------------------------------
& $PSCommandPath -ShowEnv

Write-Host 'OK: build toolchain ready. Next steps:' -ForegroundColor Green
Write-Host '  1. cd <quantum-workspace>'
Write-Host '  2. Apply the CARGO env block above (or run this script in that shell).'
Write-Host '  3. Follow doc/BUILD-QUANTUM-WIN_ARM64.md (pyo3==0.28 pin + uv sync).'