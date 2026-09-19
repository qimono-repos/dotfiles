<#
  register-jupyter-startup-task.ps1 - JupyterLab on login, at 127.0.0.1:5005
  (Windows mirror of ubuntu's systemd --user qimono-jupyter.service).
  Runs run-jupyter-lab.ps1 (which is offline-capable after first uv sync)
  every time you log in. Idempotent: re-running just re-registers.

  Ghostty/terminal first, browser never opens automatically; you Ctrl-click
  http://127.0.0.1:5005 when you want the notebook UI.
#>
$ErrorActionPreference = 'Stop'
$root  = $PSScriptRoot
$task  = 'qimono-jupyter-win'
$lab   = Join-Path $root 'run-jupyter-lab.ps1'
$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$lab`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries -RestartCount 0

Register-ScheduledTask -TaskName $task -Action $action -Trigger $trigger `
    -Settings $settings -Description 'Qimono offline JupyterLab (127.0.0.1:5005) - mirror of ubuntu qimono-jupyter.service' `
    -Force | Out-Null

Write-Host "Registered: $task (runs at every logon). Manual start:" -ForegroundColor Green
Write-Host "  Start-ScheduledTask -TaskName $task" -ForegroundColor Cyan
Write-Host "Logs:  Get-ScheduledTaskInfo -TaskName $task  |  schtasks /query /tn $task /v /fo LIST" -ForegroundColor DarkGray
