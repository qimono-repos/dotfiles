

Write-Host "`nChecking for Ollama..." -ForegroundColor Cyan

$ollamaCheck = Get-Command ollama -ErrorAction SilentlyContinue

if ($ollamaCheck) {
    $version = &(ollama --version)
    Write-Host "Ollama is already installed: $version" -ForegroundColor Green
    Write-Host "Skipping installation." -ForegroundColor Gray
} else {
    Write-Host "Ollama not found. Starting installation..." -ForegroundColor Yellow

    try {
        # 'irm' is Invoke-RestMethod, 'iex' is Invoke-Expression
        # This will download and run the official Ollama installer script from https://www.ollama.com
        Invoke-RestMethod https://ollama.com/install.ps1 | Invoke-Expression
        Write-Host "Ollama installed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install Ollama. Check your internet connection or URL."
        Write-Host "Error Details: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# --- Fleet-standard model (Qimono dotfiles, llm/docs/local-llm.md) ---

$fleetModel = "gemma4:e2b"
Write-Host "`nChecking for fleet model $fleetModel..." -ForegroundColor Cyan

$models = &(ollama ls) 2>$null
if ($models -match [regex]::Escape($fleetModel)) {
    Write-Host "$fleetModel already pulled. Skipping." -ForegroundColor Green
} else {
    Write-Host "Pulling $fleetModel (~7.2 GB download)..." -ForegroundColor Yellow
    ollama pull $fleetModel
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$fleetModel pulled successfully." -ForegroundColor Green
    } else {
        Write-Error "Failed to pull $fleetModel."
    }
}

# One-shot smoke test via the JSON API (no spinner noise, machine-readable).
try {
    $body = @{ model = $fleetModel; prompt = "Reply with exactly: FLEET-LLM-OK"; stream = $false } | ConvertTo-Json
    $resp = Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/generate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 300
    if (($resp.response -join "") -match "FLEET-LLM-OK") {
        Write-Host "Smoke test PASS ($fleetModel answered)." -ForegroundColor Green
    } else {
        Write-Warning "Smoke test: model responded without the exact marker string."
    }
    ollama stop $fleetModel | Out-Null
} catch {
    Write-Warning "Smoke test skipped/failed: $($_.Exception.Message)"
}