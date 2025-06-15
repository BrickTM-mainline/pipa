#!/bin/bash

# Define log file for error tracking
LOGFILE="/tmp/arch_setup.log"
exec 2>>"$LOGFILE"

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

# WiFi Setup - Make it optional
echo "=== WiFi Setup ==="
echo "Note: Internet connection is required for system updates and package installation."
read -p "Do you want to set up WiFi now? (y/n): " setup_wifi

if [[ $setup_wifi == "y" || $setup_wifi == "Y" ]]; then
    echo "Please enter your WiFi SSID (network name):"
    read ssid
    echo "Please enter your WiFi password:"
    read -s password
    echo "Connecting to WiFi..."
    if nmcli device wifi connect "$ssid" password "$password" &>>"$LOGFILE"; then
        echo "WiFi connected successfully!"
    else
        echo "Failed to connect to WiFi. Please check your credentials."
        echo "You can set up WiFi later using the NetworkManager tool."
    fi
else
    echo "Skipping WiFi setup. You can set it up later using the NetworkManager tool."
    echo "Note: Some installation steps may fail without internet connection."
fi

# Test internet connection
if ! ping -c 1 archlinux.org &>>"$LOGFILE"; then
    echo "Warning: No internet connection detected. Some installation steps may fail."
    read -p "Continue anyway? (y/n): " continue_setup
    if [[ $continue_setup != "y" && $continue_setup != "Y" ]]; then
        echo "Setup aborted."
        exit 1
    fi
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
read -p "Proceed with system update? (y/n): " update_choice
if [[ $update_choice == "y" || $update_choice == "Y" ]]; then
    if ! pacman -Syu --noconfirm &>>"$LOGFILE"; then
        echo "ERROR: Failed to update packages. Check $LOGFILE for details."
    fi
else
    echo "Skipping system update."
fi

# Basic packages (Wayland only)
echo ""
echo "=== Installing basic packages ==="
read -p "Install basic packages (mesa, vulkan-freedreno, sudo, etc)? (y/n): " basicpkg_choice
if [[ $basicpkg_choice == "y" || $basicpkg_choice == "Y" ]]; then
    if ! pacman -S --noconfirm mesa vulkan-freedreno sudo networkmanager bluez bluez-utils fastfetch macchanger &>>"$LOGFILE"; then
        echo "ERROR: Failed to install basic packages. Check $LOGFILE for details."
    fi
else
    echo "Skipping basic packages installation."
fi

# Enable essential services
systemctl enable NetworkManager &>>"$LOGFILE" || echo "Warning: Failed to enable NetworkManager."
systemctl enable bluetooth &>>"$LOGFILE" || echo "Warning: Failed to enable bluetooth."

# Download and install fixed BlueZ packages
echo "Downloading and installing fixed BlueZ packages..."
cd /tmp
if wget -nc https://github.com/BrickTM-mainline/pipa/releases/download/1.1/bluez-5.82-1-aarch64.pkg.tar.xz &>>"$LOGFILE" && \
   wget -nc https://github.com/BrickTM-mainline/pipa/releases/download/1.1/bluez-libs-5.82-1-aarch64.pkg.tar.xz &>>"$LOGFILE" && \
   wget -nc https://github.com/BrickTM-mainline/pipa/releases/download/1.1/bluez-tools-0.2.0-6-aarch64.pkg.tar.xz &>>"$LOGFILE" && \
   wget -nc https://github.com/BrickTM-mainline/pipa/releases/download/1.1/bluez-utils-5.82-1-aarch64.pkg.tar.xz &>>"$LOGFILE"; then
    if ! pacman -U --noconfirm bluez-5.82-1-aarch64.pkg.tar.xz bluez-libs-5.82-1-aarch64.pkg.tar.xz bluez-tools-0.2.0-6-aarch64.pkg.tar.xz bluez-utils-5.82-1-aarch64.pkg.tar.xz &>>"$LOGFILE"; then
        echo "Warning: Failed to install BlueZ packages. Continuing..."
    fi
else
    echo "Warning: Failed to download BlueZ packages. Using default packages."
fi

# Desktop Environment Selection (GNOME and KDE only)
echo ""
echo "=== Desktop Environment Selection (Wayland Only) ==="
echo "Please select a desktop environment to install:"
echo "1) GNOME (Wayland, RECOMMENDED)"
echo "2) KDE Plasma (Wayland)"
echo ""
read -p "Enter your choice (1-2): " de_choice

