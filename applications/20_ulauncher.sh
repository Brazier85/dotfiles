if $RUNNING_GNOME; then

    if [[ "$BASE_DISTRO" =~ ^(fedora|arch) ]]; then
        if ! is_package_installed "ulauncher"; then
            install_package ulauncher
        fi
    fi

    if [ "$BASE_DISTRO" = "debian" ]; then
        if ! is_package_installed "ulauncher"; then
            sudo add-apt-repository universe -y
            sudo add-apt-repository ppa:agornostal/ulauncher -y
            update_cache
            install_package ulauncher
            install_package wmctrl
        fi
    fi

fi
