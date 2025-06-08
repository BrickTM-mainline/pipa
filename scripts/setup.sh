#!/bin/bash

# Define log file for error tracking
LOGFILE="/tmp/arch_setup.log"

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
    nmcli device wifi connect "$ssid" password "$password"

    if [ $? -eq 0 ]; then
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
if ! ping -c 1 archlinux.org &> /dev/null; then
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
pacman -Syu --noconfirm || { echo "Failed to update packages. Exiting."; exit 1; }

# Basic packages (Wayland only)
echo ""
echo "=== Installing basic packages ==="
pacman -S --noconfirm mesa vulkan-freedreno sudo networkmanager bluez bluez-utils fastfetch 2>>"$LOGFILE" || { echo "Failed to install basic packages. Exiting." | tee -a "$LOGFILE"; exit 1; }

# Enable essential services with logging
systemctl enable NetworkManager 2>>"$LOGFILE"
systemctl enable bluetooth 2>>"$LOGFILE"

# Download and install fixed BlueZ packages
echo "Downloading and installing fixed BlueZ packages..."
cd /tmp
wget -nc https://github.com/BrickTM-mainline/pipa/releases/download/1.1/bluez-5.82-1-aarch64.pkg.tar.xz
wget -nc https://github.com/BrickTM-mainline/pipa/releases/download/1.1/bluez-libs-5.82-1-aarch64.pkg.tar.xz
wget -nc https://github.com/BrickTM-mainline/pipa/releases/download/1.1/bluez-tools-0.2.0-6-aarch64.pkg.tar.xz
wget -nc https://github.com/BrickTM-mainline/pipa/releases/download/1.1/bluez-utils-5.82-1-aarch64.pkg.tar.xz
pacman -U --noconfirm bluez-5.82-1-aarch64.pkg.tar.xz bluez-libs-5.82-1-aarch64.pkg.tar.xz bluez-tools-0.2.0-6-aarch64.pkg.tar.xz bluez-utils-5.82-1-aarch64.pkg.tar.xz 2>>"$LOGFILE"

# Desktop Environment Selection (Wayland only)
echo ""
echo "=== Desktop Environment Selection (Wayland Only) ==="
echo "Please select a desktop environment to install:"
echo "1) GNOME (Wayland, RECOMMENDED)"
echo "2) KDE Plasma (Wayland)"
echo "3) LXQt (Wayland, experimental)"
echo "4) XFCE (Wayland, requires XWayland)"
echo ""
read -p "Enter your choice (1-4): " de_choice

# Terminal Selection (Wayland compatible)
echo ""
echo "=== Terminal Selection ==="
echo "Please select a terminal to install:"
echo "1) GNOME Terminal"
echo "2) Konsole (KDE's terminal, Wayland compatible)"
echo "3) QTerminal (LXQt's terminal, may require XWayland)"
echo "4) Alacritty (Wayland compatible)"
echo "5) Kitty (Wayland compatible)"
echo "6) Wezterm (Wayland compatible)"
echo "7) Foot (Wayland compatible)"
read -p "Enter your choice (1-7): " term_choice

# Install Firefox browser and common applications
echo "Installing Firefox browser, fastfetch, and common desktop applications..."
pacman -S --noconfirm firefox gvfs gvfs-mtp pulseaudio pavucontrol xdg-user-dirs fastfetch || { echo "Failed to install common applications. Exiting."; exit 1; }

# Install selected terminal
case $term_choice in
    1)
        echo "Installing GNOME Terminal..."
        pacman -S --noconfirm gnome-terminal
        ;;
    2)
        echo "Installing Konsole terminal..."
        pacman -S --noconfirm konsole
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
    7)
        echo "Installing Foot terminal..."
        pacman -S --noconfirm foot
        ;;
    *)
        echo "Invalid choice. Installing default terminal based on DE."
        ;;
esac

# Install extra fonts and emojis
echo "Installing extra fonts and emoji support..."
pacman -S --noconfirm noto-fonts noto-fonts-emoji ttf-dejavu || { echo "Failed to install fonts. Continuing..."; }