# Terminal Selection (Wayland compatible)
echo ""
echo "=== Terminal Selection ==="
echo "Please select a terminal to install:"
echo "1) GNOME Terminal (GNOME default)"
echo "2) Konsole (KDE default)"
echo "3) Alacritty (Wayland compatible)"
echo "4) Kitty (Wayland compatible)"
echo "5) Foot (Wayland compatible, lightweight)"
read -p "Enter your choice (1-5): " term_choice

# Install Firefox browser and common applications
echo "Installing Firefox browser, fastfetch, and common desktop applications..."
if ! pacman -S --noconfirm firefox gvfs gvfs-mtp pulseaudio pavucontrol xdg-user-dirs fastfetch &>>"$LOGFILE"; then
    echo "ERROR: Failed to install common applications. Check $LOGFILE for details."
fi

# Install selected terminal
case $term_choice in
    1) pacman -S --noconfirm gnome-terminal &>>"$LOGFILE" || echo "Warning: Failed to install gnome-terminal." ;;
    2) pacman -S --noconfirm konsole &>>"$LOGFILE" || echo "Warning: Failed to install konsole." ;;
    3) pacman -S --noconfirm alacritty &>>"$LOGFILE" || echo "Warning: Failed to install alacritty." ;;
    4) pacman -S --noconfirm kitty &>>"$LOGFILE" || echo "Warning: Failed to install kitty." ;;
    5) pacman -S --noconfirm foot &>>"$LOGFILE" || echo "Warning: Failed to install foot." ;;
    *) echo "Invalid choice. Installing default terminal based on DE." ;;
esac

# Install extra fonts and emojis
echo "Installing extra fonts and emoji support..."
if ! pacman -S --noconfirm noto-fonts noto-fonts-emoji ttf-dejavu &>>"$LOGFILE"; then
    echo "Warning: Failed to install fonts. Continuing..."
fi

# Optionally install AppleColorEmoji.ttf (iOS emojis)
read -p "Do you want to install iOS (Apple) emojis? (y/n): " install_apple_emoji
if [[ $install_apple_emoji == "y" || $install_apple_emoji == "Y" ]]; then
    mkdir -p /usr/share/fonts/apple-emoji
    if wget -nc https://github.com/samuelngs/apple-emoji-linux/releases/download/v18.4/AppleColorEmoji.ttf -O /usr/share/fonts/apple-emoji/AppleColorEmoji.ttf &>>"$LOGFILE"; then
        fc-cache -fv &>>"$LOGFILE"
        echo "AppleColorEmoji.ttf installed."
    else
        echo "Warning: Failed to download Apple emojis."
    fi
fi

# Install power management and utilities
echo "Installing power management, brightness control, and system tools..."
if ! pacman -S --noconfirm tlp brightnessctl blueman grim slurp scrcpy gtop btop nemo &>>"$LOGFILE"; then
    echo "Warning: Failed to install some utilities."
fi
systemctl enable tlp &>>"$LOGFILE" || echo "Warning: Failed to enable tlp."

# Desktop Environment Installation
case $de_choice in
    1)
        echo "Installing GNOME (Wayland)..."
        # Install GNOME dependencies (skip libappstream-glib)
        if ! pacman -S --noconfirm flatpak ostree malcontent appstream \
            appstream-glib bubblewrap xdg-dbus-proxy \
            dconf dconf-editor gsettings-desktop-schemas \
            polkit accountsservice &>>"$LOGFILE"; then
            echo "Warning: Failed to install some GNOME dependencies."
        fi
        
        # Install GNOME core (skip gnome-icon-theme, gnome-software-packagekit-plugin)
        if ! pacman -S --noconfirm gnome gnome-extra gnome-tweaks gdm \
            adwaita-icon-theme gnome-themes-extra papirus-icon-theme \
            wayland wayland-protocols xdg-desktop-portal xdg-desktop-portal-gnome \
            gtk3 gtk4 qt5-wayland qt6-wayland breeze breeze-icons onboard \
            gnome-software &>>"$LOGFILE"; then
            echo "ERROR: Failed to install GNOME. Check $LOGFILE for details."
        fi
        
        # Configure GDM for Wayland
        mkdir -p /etc/gdm/
        cat > /etc/gdm/custom.conf << EOF
