# ~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1
# Qimono windows11 pack — PowerShell analog of .zshrc (stow-source/shell).
# Source is managed in the repo at dotfiles/windows11/profile-source/.
# Loads numbered snippets from Profile.d/ in order (mirrors .zshrc.d/*).

$ProfileDir = if ($PSScriptRoot) { $PSScriptRoot } else { Join-Path $HOME 'Documents\PowerShell' }

foreach ($snippet in (Get-ChildItem (Join-Path $ProfileDir 'Profile.d') -Filter '*.ps1' | Sort-Object Name)) {
    . $snippet.FullName
}