# Optionally install AppleColorEmoji.ttf (iOS emojis)
read -p "Do you want to install iOS (Apple) emojis? (y/n): " install_apple_emoji
if [[ $install_apple_emoji == "y" || $install_apple_emoji == "Y" ]]; then
    mkdir -p /usr/share/fonts/apple-emoji
    wget -nc https://github.com/samuelngs/apple-emoji-linux/releases/download/v18.4/AppleColorEmoji.ttf -O /usr/share/fonts/apple-emoji/AppleColorEmoji.ttf
    fc-cache -fv
    echo "AppleColorEmoji.ttf installed."
fi

# Install power management and brightness control
echo "Installing power management and brightness control tools..."
pacman -S --noconfirm tlp brightnessctl || { echo "Failed to install power/brightness tools. Continuing..."; }
systemctl enable tlp

# Install blueman for Bluetooth GUI
echo "Installing blueman Bluetooth manager..."
pacman -S --noconfirm blueman || { echo "Failed to install blueman. Continuing..."; }

# Install Wayland screenshot tools and scrcpy
echo "Installing Wayland screenshot tools (grim, slurp) and scrcpy..."
pacman -S --noconfirm grim slurp scrcpy || { echo "Failed to install screenshot tools or scrcpy. Continuing..."; }

# Install gtop (system monitoring), btop (modern system monitor), and nemo (GNOME file manager)
echo "Installing gtop, btop (system monitors), and nemo (file manager for GNOME)..."
pacman -S --noconfirm gtop btop nemo || { echo "Failed to install gtop, btop, or nemo. Continuing..."; }

# Desktop Environment Installation (Wayland only)
case $de_choice in
    1)
        echo "Installing GNOME (Wayland)..."
        # Install GNOME dependencies (Flatpak, malcontent, ostree)
        echo "Installing GNOME dependencies (Flatpak, malcontent, ostree)..."
        pacman -S --noconfirm flatpak ostree malcontent appstream \
            libappstream-glib appstream-glib bubblewrap xdg-dbus-proxy \
            dconf dconf-editor gsettings-desktop-schemas \
            polkit accountsservice 2>>"$LOGFILE" || echo "Warning: Failed to install some GNOME dependencies." | tee -a "$LOGFILE"
        
        # Install GNOME core group and recommended extras for icons/themes
        pacman -S --noconfirm gnome gnome-extra gnome-tweaks gdm \
            adwaita-icon-theme gnome-icon-theme gnome-themes-extra papirus-icon-theme \
            wayland wayland-protocols xdg-desktop-portal xdg-desktop-portal-gnome \
            gtk3 gtk4 qt5-wayland qt6-wayland breeze breeze-icons onboard \
            gnome-software gnome-software-packagekit-plugin 2>>"$LOGFILE" \
            || echo "Warning: Failed to install some GNOME packages. Continuing..." | tee -a "$LOGFILE"
        
        # Enable Flatpak system-wide
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        
        # Enable GDM for GNOME
        systemctl enable gdm 2>>"$LOGFILE"
        echo "GNOME with full Flatpak support and GDM greeter installed successfully!"
        ;;
    2)
        echo "Installing KDE Plasma (Wayland)..."
        pacman -S --noconfirm plasma plasma-wayland-session plasma-pa plasma-nm plasma-desktop dolphin kate wayland wayland-protocols qt5-wayland qt6-wayland xdg-desktop-portal xdg-desktop-portal-kde wlroots breeze breeze-icons sddm sddm-kcm qtvirtualkeyboard 2>>"$LOGFILE" || echo "Warning: Failed to install some KDE Plasma packages. Continuing..." | tee -a "$LOGFILE"
        mkdir -p /etc/sddm.conf.d/
        cat > /etc/sddm.conf.d/kde_settings.conf << EOF
[General]
Session=plasmawayland

[Theme]
Current=breeze

[Wayland]
EnableHiDPI=true
EOF
        systemctl enable sddm 2>>"$LOGFILE"
        ;;
    3)
        echo "Installing LXQt (Wayland, experimental)..."
        echo "Warning: LXQt native Wayland support is experimental. You may experience instability."
        pacman -S --noconfirm lxqt lxqt-admin lxqt-config lxqt-globalkeys lxqt-panel lxqt-runner breeze-icons pcmanfm-qt wayland wayland-protocols qt5-wayland qt6-wayland xdg-desktop-portal xdg-desktop-portal-wlr wlroots sddm sddm-kcm xorg-xwayland 2>>"$LOGFILE" || echo "Warning: Failed to install some LXQt packages. Continuing..." | tee -a "$LOGFILE"
        mkdir -p /etc/sddm.conf.d/
        cat > /etc/sddm.conf.d/lxqt_settings.conf << EOF
