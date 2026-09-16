# 30-dotnet.ps1 — .NET / Q# readiness (Windows is the native home; mirror of
# 30-dotnet-quantum.zsh). No-op today if the SDK is deferred; activates the
# moment 'dotnet' lands on PATH.
$dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
if ($dotnet) {
    $env:DOTNET_ROOT = if ($env:DOTNET_ROOT) { $env:DOTNET_ROOT } else { Split-Path $dotnet.Source }
    if (Test-Path "$env:USERPROFILE\.dotnet\tools") { $env:PATH = "$env:USERPROFILE\.dotnet\tools;$env:PATH" }
}