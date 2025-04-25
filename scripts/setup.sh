#!/bin/bash

echo "Script made by rmux"
echo "===== Arch Linux ARM Setup for Xiaomi Pad 6 ====="
echo ""
echo " ____  ____  _  ____  _  __  "
echo "| __ )|  _ \|_|/ ___|| |/ / "
echo "|  _ \| |_) | | |    | ' / "
echo "| |_) |  _ <| | |___ | . \ "
echo "|____/|_| \_\_|\____||_|\_\ "
echo "                             ᵀᴹ  "
echo ""

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
   echo "This script must be run as root" 
   exit 1
fi

# WiFi Setup
echo "=== WiFi Setup ==="
echo "Please enter your WiFi SSID (network name):"
read ssid
echo "Please enter your WiFi password:"
read -s password
echo "Connecting to WiFi..."
nmcli device wifi connect "$ssid" password "$password"

if [ $? -eq 0 ]; then
    echo "WiFi connected successfully!"
else
    echo "Failed to connect to WiFi. Please check your credentials and try again."
    exit 1
fi

# Test internet connection
if ! ping -c 1 archlinux.org &> /dev/null; then
    echo "No internet connection. Please check your network and try again."
    exit 1
fi

# Time and Locale Setup
echo ""
echo "=== Time and Locale Setup ==="

# Synchronize time with network
echo "Synchronizing time with network time servers..."
timedatectl set-ntp true

# Timezone setup
echo "Setting up timezone..."
echo "Common timezones:"
echo "1) America/New_York (Eastern US)"
echo "2) America/Chicago (Central US)"
echo "3) America/Denver (Mountain US)"
echo "4) America/Los_Angeles (Pacific US)"
echo "5) Europe/London (UK)"
echo "6) Europe/Berlin (Germany, Central Europe)"
echo "7) Europe/Moscow (Russia)"
echo "8) Asia/Tokyo (Japan)"
echo "9) Asia/Shanghai (China)"
echo "10) Australia/Sydney (Australia Eastern)"
echo "11) Pacific/Auckland (New Zealand)"
echo "12) Other (manually enter timezone)"

read -p "Select your timezone [1-12]: " tz_choice

case $tz_choice in
    1) timezone="America/New_York" ;;
    2) timezone="America/Chicago" ;;
    3) timezone="America/Denver" ;;
    4) timezone="America/Los_Angeles" ;;
    5) timezone="Europe/London" ;;
    6) timezone="Europe/Berlin" ;;
    7) timezone="Europe/Moscow" ;;
    8) timezone="Asia/Tokyo" ;;
    9) timezone="Asia/Shanghai" ;;
    10) timezone="Australia/Sydney" ;;
    11) timezone="Pacific/Auckland" ;;
    12)
        echo "Available timezones can be listed with 'timedatectl list-timezones'"
        echo "Please enter your timezone (e.g., America/New_York):"
        read timezone
        ;;
    *) 
        echo "Invalid choice. Setting to UTC."
        timezone="UTC"
        ;;
esac

timedatectl set-timezone $timezone
echo "Timezone set to $timezone"

# Locale setup
echo ""
echo "Setting up system locale..."
echo "Common locales:"
echo "1) en_US.UTF-8 (US English)"
echo "2) en_GB.UTF-8 (British English)"
echo "3) de_DE.UTF-8 (German)"
echo "4) fr_FR.UTF-8 (French)"
echo "5) es_ES.UTF-8 (Spanish)"
echo "6) it_IT.UTF-8 (Italian)"
echo "7) ru_RU.UTF-8 (Russian)"
echo "8) zh_CN.UTF-8 (Chinese Simplified)"
echo "9) ja_JP.UTF-8 (Japanese)"
echo "10) ko_KR.UTF-8 (Korean)"
echo "11) Other (manually enter locale)"

read -p "Select your locale [1-11]: " locale_choice

case $locale_choice in
    1) locale="en_US.UTF-8" ;;
    2) locale="en_GB.UTF-8" ;;
    3) locale="de_DE.UTF-8" ;;
    4) locale="fr_FR.UTF-8" ;;
    5) locale="es_ES.UTF-8" ;;
    6) locale="it_IT.UTF-8" ;;
    7) locale="ru_RU.UTF-8" ;;
    8) locale="zh_CN.UTF-8" ;;
    9) locale="ja_JP.UTF-8" ;;
    10) locale="ko_KR.UTF-8" ;;
    11)
        echo "Please enter your locale (e.g., en_US.UTF-8):"
        read locale
        ;;
    *) 
        echo "Invalid choice. Setting to en_US.UTF-8."
        locale="en_US.UTF-8"
        ;;