[General]
Session=lxqt

[Theme]
Current=breeze

[Wayland]
EnableHiDPI=true
EOF
        systemctl enable sddm 2>>"$LOGFILE"
        ;;
    4)
        echo "Installing XFCE (Wayland, requires XWayland)..."
        echo "Note: XFCE does not natively support Wayland, but can run under XWayland."
        pacman -S --noconfirm xfce4 xfce4-goodies xfdesktop xfwm4 xfce4-session network-manager-applet xfce4-power-manager wayland wayland-protocols xdg-desktop-portal xdg-desktop-portal-wlr wlroots sddm sddm-kcm xorg-xwayland breeze breeze-icons 2>>"$LOGFILE" || echo "Warning: Failed to install some XFCE packages. Continuing..." | tee -a "$LOGFILE"
        mkdir -p /etc/sddm.conf.d/
        cat > /etc/sddm.conf.d/xfce_settings.conf << EOF
[General]
Session=xfce

[Theme]
Current=breeze

[Wayland]
EnableHiDPI=true
EOF
        systemctl enable sddm 2>>"$LOGFILE"
        ;;
    *)
        echo "Invalid choice. Exiting." | tee -a "$LOGFILE"
        exit 1
        ;;
esac

echo "Display manager has been installed and enabled for the selected desktop environment."

# Display scaling for Wayland/XWayland
echo ""
echo "=== Display Scaling Setup ==="
if [[ $de_choice == "1" ]]; then
    echo "For GNOME, set scaling in Settings > Displays after login."
elif [[ $de_choice == "2" ]]; then
    echo "For KDE Plasma, set scaling in System Settings > Display and Monitor > Display Configuration after login."
elif [[ $de_choice == "3" || $de_choice == "4" ]]; then
    echo "For wlroots-based compositors (LXQt/experimental, XFCE/XWayland), you can use wlr-randr for scaling."
    echo "Example: wlr-randr --output DSI-1 --scale 0.5"
    echo "Note: xrandr is for Xorg/XWayland only. For XWayland, use:"
    echo "xrandr --output DSI-1 --scale 0.5x0.5"
    echo "If you are running under pure Wayland, use wlr-randr instead."
fi

# Kernel Update and Audio Fix
echo ""
echo "=== Arch Linux Kernel 6.14.2 Update ==="
echo "Downloading and extracting kernel modules..."
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

# Prompt to create a regular user
read -p "Do you want to create a new regular (non-root) user? (y/n): " create_user
if [[ $create_user == "y" || $create_user == "Y" ]]; then
    read -p "Enter the username for the new user: " new_username
    useradd -m -G wheel,audio,video,network -s /bin/bash "$new_username"
    echo "Set password for $new_username:"
    passwd "$new_username"
    echo "$new_username ALL=(ALL) ALL" >> /etc/sudoers.d/10-$new_username
    chmod 0440 /etc/sudoers.d/10-$new_username
    echo "User $new_username created and added to sudoers."
fi

# Prompt to create an additional root user
read -p "Do you want to create an additional root user? (y/n): " create_root_user
if [[ $create_root_user == "y" || $create_root_user == "Y" ]]; then
    read -p "Enter the username for the new root user: " root_username
    useradd -m -G wheel,audio,video,network -s /bin/bash "$root_username"
    echo "Set password for $root_username:"
    passwd "$root_username"
    usermod -aG root "$root_username"
    echo "$root_username ALL=(ALL) ALL" >> /etc/sudoers.d/10-$root_username
    chmod 0440 /etc/sudoers.d/10-$root_username
    echo "Root user $root_username created and added to sudoers and root group."
fi

# Install media codecs
echo "Installing media codecs..."
pacman -S --noconfirm gst-libav gst-plugins-ugly gst-plugins-bad ffmpeg || { echo "Failed to install codecs. Continuing..."; }

