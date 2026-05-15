

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