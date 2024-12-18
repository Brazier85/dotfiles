#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Change to the directory where the script is located
SCRIPT_DIR="$HOME/.dotfiles"
cd "$SCRIPT_DIR" || {
    echo "Failed to change directory to $SCRIPT_DIR"
    exit 1
}

# Import colors and logging functions
source "$SCRIPT_DIR/colors.sh"
source "$SCRIPT_DIR/log.sh"

# Directories
APPLICATIONS_ALL_DIR="$SCRIPT_DIR/applications/all"
APPLICATIONS_ARCH_DIR="$SCRIPT_DIR/applications/arch"
APPLICATIONS_DEB_DIR="$SCRIPT_DIR/applications/deb"
APPLICATIONS_FED_DIR="$SCRIPT_DIR/applications/fedora"
APPLICATIONS_WSL_DIR="$SCRIPT_DIR/applications/wsl"

# Desktop features
APPLICATIONS_GNOME_DIR_ALL="$SCRIPT_DIR/applications/gnome_all"
APPLICATIONS_GNOME_DIR_ARCH="$SCRIPT_DIR/applications/gnome_arch"
APPLICATIONS_GNOME_DIR_DEB="$SCRIPT_DIR/applications/gnome_deb"
APPLICATIONS_GNOME_DIR_FEDORA="$SCRIPT_DIR/applications/gnome_fedora"
APPLICATIONS_HYPRLAND_DIR="$SCRIPT_DIR/applications/hyprland"
APPLICATIONS_FLATPAK_DIR="$SCRIPT_DIR/applications/flatpak"

# Base config dir
CONFIG_DIR="$SCRIPT_DIR/config"

# Determine distribution and environment
DISTRO=$(source /etc/os-release 2>/dev/null && echo $ID || {
    log "ERROR" "Unknown Linux distribution"
    exit 1
})
IS_WSL=$(grep -qiE "(Microsoft|WSL)" /proc/version && echo true || echo false)
RUNNING_GNOME=$([[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] && echo true || echo false)
RUNNING_HYPRLAND=$([[ "$XDG_CURRENT_DESKTOP" == *"Hyprland"* ]] && echo true || echo false)
SHOW_DEBUG=false

# Set the IS_ONLINE variable (true to check for internet, false to skip)
IS_ONLINE=true

# Determine the hostname and configuration file path
HOSTNAME=$(hostname)
CONFIG_FILE="$SCRIPT_DIR/config/hosts/${HOSTNAME}.conf"

# Make sure $WORK is unset
unset WORK

# Parse script arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --work)
        WORK=true
        shift # Move to the next argument
        ;;
    --run-all)
        RUN_ALL=true
        shift # Move to the next argument
        ;;
    --file)
        SCRIPT_FILE="$2"
        shift 2 # Move to the next argument after the file name
        ;;
    *)
        log "WARNING" "Unknown option: $1"
        shift # Move to the next argument
        ;;
    esac
done

# Installation function based on distribution
install_package() {
    local package="$1"
    case "$DISTRO" in
    ubuntu | debian) cmd="sudo apt-get install -qq -y $package" ;;
    fedora) cmd="sudo dnf install -y $package" ;;
    arch) cmd="sudo pacman -Syu --noconfirm $package" ;;
    manjaro) cmd="sudo pamac install --no-confirm $package" ;;
    *)
        log "ERROR" "Unsupported distribution: $DISTRO"
        return 1
        ;;
    esac

    eval "$cmd" && log "SUCCESS" "$package installed" || log "ERROR" "Failed to install $package"
}

# Function to update package cache
update_cache() {
    case "$DISTRO" in
    ubuntu | debian) cmd="sudo apt-get -qq update" ;;
    fedora) cmd="sudo dnf makecache" ;;
    arch) cmd="sudo pacman -Syy" ;;
    manjaro) cmd="sudo pamac update" ;;
    *)
        log "ERROR" "Unsupported distribution: $DISTRO"
        return 1
        ;;
    esac

    eval "$cmd" && log "SUCCESS" "Package cache updated" || log "ERROR" "Failed to update package cache"
}

# Function to upgrade the system based on distribution
system_upgrade() {
    case "$DISTRO" in
    ubuntu | debian) sudo apt-get update -qq && sudo apt-get upgrade -qq -y ;;
    fedora) sudo dnf upgrade -y ;;
    arch | manjaro) sudo pacman -Syu --noconfirm ;;
    manjaro) sudo pamac upgrade --no-confirm ;;
    *)
        log "ERROR" "Unsupported distro: $DISTRO"
        return 1
        ;;
    esac
    log "SUCCESS" "System upgrade complete."
}