[daemon]
WaylandEnable=true
AutomaticLoginEnable=false

[security]

[xdmcp]

[chooser]

[debug]
EOF
        
        # Ensure Flatpak is installed before using it
        if command -v flatpak &>/dev/null; then
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo &>>"$LOGFILE"
        else
            echo "Warning: Flatpak is not installed, skipping flathub remote add."
        fi

        # Always enable GDM for GNOME
        if ! systemctl enable gdm &>>"$LOGFILE"; then
            echo "ERROR: Failed to enable gdm. Try installing gdm manually and enable it."
        fi
        echo "GNOME with GDM (Wayland) installed successfully!"
        ;;
    2)
        echo "Installing KDE Plasma (Wayland)..."
        if ! pacman -S --noconfirm plasma plasma-wayland-session plasma-pa plasma-nm plasma-desktop \
            dolphin kate wayland wayland-protocols qt5-wayland qt6-wayland \
            xdg-desktop-portal xdg-desktop-portal-kde wlroots breeze breeze-icons \
            sddm sddm-kcm qtvirtualkeyboard &>>"$LOGFILE"; then
            echo "ERROR: Failed to install KDE Plasma. Check $LOGFILE for details."
        fi
        
        # Configure SDDM for Wayland
        mkdir -p /etc/sddm.conf.d/
        cat > /etc/sddm.conf.d/10-wayland.conf << EOF
[General]
DisplayServer=wayland
CompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1

[Theme]
Current=breeze

[Wayland]
SessionDir=/usr/share/wayland-sessions
CompositorCommand=kwin_wayland --drm --no-lockscreen

[X11]
SessionDir=/usr/share/xsessions
EOF
        # Always enable SDDM for KDE
        systemctl enable sddm &>>"$LOGFILE" || echo "Warning: Failed to enable sddm."
        echo "KDE Plasma with SDDM (Wayland) installed successfully!"
        ;;
    *)
        echo "ERROR: Invalid choice. Exiting."
        exit 1
        ;;
esac

echo "Display manager has been installed and enabled."

# Kernel Update and Audio Fix
echo ""
echo "=== Arch Linux Kernel 6.14.2 Update ==="
echo "Downloading and extracting kernel modules..."
read -p "Do you want to update kernel modules? (y/n): " kernel_choice
if [[ $kernel_choice == "y" || $kernel_choice == "Y" ]]; then
    pacman -S --noconfirm wget p7zip unzip || { echo "Failed to install download tools. Continuing anyway..."; }
    wget -nc https://github.com/BrickTM-mainline/pipa/releases/download/1.1/6.14.2-1-aarch64-pipa-arch-pipa-domin746826+.7z -O /tmp/6.14.2-1-aarch64-pipa-arch-pipa-domin746826+.7z || { echo "Failed to download kernel modules. Skipping kernel update."; }

    if [ -f /tmp/6.14.2-1-aarch64-pipa-arch-pipa-domin746826+.7z ]; then
        echo "Extracting kernel modules to /lib/modules/..."
        7z x /tmp/6.14.2-1-aarch64-pipa-arch-pipa-domin746826+.7z -o/lib/modules/ || { echo "Failed to extract kernel modules. Skipping kernel update."; }
        rm /tmp/6.14.2-1-aarch64-pipa-arch-pipa-domin746826+.7z
        echo "Kernel modules updated successfully!"
    else
        echo "Kernel modules archive not found. Skipping kernel update."
    fi
else
    echo "Skipping kernel module update."
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

# === User Account Creation ===
echo ""
echo "=== User Account Setup ==="

read -p "Do you want to create any additional users (regular or root)? (y/n): " add_users
if [[ $add_users == "y" || $add_users == "Y" ]]; then
    while true; do
        echo ""
        echo "1) Create a regular (non-root) user"
        echo "2) Create an additional root user"
        echo "3) Done adding users"
        read -p "Choose an option [1-3]: " user_opt
        case $user_opt in
            1)
                read -p "Enter the username for the new regular user: " new_username
                useradd -m -G wheel,audio,video,network -s /bin/bash "$new_username" &>>"$LOGFILE"
                echo "Set password for $new_username:"
                passwd "$new_username"
                echo "$new_username ALL=(ALL) ALL" >> /etc/sudoers.d/10-$new_username
                chmod 0440 /etc/sudoers.d/10-$new_username
                echo "User $new_username created and added to sudoers."
                ;;
            2)
                read -p "Enter the username for the new root user: " root_username
                useradd -m -G wheel,audio,video,network -s /bin/bash "$root_username" &>>"$LOGFILE"
                echo "Set password for $root_username:"
                passwd "$root_username"
                usermod -aG root "$root_username" &>>"$LOGFILE"
                echo "$root_username ALL=(ALL) ALL" >> /etc/sudoers.d/10-$root_username
                chmod 0440 /etc/sudoers.d/10-$root_username
                echo "Root user $root_username created and added to sudoers and root group."
                ;;
            3)
                break
                ;;
            *)
                echo "Invalid option."
                ;;
        esac
    done