esac

# Generate locale
echo "$locale UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=$locale" > /etc/locale.conf
export LANG=$locale
echo "Locale set to $locale"

# System update
echo ""
echo "=== Updating system packages ==="
echo "This may take some time depending on your internet speed..."
pacman -Syu --noconfirm || { echo "Failed to update packages. Exiting."; exit 1; }

# Install basic packages
echo ""
echo "=== Installing basic packages ==="
pacman -S --noconfirm mesa vulkan-freedreno sudo networkmanager bluez bluez-utils xorg xorg-server xorg-xinit || { echo "Failed to install basic packages. Exiting."; exit 1; }

# Enable essential services
systemctl enable NetworkManager
systemctl enable bluetooth

# Fix Bluetooth MAC address
echo ""
echo "=== Setting up Bluetooth MAC address fix ==="
cat > /etc/systemd/system/bt-mac.service << EOF
[Unit]
Description=Bluetooth MAC fix
After=bluetooth.service
Requires=bluetooth.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c "/usr/bin/echo "yes" | /usr/bin/btmgmt --index 0 public-addr 00:1a:7d:da:71:13"
RemainAfterExit=yes
TimeoutStartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable bt-mac.service
echo "Bluetooth MAC address fix service has been set up"

# Desktop Environment Selection
echo ""
echo "=== Desktop Environment Selection ==="
echo "Please select a desktop environment to install:"
echo "1) KDE Plasma"
echo "   - Modern, feature-rich desktop environment"
echo "   - RAM usage: ~1GB"
echo "   - Good for tablets with touchscreen support"
echo ""
echo "2) XFCE"
echo "   - Lightweight traditional desktop environment"
echo "   - RAM usage: ~500MB"
echo "   - Customizable but needs additional configuration for tablets"
echo ""
echo "3) LXQt"
echo "   - Very lightweight Qt-based desktop environment"
echo "   - RAM usage: ~350MB"
echo "   - Best performance on limited hardware"
echo "   - RECOMMENDED if you plan to game on this tablet due to lower resource usage"
echo ""
read -p "Enter your choice (1-3): " de_choice

# Terminal Selection
echo ""
echo "=== Terminal Selection ==="
echo "Please select a terminal to install:"
echo "1) Konsole (KDE's terminal)"
echo "2) XFCE Terminal"
echo "3) QTerminal (LXQt's terminal)"
echo "4) Alacritty (GPU accelerated terminal)"
echo "5) Kitty (GPU accelerated terminal with tabs)"
echo "6) Wezterm (GPU accelerated terminal with advanced features)"
read -p "Enter your choice (1-6): " term_choice

# Install Firefox browser and common applications
echo "Installing Firefox browser and common desktop applications..."
pacman -S --noconfirm firefox gvfs gvfs-mtp pulseaudio pavucontrol xdg-user-dirs || { echo "Failed to install common applications. Exiting."; exit 1; }

# Install selected terminal
case $term_choice in
    1)
        echo "Installing Konsole terminal..."
        pacman -S --noconfirm konsole
        ;;
    2)
        echo "Installing XFCE Terminal..."
        pacman -S --noconfirm xfce4-terminal
        ;;
    3)
        echo "Installing QTerminal..."
        pacman -S --noconfirm qterminal
        ;;
    4)
        echo "Installing Alacritty terminal..."
        pacman -S --noconfirm alacritty
        ;;
    5)
        echo "Installing Kitty terminal..."
        pacman -S --noconfirm kitty
        ;;
    6)
        echo "Installing Wezterm terminal..."
        pacman -S --noconfirm wezterm
        ;;
    *)
        echo "Invalid choice. Installing default terminal based on DE."
        ;;
esac

# Install SDDM and theme
echo "Installing SDDM display manager with theme..."
pacman -S --noconfirm sddm sddm-kcm || { echo "Failed to install SDDM. Exiting."; exit 1; }

# Install a theme for SDDM to avoid bugs
pacman -S --noconfirm breeze || { echo "Warning: Failed to install SDDM theme. SDDM might have display issues."; }

# Configure SDDM
mkdir -p /etc/sddm.conf.d/
cat > /etc/sddm.conf.d/kde_settings.conf << EOF
[Theme]
Current=breeze
EOF

