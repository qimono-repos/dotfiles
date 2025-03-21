# TUTORIAL: INSTALL JAVA FOR ANDROID CLI TOOLS ON LINUX  
Android CLI tools require **Java 17**. This guide covers installation for all Linux distributions.

---

## Step 1: Installation Methods  
Choose **ONE** of these methods:  

### Method A: Package Manager (Recommended)  

#### Ubuntu/Debian
1. Update repositories:  
    sudo apt update  

2. Install OpenJDK 17:  
    sudo apt install openjdk-17-jdk  

3. Verify:  
        java --version  

#### Fedora/RHEL
1. Install OpenJDK 17:  
        sudo dnf install java-17-openjdk-devel  

2. Verify:  
                java --version  

#### Arch Linux

1. Install OpenJDK 17:  
                    sudo pacman -S jdk17-openjdk  

2. Verify:  
                        java --version  

                        ---

### Method B: Manual Installation (Custom Path: `/usr/lib/jdk/jvm`)  

1. Download OpenJDK 17 from Adoptium:  
wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.11+9/OpenJDK17U-jdk_x64_linux_hotspot_17.0.11_9.tar.gz  

2. Create the target directory:  
sudo mkdir -p /usr/lib/jdk/jvm  

3. Extract the tarball:  
sudo tar -xzf OpenJDK17U-jdk_*.tar.gz -C /usr/lib/jdk/jvm --strip-components=1  

4. Set environment variables in `~/.bashrc` or `~/.zshrc`:  
export JAVA_HOME=/usr/lib/jdk/jvm  
export PATH=$JAVA_HOME/bin:$PATH  

5. Apply changes:  
source ~/.bashrc  

6. Verify:  
java --version  

---

## Step 2: Configuration Checks  

1. Confirm `JAVA_HOME`:  
echo $JAVA_HOME  

2. Check Java binary path:  
which java  

3. Validate Java version:  
    java --version  

    ---

## Step 3: Troubleshooting  

### Multiple Java Versions  
1. List installed versions:  
sudo update-alternatives --config java  

2. Select OpenJDK 17 from the menu.  

### `JAVA_HOME` Not Set  
Add these lines to your shell profile:  
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk  # For package manager installs  
# OR  
export JAVA_HOME=/usr/lib/jdk/jvm              # For manual installs  
export PATH=$JAVA_HOME/bin:$PATH  

### Android Tools Compatibility  
Explicitly set Java for Android SDK:  
export ANDROID_JAVA_HOME=$JAVA_HOME  

---

## Final Notes  
- Use `java --version` to confirm OpenJDK 17.  
- Replace manual installations manually when updating.  
