# 50-power.ps1 — fast reboot/poweroff (Windows analog of 50-power.zsh).
# ARM64 laptop: idempotent; works without elevation prompts.
function too       { & shutdown /r /t 0 }
function powerofff { & shutdown /s /t 0 }