# Install archive utilities
echo "Installing archive utilities..."
pacman -S --noconfirm file-roller ark xarchiver unrar unzip p7zip || { echo "Failed to install archive utilities. Continuing..."; }

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
            echo "Flatpak is already installed system-wide."
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
            echo "No user selected. Skipping additional flatpak apps."
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
                
                # Install useful AUR packages for ARM64
                echo "Installing useful AUR packages for ARM64..."
                sudo -u "$yay_user" yay -S --noconfirm visual-studio-code-bin
                echo "AUR packages installed!"
            else
                echo "No user selected. Skipping yay and additional apps."
            fi
        fi
    fi
fi

# Install additional useful native packages
echo "Installing additional useful native packages for ARM64..."
pacman -S --noconfirm \
    neofetch htop tree vim nano \
    git curl wget rsync \
    mpv imagemagick \
    transmission-cli transmission-gtk \
    gnome-calculator gnome-text-editor \
    evolution evolution-ews \
    simple-scan gnome-screenshot \
    || { echo "Failed to install some additional packages. Continuing..."; }

# ARM64 specific optimizations
echo "Applying ARM64 specific optimizations..."
# Enable zswap for better memory management on ARM devices
echo 'zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=20' >> /etc/default/grub || true

# Install ARM64 performance tools
echo "Installing ARM64 performance monitoring tools..."
pacman -S --noconfirm \
    linux-cpupower \
    thermald \
    powertop \
    iotop \
    || { echo "Failed to install performance tools. Continuing..."; }

# Wayland and ARM/Qualcomm drivers (ensure all needed for best perf)
echo "Installing essential Wayland and ARM/Qualcomm drivers..."
pacman -S --noconfirm \
    wayland wayland-protocols \
    qt5-wayland qt6-wayland \
    mesa mesa-utils \
    vulkan-freedreno vulkan-icd-loader \
    libdrm libglvnd \
    libva-mesa-driver mesa-vdpau \
    libinput xf86-input-libinput \
    xf86-video-fbdev xf86-video-vesa \
    mesa-opencl-icd clinfo \
    || { echo "Failed to install Wayland/ARM/Qualcomm drivers. Continuing..."; }

# Suggestion: Offer to install sway (Wayland compositor)
read -p "Do you want to install sway (Wayland compositor, minimal desktop)? (y/n): " install_sway
if [[ $install_sway == "y" || $install_sway == "Y" ]]; then
    pacman -S --noconfirm sway swaybg swaylock swayidle foot dmenu greetd greetd-tuigreet 2>>"$LOGFILE" || echo "Warning: Failed to install sway or related packages. Continuing..." | tee -a "$LOGFILE"
    systemctl enable greetd 2>>"$LOGFILE"
    echo "Sway and greetd installed. You can customize sway config in ~/.config/sway/"
fi

# Set up display scaling to 2 for better performance and readability
echo ""
echo "=== Setting up display scaling ==="
echo "Setting display scaling to 2 for better performance..."

if [[ $de_choice == "1" ]]; then
    # GNOME scaling setup
    echo "Configuring GNOME scaling to 2..."
    mkdir -p /etc/dconf/db/local.d
    cat > /etc/dconf/db/local.d/00-scaling << EOF
[org/gnome/desktop/interface]
scaling-factor=uint32 2

[org/gnome/mutter]
experimental-features=['scale-monitor-framebuffer']
EOF
    dconf update
    echo "GNOME scaling set to 2. You can adjust this in Settings > Displays after login."
elif [[ $de_choice == "2" ]]; then
    echo "For KDE Plasma, scaling will be set to 200% automatically."
    echo "You can adjust this in System Settings > Display and Monitor after login."
elif [[ $de_choice == "3" || $de_choice == "4" ]]; then
    echo "For wlroots-based compositors, you can use:"
    echo "wlr-randr --output DSI-1 --scale 2.0"
    echo "Or for XWayland: xrandr --output DSI-1 --scale 2.0x2.0"
fi

echo ""
echo "=== Setup Completed ==="
echo "Your Arch Linux system on Xiaomi Pad 6 has been set up successfully!"
echo "The system will reboot in 10 seconds to apply changes."
echo "After reboot, you will be greeted with your new desktop environment."

sleep 10
reboot
