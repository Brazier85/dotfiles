#!/bin/bash

nvidia_pkg=(
    akmod-nvidia
    xorg-x11-drv-nvidia-cuda
    libva
    libva-nvidia-driver
)


# Install additional Nvidia packages
for NVIDIA in "${nvidia_pkg[@]}"; do
    install_package "$NVIDIA"
    if [ $? -ne 0 ]; then
        log "ERROR" "${ERROR} - $NVIDIA Installation failed. Check the install log."
        exit 1
    fi
done

log "WARNING" "Adding nvidia-stuff to /etc/default/grub..."

# Additional options to add to GRUB_CMDLINE_LINUX
additional_options="rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1 nvidia_drm.fbdev=1"

# Check if additional options are already present in GRUB_CMDLINE_LINUX
if grep -q "GRUB_CMDLINE_LINUX.*$additional_options" /etc/default/grub; then
    echo "GRUB_CMDLINE_LINUX already contains the additional options" 2>&1 | tee -a "$LOG"
else
    # Append the additional options to GRUB_CMDLINE_LINUX
    sudo sed -i "s/GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"$additional_options /" /etc/default/grub
    echo "Added the additional options to GRUB_CMDLINE_LINUX" 2>&1 | tee -a "$LOG"
fi

# Update GRUB configuration
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

log "CINFO" "Nvidia DRM modeset and additional options have been added to /etc/default/grub. Please reboot for changes to take effect."
