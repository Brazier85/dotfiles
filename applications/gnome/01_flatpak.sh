log "INFO" "Installing Flatpak"
install_package flatpak
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
install_package gnome-software-plugin-flatpak
log "SUCCESS" "Installined Flatpak"