else
    echo "Skipping user creation."
fi

# Install additional packages
echo "Installing media codecs and archive utilities..."
if ! pacman -S --noconfirm gst-libav gst-plugins-ugly gst-plugins-bad ffmpeg \
    file-roller ark xarchiver unrar unzip p7zip &>>"$LOGFILE"; then
    echo "Warning: Failed to install some packages."
fi

# Optional: yay AUR helper and Flatpak installation
read -p "Do you want to install yay (AUR helper) and additional Flatpak apps? (y/n): " install_yay
if [[ $install_yay == "y" || $install_yay == "Y" ]]; then
    echo "Checking for yay..."
    if command -v yay >/dev/null 2>&1; then
        echo "yay is already installed."
        yay_user=""
        # List all non-system users (UID >= 1000, except nologin)
        users=$(awk -F: '$3 >= 1000 && $7 !~ /nologin/ {print $1}' /etc/passwd)
        echo "Available users:"
        select u in $users; do
            yay_user=$u
            break
        done
        if [[ -n "$yay_user" ]]; then
            if command -v flatpak >/dev/null 2>&1; then
                # Install ARM64-compatible Flatpak apps
                if [[ $de_choice == "1" ]]; then
                    echo "Installing ARM64-compatible Flatpak apps for GNOME..."
                    sudo -u "$yay_user" flatpak install -y flathub org.videolan.VLC
                    sudo -u "$yay_user" flatpak install -y flathub org.signal.Signal
                    sudo -u "$yay_user" flatpak install -y flathub com.github.tchx84.Flatseal
                    sudo -u "$yay_user" flatpak install -y flathub org.gnome.Calculator
                    sudo -u "$yay_user" flatpak install -y flathub org.gnome.TextEditor
                    echo "ARM64-compatible Flatpak apps installed!"
                fi
            else
                echo "Flatpak is not installed, skipping Flatpak app install."
            fi
        fi
    else
        pacman -S --noconfirm git base-devel || { echo "Failed to install build tools for yay. Skipping yay." | tee -a "$LOGFILE"; }
        # List all non-system users (UID >= 1000, except nologin)
        users=$(awk -F: '$3 >= 1000 && $7 !~ /nologin/ {print $1}' /etc/passwd)
        if [[ -z "$users" ]]; then
            echo "No regular users found. Skipping yay and additional flatpak apps."
        else
            echo "Available users for yay install:"
            select yay_user in $users; do
                break
            done
            if [[ -n "$yay_user" ]]; then
                sudo -u "$yay_user" bash -c '
                    cd ~
                    git clone https://aur.archlinux.org/yay.git
                    cd yay
                    makepkg -si --noconfirm
                '
                echo "yay installed successfully!"
                if command -v flatpak >/dev/null 2>&1; then
                    # Install ARM64-compatible Flatpak apps for GNOME
                    if [[ $de_choice == "1" ]]; then
                        echo "Installing ARM64-compatible Flatpak apps for GNOME..."
                        sudo -u "$yay_user" flatpak install -y flathub org.videolan.VLC
                        sudo -u "$yay_user" flatpak install -y flathub org.mozilla.Thunderbird
                        sudo -u "$yay_user" flatpak install -y flathub org.signal.Signal
                        sudo -u "$yay_user" flatpak install -y flathub com.github.tchx84.Flatseal
                        sudo -u "$yay_user" flatpak install -y flathub org.gnome.Calculator
                        sudo -u "$yay_user" flatpak install -y flathub org.gnome.TextEditor
                        echo "ARM64-compatible Flatpak apps installed!"
                    fi
                else
                    echo "Flatpak is not installed, skipping Flatpak app install."
                fi
                
                # Install useful AUR packages for ARM64
                echo "Installing useful AUR packages for ARM64..."
                if command -v yay >/dev/null 2>&1; then
                    sudo -u "$yay_user" yay -S --noconfirm visual-studio-code-bin
                    echo "AUR packages installed!"
                else
                    echo "yay is not available, skipping AUR package install."
                fi
            fi
        fi
    fi
