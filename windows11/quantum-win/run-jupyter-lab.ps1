<#
  run-jupyter-lab.ps1 - offline-capable JupyterLab (127.0.0.1 ONLY, port 5005).
  Direct Windows mirror of ubuntu's systemd-user qimono-jupyter.service, which
  runs `jupyter notebook` on 127.0.0.1:5005 (see ubuntu-hp-pro/stow-source/jupyter).
  Uses uv run (uv is project-scoped like npm, NOT a shell activate).

  The lab extra is OPTIONAL in pyproject (ipykernel + jupyterlab). They're
  pure-Python wheels, so first sync fetches them once, then they ride the uv
  cache. qiskit+rustworkx were vendored; uv NEVER source-builds those again.
#>
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
Set-Location $root

if (-not (Test-Path '.venv')) {
    Write-Host "no .venv yet -> running bootstrap + lab extra first" -ForegroundColor Yellow
    & .\bootstrap-quantum-win-offline.ps1
    if ($LASTEXITCODE -ne 0) { throw "bootstrap failed" }
}

# uv run always ensures the requested env; --extra lab pulls jupyterlab+ipykernel
# if missing. After the FIRST sync they're cached -> offline forever.
uv run --extra lab jupyter lab `
    --no-browser `
    --ip=127.0.0.1 `
    --port=5005 `
    --NotebookApp.token='' `
    --ServerApp.open_browser=False