# Desktop Environment Installation
case $de_choice in
    1)
        echo "Installing KDE Plasma Desktop..."
        pacman -S --noconfirm plasma plasma-wayland-session plasma-pa plasma-nm plasma-desktop dolphin kate xorg-server-xwayland || { echo "Failed to install KDE Plasma. Exiting."; exit 1; }
        systemctl enable sddm
        ;;
    2)
        echo "Installing XFCE Desktop..."
        pacman -S --noconfirm xfce4 xfce4-goodies xfdesktop xfwm4 xfce4-session xorg-xinit network-manager-applet xfce4-power-manager || { echo "Failed to install XFCE. Exiting."; exit 1; }
        # Use SDDM for XFCE too
        systemctl enable sddm
        ;;
    3)
        echo "Installing LXQt Desktop..."
        pacman -S --noconfirm lxqt lxqt-admin lxqt-config lxqt-globalkeys lxqt-panel lxqt-runner breeze-icons pcmanfm-qt xorg-xinit network-manager-applet || { echo "Failed to install LXQt. Exiting."; exit 1; }
        systemctl enable sddm
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Kernel Update and Audio Fix
echo ""
echo "=== Arch Linux Kernel 6.14.2 Update ==="
echo "This should be the last time kernel is updated this way. In the near future, kernel will be updateable by pacman."
echo ""
echo "Features:"
echo "- Update to 6.14.2 Kernel"
echo "- Sound (less glitchy)"
echo "- Landscape TTY"
echo "- Landlock support"
echo "- Enabled lz4 for zram"
echo ""

echo "Downloading kernel modules..."
pacman -S --noconfirm wget unzip || { echo "Failed to install download tools. Continuing anyway..."; }
wget https://github.com/BrickTM-mainline/pipa/releases/download/3.0/arch_modules_v3_0_0.zip -O /tmp/arch_modules_v3_0_0.zip || { echo "Failed to download kernel modules. Skipping kernel update."; }

if [ -f /tmp/arch_modules_v3_0_0.zip ]; then
    echo "Installing kernel modules..."
    unzip -o /tmp/arch_modules_v3_0_0.zip -d / || { echo "Failed to extract kernel modules. Skipping kernel update."; }
    rm /tmp/arch_modules_v3_0_0.zip
    echo "Kernel modules updated successfully!"
else
    echo "Kernel modules archive not found. Skipping kernel update."
fi

echo ""
echo "=== Audio Fix Setup ==="
echo "Creating ALSA UCM configuration files for Xiaomi Pad 6..."

# Create directories if they don't exist
mkdir -p /usr/share/alsa/ucm2/conf.d/sm8250
mkdir -p /usr/share/alsa/ucm2/Qualcomm/sm8250

# Create first configuration file
cat > "/usr/share/alsa/ucm2/conf.d/sm8250/Xiaomi Pad 6.conf" << EOF
Syntax 3

SectionUseCase."HiFi" {
  File "/Qualcomm/sm8250/HiFi.conf"
  Comment "HiFi quality Music."
}

SectionUseCase."HDMI" {
  File "/Qualcomm/sm8250/HDMI.conf"
  Comment "HDMI output."
}
EOF

# Create second configuration file
cat > "/usr/share/alsa/ucm2/Qualcomm/sm8250/HiFi.conf" << EOF
Syntax 3

SectionVerb {
    EnableSequence [
        # Enable MultiMedia1 routing -> TERTIARY_TDM_RX_0
        cset "name='TERT_TDM_RX_0 Audio Mixer MultiMedia1' 1"
    ]


    DisableSequence [
        cset "name='TERT_TDM_RX_0 Audio Mixer MultiMedia1' 0"
    ]

    Value {
        TQ "HiFi"
    }
}

# Add a section for AW88261 speakers
SectionDevice."Speaker" {
    Comment "Speaker playback"

    Value {
        PlaybackPriority 200
        PlaybackPCM "hw:\${CardId},0"  # PCM dla TERTIARY_TDM_RX_0
    }
}
EOF

echo "Audio configuration files created successfully!"

echo ""
echo "=== Setup Completed ==="
echo "Your Arch Linux system on Xiaomi Pad 6 has been set up successfully!"
echo "The system will reboot in 10 seconds to apply changes."
echo "After reboot, you will be greeted with your new desktop environment."

sleep 10
reboot