# Function to check if a package is installed
is_package_installed() {
    local package="$1"

    # Check if the package is installed using the native package manager
    case "$DISTRO" in
    ubuntu | debian) dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed" ;;
    fedora) rpm -q "$package" &>/dev/null ;;
    arch | manjaro) pacman -Q "$package" &>/dev/null ;;
    *)
        log "ERROR" "Unsupported distribution: $DISTRO"
        return 1
        ;;
    esac && {
        log "DEBUG" "Package '$package' is installed"
        return 0
    }

    # Check if 'snap' or 'flatpak' is installed and verify package presence
    for cmd in snap flatpak; do
        if command -v "$cmd" &>/dev/null; then
            if [ "$cmd" = "snap" ]; then
                if snap list "$package" &>/dev/null; then
                    log "DEBUG" "Package '$package' is installed via Snap"
                    return 0
                fi
            elif [ "$cmd" = "flatpak" ]; then
                if flatpak list --app | grep -qw "$package"; then
                    log "DEBUG" "Package '$package' is installed via Flatpak"
                    return 0
                fi
            fi
        fi
    done

    log "INFO" "Package '$package' is not installed"
    return 1
}

# Do we need to reboot?
check_reboot_needed() {
    # Check for systemd reboot required flag
    if [ -f /run/reboot-required ]; then
        log "WARNING" "Reboot required: /run/reboot-required exists"
        reboot_prompt "System update requires a reboot to complete."
        return 0
    fi

    # Check if there's a need to reboot based on package manager status
    if [ -f /var/run/reboot-required ]; then
        log "WARNING" "Reboot required: /var/run/reboot-required exists"
        reboot_prompt "System update requires a reboot to complete."
        return 0
    fi

    log "INFO" "No reboot required or could not determine"
    return 1
}

# Ask user for a reboot
reboot_prompt() {
    local reason="$1"

    if command -v whiptail &>/dev/null; then
        if whiptail --title "Reboot Required" \
            --yesno "$reason\n\nDo you want to reboot now?" 10 50; then
            log "INFO" "User chose to reboot"
            sudo reboot
        else
            log "CINFO" "User chose not to reboot"
        fi
    else
        log "ERROR" "Whiptail is not installed. Unable to show reboot prompt."
    fi
}

# Function to ensure sudo access
has_sudo_access() {
    sudo -v && return 0 || return 1
}

# Function to execute command with or without sudo
retry_with_sudo() {
    local cmd="$1"
    eval "$cmd" || {
        [[ "$cmd" =~ mkdir && -d "${cmd##* }" ]] && return 0
        sudo bash -c "$cmd"
    }
}

# Function to determine non-root user
get_non_root_user() {
    local user=$(whoami 2>/dev/null || id -un 2>/dev/null || logname 2>/dev/null)
    [[ "$user" != "root" ]] && echo "$user" || {
        log "ERROR" "Cannot run as root"
        exit 1
    }
}

# Create a symlink
create_symlink() {
    local target="$1"    # Target of the symlink
    local link_name="$2" # Name of the symlink

    # Remove existing file or symlink at the target location if it exists
    if [ -e "$link_name" ] || [ -L "$link_name" ]; then
        log "DEBUG" "Removing existing file or symlink $link_name"
        retry_with_sudo "rm -rf \"$link_name\""
        if [ $? -ne 0 ]; then
            log "ERROR" "Error removing $link_name"
            return 1
        fi
    fi

    # Create the symlink
    retry_with_sudo "ln -s \"$target\" \"$link_name\""
    if [ $? -eq 0 ]; then
        log "SUCCESS" "Symlink $link_name -> $target created successfully"
    else
        log "ERROR" "Error creating symlink $link_name -> $target"
        return 1
    fi
}

# Function to clone or update repository
clone_repository() {
    local repo_url="$1" target_dir="$2"
    if [ -d "$target_dir" ]; then
        if [ "$IS_ONLINE" = true ]; then
            log "INFO" "Updating repository in $target_dir"
            git -C "$target_dir" pull --quiet >/dev/null
        else
            log "WARNING" "We are offline. I can not update"
        fi
    else
        log "INFO" "Cloning repository $repo_url into $target_dir"
        git clone --quiet "$repo_url" "$target_dir" >/dev/null
    fi
}

# Function to ensure directories exist
ensure_directories() {
    for dir in "$@"; do
        log "DEBUG" "Making sure ${dir} exists"
        [[ ! -d "$dir" ]] && retry_with_sudo "mkdir -p \"$dir\""
        log "DEBUG" "${dir} exists"
    done
}