fi

# Install additional useful native packages
echo "Installing additional useful native packages for ARM64..."
if ! pacman -S --noconfirm \
    htop tree vim nano \
    git curl wget rsync \
    mpv imagemagick \
    transmission-cli transmission-gtk \
    gnome-calculator gnome-text-editor \
    evolution evolution-ews \
    simple-scan gnome-screenshot \
    &>>"$LOGFILE"; then
    echo "Failed to install some additional packages. Continuing..."
fi

# ARM64 specific optimizations
echo "Applying ARM64 specific optimizations..."

# Remove unavailable performance tools for ARM64
if ! pacman -S --noconfirm \
    powertop \
    iotop \
    &>>"$LOGFILE"; then
    echo "Failed to install performance tools. Continuing..."
fi

# Wayland and ARM/Qualcomm drivers (remove mesa-opencl-icd)
if ! pacman -S --noconfirm \
    wayland wayland-protocols \
    qt5-wayland qt6-wayland \
    mesa mesa-utils \
    vulkan-freedreno vulkan-icd-loader \
    libdrm libglvnd \
    libva-mesa-driver mesa-vdpau \
    libinput xf86-input-libinput \
    xf86-video-fbdev xf86-video-vesa \
    clinfo \
    &>>"$LOGFILE"; then
    echo "Failed to install Wayland/ARM/Qualcomm drivers. Continuing..."
fi

# Suggestion: Offer to install sway (Wayland compositor)
read -p "Do you want to install sway (Wayland compositor, minimal desktop)? (y/n): " install_sway
if [[ $install_sway == "y" || $install_sway == "Y" ]]; then
    if ! pacman -S --noconfirm sway swaybg swaylock swayidle foot dmenu greetd greetd-tuigreet &>>"$LOGFILE"; then
        echo "Warning: Failed to install sway or related packages. Continuing..."
    fi
    systemctl enable greetd &>>"$LOGFILE" || echo "Warning: Failed to enable greetd."
    echo "Sway and greetd installed. You can customize sway config in ~/.config/sway/"
fi

# Set up display scaling to 2 for better performance and readability
echo ""
echo "=== Setting up display scaling ==="
read -p "Would you like to configure display scaling for optimal tablet experience? (y/n): " scale_choice
if [[ $scale_choice == "y" || $scale_choice == "Y" ]]; then
    if [[ $de_choice == "1" ]]; then
        # GNOME scaling setup
        mkdir -p /etc/dconf/db/local.d
        cat > /etc/dconf/db/local.d/00-scaling << EOF
[org/gnome/desktop/interface]
scaling-factor=uint32 2

[org/gnome/mutter]
experimental-features=['scale-monitor-framebuffer']
EOF
        dconf update &>>"$LOGFILE"
        echo "GNOME scaling configured. You can adjust this in Settings > Displays after login."
    elif [[ $de_choice == "2" ]]; then
        echo "KDE Plasma scaling can be adjusted in System Settings > Display and Monitor after login."
        echo "Recommended: Set scaling to 200% for optimal tablet experience."
    fi
else
    echo "Skipping display scaling configuration."
fi

echo ""
echo "=== Kernel Update Information ==="
echo "Current kernel modules have been updated to 6.14.9."
echo ""
echo "NOTE: We are working on a seamless kernel update system."
echo "In the future, you will be able to update the kernel simply by running:"
echo "  pipa -arch -update"
echo ""
echo "This will automatically download and install the latest kernel modules"
echo "and system updates specifically optimized for the Xiaomi Pad 6."

echo ""
echo "=== Setup Completed ==="
echo "Your Arch Linux system on Xiaomi Pad 6 has been set up successfully!"
echo ""
if [[ -s "$LOGFILE" ]]; then
    echo "Some warnings or errors occurred during installation."
    echo "Check $LOGFILE for detailed information."
fi
echo ""
echo "MAC address randomization is available via macchanger if needed."
