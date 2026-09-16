# 25-ssh-agent.ps1 — ensure the OpenSSH Authentication Agent is available
# (Windows analog of 25-ssh-agent.zsh). Identity key created by install.ps1:
#   ~\.ssh\id_ed_key_25519_yin_at_qi
$sshAgent = Get-Service ssh-agent -ErrorAction SilentlyContinue
if ($sshAgent) {
    if ($sshAgent.Status -ne 'Running') {
        try { Start-Service ssh-agent; Start-Sleep -Milliseconds 300 } catch { }
    }
    if ((Get-Service ssh-agent -ErrorAction SilentlyContinue).Status -eq 'Running' -and
        -not (Test-Path "$env:USERPROFILE\.ssh\id_ed_key_25519_yin_at_qi")) {
        Write-Warning '25-ssh-agent: no ed25519 key yet — generate one with: ssh-keygen -t ed25519'
    }
} else {
    Write-Verbose '25-ssh-agent: OpenSSH agent service not present (optional).'
}