# Function to run a single script based on the --file option
run_single_script() {
    local script_name="${SCRIPT_FILE:-""}"

    # Check if SCRIPT_FILE is provided
    if [[ -z "$script_name" ]]; then
        log "ERROR" "No script specified. Use the --file option to specify a script."
        return 1
    fi

    # Search for the script starting from the current directory
    local script_path
    script_path=$(find ./applications/ -type f -name "*$script_name*" 2>/dev/null | head -n 1)

    # Check if the script was found
    if [[ -z "$script_path" ]]; then
        log "ERROR" "Script $script_name not found in any directory."
        return 1
    fi

    # Check if multiple scripts with the same name were found
    local script_count
    script_count=$(find ./applications/ -type f -name "$script_name" 2>/dev/null | wc -l)

    if ((script_count > 1)); then
        log "ERROR" "Multiple scripts named $script_name found. Please specify a unique script."
        return 1
    fi

    # If the script was found, run it
    if [[ -f "$script_path" ]]; then
        log "INFO" "Running script $script_path"
        if ! source "$script_path"; then
            log "ERROR" "Error occurred while running $script_name"
            return 1
        fi
    else
        log "ERROR" "$script_path is not a regular file."
        return 1
    fi
}

# Function to run application scripts
run_scripts_in_directory() {
    local directory="$1"
    local run_all="${RUN_ALL:-false}" # Check if RUN_ALL is set, default to false

    # Check if the directory exists
    if [[ ! -d "$directory" ]]; then
        log "ERROR" "Directory $directory not found"
        return 1
    else
        log "CINFO" "Running scripts in $directory"
    fi

    # Loop through each .sh file in the directory
    for script in "$directory"/*.sh; do
        # If there are no .sh files, exit
        if [[ "$script" == "$directory/*.sh" ]]; then
            log "INFO" "No .sh files found in $directory"
            return 0
        fi

        # Check if the file is a regular file
        if [[ -f "$script" ]]; then
            script_name=$(basename "$script")
            prefix=$(echo "$script_name" | grep -oE '^[0-9]+' | awk '{print $1}')
            description=$(head -n 1 "$script" | sed 's/^# //')

            # Remove leading zeros from the prefix
            # prefix=$((10#$prefix))

            # Check if the script is blacklisted
            if is_blacklisted "$script_name"; then
                log "WARNING" "Skipping blacklisted script $script_name"
                continue
            fi

            # If RUN_ALL is true, source the script directly
            if [[ "$run_all" == true ]]; then
                log "INFO" "RUN_ALL is set. Running $script_name"
                if ! source "$script"; then
                    log "ERROR" "Error occurred while running $script"
                    return 1
                fi
                continue
            fi

            # Check if the prefix is within the specified range
            if ((prefix >= 50 && prefix < 90)); then
                # Prepare message for whiptail
                message=$(printf "Script: %s\n\nDescription:\n%s" "$script_name" "$description")
                if whiptail --title "Source Script" --yes-button "Yes" --no-button "No" --yesno "$message" 15 60; then
                    log "INFO" "Running $script_name"
                    if ! source "$script"; then
                        log "ERROR" "Error occurred while running $script"
                        return 1
                    fi
                else
                    log "INFO" "Skipping $script"
                fi
            else
                # Automatically run scripts not in the range 50-89
                log "INFO" "Running $script_name"
                if ! source "$script"; then
                    log "ERROR" "Error occurred while running $script"
                    return 1
                fi
            fi
        else
            log "WARNING" "$script is not a regular file"
        fi
    done
}

# Function to update the script
update_script() {
    log "INFO" "Checking for script updates..."

    # Store the current commit hash
    local current_commit
    current_commit=$(git rev-parse HEAD)

    # Pull the latest changes from the repository
    if ! git pull --quiet >/dev/null; then
        log "ERROR" "Failed to update the script repository"
        log "WARNING" "Using local version"
    else
        # Check the new commit hash and message
        local new_commit
        local new_commit_message
        new_commit=$(git rev-parse HEAD)
        new_commit_message=$(git log -1 --pretty=format:"%s" "$new_commit")

        # Compare the current and new commit hashes
        if [ "$current_commit" != "$new_commit" ]; then
            # Show a whiptail dialog informing about the update
            whiptail --title "Script Updated" \
                --msgbox "The script has been updated to the latest version.\n\nNew commit: $new_commit\nCommit message: $new_commit_message\n\nPlease restart the script to apply the changes." 15 60

            log "INFO" "Script updated to the latest version."
            log "INFO" "New commit: $new_commit"
            log "INFO" "Commit message: $new_commit_message"

            # Exit the script
            log "ERROR" "Script needs to restart!"
            exit 0
        else
            log "DEBUG" "Script is already up-to-date."
        fi
    fi
}

# Function to create a default configuration file
create_default_config() {
    log "INFO" "Creating default configuration file at $CONFIG_FILE"
    echo -e "# Blacklisted scripts\nblacklist=()" >"$CONFIG_FILE"
}

# Function to load configuration file
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log "INFO" "Loading configuration from $(basename "$CONFIG_FILE")"
        source "$CONFIG_FILE"
    else
        create_default_config
        log "INFO" "Default configuration file created. Reloading..."
        source "$CONFIG_FILE"
    fi
}

# Function to check if a script is blacklisted
is_blacklisted() {
    local script_name="$1"
    for blacklisted_script in "${blacklist[@]}"; do
        if [[ "$script_name" =~ "$blacklisted_script" ]]; then
            return 0 # Script is blacklisted
        fi
    done
    return 1 # Script is not blacklisted
}

# Function to check for internet connectivity
check_online() {
    ping -q -c1 google.com &>/dev/null && IS_ONLINE=true || IS_ONLINE=false

    if [ "$IS_ONLINE" = true ]; then
        log "INFO" "We are online"
    else
        log "WARNING" "We are offline"
    fi
}

# Main process
main() {
    log "INFO" "Starting bootstrap process for $DISTRO"

    # Are we online
    check_online

    # Update main repo
    update_script

    # Load or create configuration file
    load_config

    # Check for sudo access
    has_sudo_access || {
        log "ERROR" "No sudo access"
        exit 1
    }

    # Get current running user
    USER=$(get_non_root_user)
    if [ $? -eq 0 ]; then
        log "INFO" "Current user: $USER"
    else
        log "ERROR" "Failed to determine a non-root user."
        exit 1
    fi

    # Are we in GNOME?
    if $RUNNING_GNOME; then
        # Ensure computer doesn't go to sleep or lock while installing
        gsettings set org.gnome.desktop.screensaver lock-enabled false
        gsettings set org.gnome.desktop.session idle-delay 0
    fi

    # Doing system update
    log "INFO" "Running system update"
    log "INFO" "This may take a while..."
    system_upgrade

    # Single script or folder scripts
    if [ -n "$SCRIPT_FILE" ]; then
        log "DEBUG" "Running single script mode"
        run_single_script $SCRIPT_FILE
    else
        # Install universal applications
        run_scripts_in_directory "$APPLICATIONS_ALL_DIR"

        # Install distribution-specific applications
        case "$DISTRO" in
        arch | manjaro)
            run_scripts_in_directory "$APPLICATIONS_ARCH_DIR"
            ;;
        ubuntu | debian)
            run_scripts_in_directory "$APPLICATIONS_DEB_DIR"
            ;;
        fedora)
            run_scripts_in_directory "$APPLICATIONS_FED_DIR"
            ;;
        *)
            log "WARNING" "No specific scripts found for $DISTRO"
            ;;
        esac

        # Install WSL-specific applications if WSL is detected
        if [ "$IS_WSL" = true ]; then
            run_scripts_in_directory "$APPLICATIONS_WSL_DIR"
        fi

        # If on gnome
        if $RUNNING_GNOME; then
            # Install desktop tools and tweaks
            run_scripts_in_directory "$APPLICATIONS_GNOME_DIR_ALL"

            case "$DISTRO" in
            arch | manjaro)
                run_scripts_in_directory "$APPLICATIONS_GNOME_DIR_ARCH"
                ;;
            ubuntu | debian)
                un_scripts_in_directory "$APPLICATIONS_GNOME_DIR_DEB"
                ;;
            fedora)
                run_scripts_in_directory "$APPLICATIONS_GNOME_DIR_FEDORA"
                ;;
            *)
                log "WARNING" "No specific scripts found for $DISTRO"
                ;;
            esac

            run_scripts_in_directory "$APPLICATIONS_FLATPAK_DIR"
        fi

        if $RUNNING_HYPRLAND; then
            run_scripts_in_directory "$APPLICATIONS_HYPRLAND_DIR"

            run_scripts_in_directory "$APPLICATIONS_FLATPAK_DIR"
        fi
    fi

    # If on gnome
    if $RUNNING_GNOME; then
        # Revert to normal idle and lock settings
        gsettings set org.gnome.desktop.screensaver lock-enabled true
        gsettings set org.gnome.desktop.session idle-delay 900
    fi

    log "SUCCESS" "Bootstrap process completed"

    # Do we need a reboot?
    check_reboot_needed
}

# Execute the script
main
