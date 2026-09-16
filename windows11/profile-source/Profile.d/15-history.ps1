# 15-history.ps1 — fleet baseline history (mirror 15-history.zsh).
# PSReadLine keeps history across sessions by default; tune sizes + dedupe.
if (Get-Module -ListAvailable PSReadLine) {
    Set-PSReadLineOption -HistorySaveStyle SaveIncrementally -MaximumHistoryCount 10000
}

# Fast up-arrow history search (mirrors up-line-or-beginning-search)
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Interactive default editor parity (alias vi -> nvim when present)
if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Set-Alias -Name vi -Value nvim -Scope Global
}