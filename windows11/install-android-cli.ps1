# 1. Define Environment Paths
$AndroidHome = "$env:USERPROFILE\AppData\Local\Android\Sdk"
$CmdLineHome = "$AndroidHome\cmdline-tools\latest"

# Ensure directories exist
if (!(Test-Path $CmdLineHome)) { New-Item -ItemType Directory -Force -Path $CmdLineHome }

# 2. Download the latest Command Line Tools for Windows
# URL sourced from https://developer.android.com/studio#command-tools
$ZipUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$ZipFile = "$env:TEMP\cmdline-tools.zip"

Write-Host "Downloading Android Command Line Tools..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipFile

# 3. Extract Archive
Write-Host "Extracting tools..." -ForegroundColor Cyan
Expand-Archive -Path $ZipFile -DestinationPath "$env:TEMP\cmdline-extracted" -Force

# Move contents to the expected structure ('latest' directory is critical for modern sdkmanager)
Copy-Item -Path "$env:TEMP\cmdline-extracted\cmdline-tools\*" -Destination $CmdLineHome -Recurse -Force
Remove-Item "$env:TEMP\cmdline-extracted" -Recurse -Force
Remove-Item $ZipFile

# 4. Set Persistent Environment Variables
Write-Host "Configuring Environment Variables..." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $AndroidHome, "User")
[Environment]::SetEnvironmentVariable("ANDROID_USER_HOME", "$env:USERPROFILE\.android", "User")

# Update current session paths
$env:ANDROID_HOME = $AndroidHome
$env:PATH += ";$CmdLineHome\bin;$AndroidHome\platform-tools;$AndroidHome\emulator"

# Persist PATH updates for future sessions
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
$RequiredPaths = @("$CmdLineHome\bin", "$AndroidHome\platform-tools", "$AndroidHome\emulator")
foreach ($Path in $RequiredPaths) {
    if ($UserPath -notlike "*$Path*") { $UserPath += ";$Path" }
}
[Environment]::SetEnvironmentVariable("Path", $UserPath, "User")

# 5. Silently Accept Licenses & Install Core Components
Write-Host "Accepting SDK Licenses..." -ForegroundColor Cyan
# This handles the terminal prompt injection automatically
yes | & "$CmdLineHome\bin\sdkmanager.bat" --licenses

Write-Host "Installing Platform Tools, Build Tools, and System Image..." -ForegroundColor Cyan
# Adjust the API level (e.g., android-34) and architecture (google_apis;x86_64) as needed
& "$CmdLineHome\bin\sdkmanager.bat" "platform-tools" "build-tools;34.0.0" "platforms;android-34" "system-images;android-34;google_apis;x86_64" "emulator"

# 6. Create an Android Virtual Device (AVD) for the Emulator
Write-Host "Creating Virtual Device (AVD)..." -ForegroundColor Cyan
echo "no" | & "$CmdLineHome\bin\avdmanager.bat" create avd -n "Automation_Device" -k "system-images;android-34;google_apis;x86_64" --force

Write-Host "Setup Completed Successfully!" -ForegroundColor Green