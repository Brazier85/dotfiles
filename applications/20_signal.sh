if [ "$BASE_DISTRO" = "debian" ]; then
    if ! is_package_installed "signal-desktop"; then
        wget -qO- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor >signal-desktop-keyring.gpg
        cat signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg >/dev/null
        echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' |
            sudo tee /etc/apt/sources.list.d/signal-xenial.list
        rm signal-desktop-keyring.gpg
        update_cache
        install_package signal-desktop
    fi
fi

if [ "$BASE_DISTRO" = "arch" ]; then
    if ! is_package_installed "signal-desktop"; then
        install_package signal-desktop
    fi
fi
