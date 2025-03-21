# INSTALL ANDROID CLI TOOLS IN LINUX (Any Distro)

---

## PREREQUISITES
- Java 17 JDK installed (`JAVA_HOME` configured)
- `wget` and `unzip` utilities
- 3+ GB disk space

---

## STEP 1: DOWNLOAD ANDROID COMMAND-LINE TOOLS

` ` ` bash
mkdir -p ~/android/sdk/cmdline-tools
cd /tmp
wget https://dl.google.com/android/repository/commandlinetools-linux-10499896_latest.zip
unzip commandlinetools-linux-*.zip -d ~/android/sdk/cmdline-tools
mv ~/android/sdk/cmdline-tools/cmdline-tools ~/android/sdk/cmdline-tools/latest
` ` `

---

## STEP 2: SET ENVIRONMENT VARIABLES

Add to your shell config (`~/.bashrc` or `~/.zshrc`):

` ` ` bash
# Android paths
export ANDROID_HOME="$HOME/android/sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
` ` `

Reload configuration:

` ` ` bash
source ~/.bashrc  # or source ~/.zshrc
` ` `

---

## STEP 3: ACCEPT SDK LICENSES

` ` ` bash
yes | sdkmanager --licenses
` ` `

---

## STEP 4: INSTALL CORE COMPONENTS

### For .NET MAUI Development:

` ` ` bash
sdkmanager "platforms;android-34" "build-tools;34.0.0"
` ` `

### For Flutter/React Native:

` ` ` bash
sdkmanager \
"platform-tools" \
"emulator" \
"system-images;android-34;google_apis;x86_64" \
"patcher;v4"
` ` `

---

## STEP 5: VERIFY INSTALLATION

Check SDK Manager:

` ` ` bash
sdkmanager --list
` ` `

Test ADB:

` ` ` bash
adb devices
` ` `

---

## OPTIONAL: CREATE ANDROID VIRTUAL DEVICE

` ` ` bash
avdmanager create avd \
-n Pixel_6 \
-k "system-images;android-34;google_apis;x86_64" \
-d pixel_6
` ` `

---

## TROUBLESHOOTING

### Fix "command not found" errors:
- Verify `ANDROID_HOME` path matches installation directory
- Confirm `PATH` includes `cmdline-tools/latest/bin`

### Resolve Java issues:
` ` ` bash
# Add to shell config if encountering Java errors
export JAVA_HOME=/path/to/java17
export ANDROID_JAVA_HOME=$JAVA_HOME
` ` `

---

## POST-INSTALL CHECKLIST
- [ ] `sdkmanager --version` returns valid output
- [ ] `adb --version` shows 34.0+ 
- [ ] `$ANDROID_HOME/platforms/android-34` exists
