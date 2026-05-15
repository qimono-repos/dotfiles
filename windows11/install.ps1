# Filename: install.ps1
# Description: Bootstraps Yin (Windows) with WSL2 (Ubuntu), Podman, Git, GitHub CLI, and SSH.
# IMPORTANT: Run as Administrator.

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator (Right-click > Run with PowerShell as Admin)."
    exit
}

Write-Host "--- Starting Qimono Bootstrapping (2026 Edition) ---" -ForegroundColor Cyan

Write-Host "Enabling WSL 2 and installing Ubuntu..." -ForegroundColor Green
wsl --install -d Ubuntu

$apps = @("Git.Git", "GitHub.cli", "RedHat.Podman-Desktop")

foreach ($app in $apps) {
    Write-Host "Installing $app..." -ForegroundColor Green
    winget install -e --id $app --silent --accept-package-agreements
}

$sshPath = "$env:USERPROFILE\.ssh"
$keyName = "id_ed_key_25519_yin_at_qi"

if (!(Test-Path $sshPath)) {
    New-Item -ItemType Directory -Path $sshPath -Force | Out-Null
}

if (!(Test-Path "$sshPath\$keyName")) {
    Write-Host "Generating Ed25519 SSH key..." -ForegroundColor Yellow
    # -N '""' ensures no passphrase for a truly "lazy" automated setup
    ssh-keygen -t ed25519 -N '""' -f "$sshPath\$keyName"
}

# 5. Final Instructions [cite: 124, 125]
Write-Host "`n--- SETUP NEARLY COMPLETE ---" -ForegroundColor Cyan
Write-Host "STEP 1: RESTART YOUR PC (Mandatory for WSL 2 kernel & Ubuntu initialization)." -ForegroundColor Red
Write-Host "STEP 2: After reboot, open a terminal and run these commands to sync with GitHub:" -ForegroundColor Yellow
Write-Host "   gh auth login"
Write-Host "   gh ssh-key add `"$sshPath\$keyName.pub`" --title `"Yin-Windows-Machine`""
Write-Host "STEP 3: Clone your dotfiles: gh repo clone qimono-repos/dotfiles" -ForegroundColor Yellow

Write-Host "`nSetup current GIT username..." -ForegroundColor Yellow
git config --global user.email alberto.gruning.zen@gmail.com
git config --global user.name "Albert_Gruning__at__Qimono"