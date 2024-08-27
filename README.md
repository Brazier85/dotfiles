# Dotfiles Bootstrapper

## Overview
This repository contains a bash script designed to manage your dotfiles and bootstrap your Linux environment. It supports multiple Linux distributions and environments, such as WSL and GNOME, providing an easy way to install applications, manage configurations, and keep your system up-to-date.

## Getting Started

### Prerequisites
Ensure you have `git` installed on your system before proceeding.

### Installation
Clone this repository to your home directory and run the bootstrap script:

```bash
git clone https://github.com/Brazier85/dotfiles_bash.git ~/.dotfiles \
&& cd ~/.dotfiles \
&& ./bootstrap.sh
```

### Running the Script
The script offers flexible options to tailor the setup process to your needs:

- `--work`: Applies `.work`-specific configurations if they exist, making it ideal for setting up a work environment.
- `--run-all`: Automatically runs all scripts in the specified directories without prompting for confirmation on scripts numbered 50 or above.
- `--file`: Enter the name of a single file like `git` and it will only run this file.

**Example usage:**

```bash
./bootstrap.sh --work --run-all

./bootstrap.sh --file zsh
```

### What the Script Does
- **Environment Detection:** Automatically detects your Linux distribution, whether you're running on WSL, and if you're using the GNOME desktop environment.
- **Package Management:** Handles package installations, system upgrades, and cache updates for Debian-based, Fedora, and Arch Linux distributions.
- **Script Execution:** Runs categorized application scripts (universal, distribution-specific, WSL-specific, GNOME-specific) to install and configure necessary tools and settings.
- **Symlink Management:** Creates symbolic links for your dotfiles, ensuring your configurations are in place.
- **Repository Management:** Automatically updates itself from the latest changes in the Git repository.
- **Reboot Handling:** After completing updates, it checks if a system reboot is required and prompts you accordingly.

## Custom Scripts

To extend the functionality of the bootstrap process, you can add custom scripts tailored to your specific needs. Here’s how to create and integrate these scripts effectively:

### Directory Structure
The bootstrap script organizes custom scripts into specific directories based on their purpose:

- **Universal Scripts:** `~/.dotfiles/applications/all/`
- **Distribution-Specific Scripts:**
  - Arch Linux: `~/.dotfiles/applications/arch/`
  - Debian/Ubuntu: `~/.dotfiles/applications/deb/`
- **WSL-Specific Scripts:** `~/.dotfiles/applications/wsl/`
- **GNOME-Specific Scripts:** `~/.dotfiles/applications/gnome/`

Place your custom `.sh` scripts in the appropriate directory based on where they should be executed.

### Naming Convention
To control the execution order and behavior of your scripts, adhere to the following naming conventions:

- **Prefix with Numbers:** Prefix your script filenames with numbers to define the order in which they should run. For example, `01_install_vim.sh`, `02_setup_git.sh`, etc.
  
- **Script Description:** Optionally, include a brief description after the numbering for clarity. For example, `50_customize_shell.sh`.

### Script Structure
Each custom script should follow a consistent structure to ensure compatibility with the bootstrap process. Here's a breakdown based on the provided TMUX installation example:

1. **Shebang:** Start with the shebang to specify the script interpreter.

   ```bash
   #!/bin/bash
   ```

2. **Logging:** Use the `log` function to provide informative messages throughout the script. This helps track the script's progress.

   ```bash
   log "INFO" "Installing TMUX..."
   ```

3. **Package Installation:** Use the `is_package_installed` function to check if a package is already installed. If not, install it using `install_package`.

   ```bash
   is_package_installed "tmux" || install_package "tmux"
   ```

4. **Repository Cloning:** Use the `clone_repository` function to clone any necessary repositories.

   ```bash
   clone_repository "https://github.com/gpakosz/.tmux.git" "$SCRIPT_DIR/repos/oh-my-tmux"
   ```

5. **Symlink Creation:** Use the `create_symlink` function to create symbolic links between the repository files and the user's home directory.

   ```bash
   create_symlink "$SCRIPT_DIR/repos/oh-my-tmux/.tmux.conf" "$HOME/.tmux.conf"
   create_symlink "$SCRIPT_DIR/config/tmux/tmux.conf.local" "$HOME/.tmux.conf.local"
   ```

6. **Completion Log:** End the script with a final log message indicating that the task is complete.

   ```bash
   log "INFO" "TMUX done"
   ```

### Example Custom Script

Here is an example script that follows the conventions above to install and configure TMUX:

**50_install_tmux.sh**

```bash
#!/bin/bash
# Script to install and configure TMUX

log "INFO" "Installing TMUX..."

# Install TMUX if not already installed
is_package_installed "tmux" || install_package "tmux"

# Clone the oh-my-tmux repository
clone_repository "https://github.com/gpakosz/.tmux.git" "$SCRIPT_DIR/repos/oh-my-tmux"

# Create symbolic links for TMUX configuration
create_symlink "$SCRIPT_DIR/repos/oh-my-tmux/.tmux.conf" "$HOME/.tmux.conf"
create_symlink "$SCRIPT_DIR/config/tmux/tmux.conf.local" "$HOME/.tmux.conf.local"

log "INFO" "TMUX done"
```

### Best Practices
- **Idempotency:** Ensure that your scripts can be run multiple times without causing unintended side effects. For example, check if a package is already installed before attempting to install it.
  
- **Error Handling:** Incorporate error checking after critical commands to handle failures gracefully. Use the provided `log` functions to report success or errors.

- **Modularity:** Keep scripts focused on a single task or related set of tasks. This makes them easier to manage and debug.

- **Documentation:** Comment your scripts to explain the purpose of commands and configurations. This aids in maintenance and helps others understand your setup.

## Why Use This Script?
This script provides a highly customizable, cross-distribution solution for managing dotfiles and bootstrapping your Linux environment. Unlike other tools, this script is written entirely in bash, ensuring it runs on virtually any Linux system without additional dependencies.

## Contributing
Feel free to fork this repository, submit issues, or create pull requests to improve this script. Contributions are always welcome!

## Credits

I did take inspiration for my dotfile version from [Omakub](https://github.com/basecamp/omakub)

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.