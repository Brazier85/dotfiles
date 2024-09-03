is_package_installed "vim" || install_package "vim"

ensure_directories "$HOME/.config/"

create_symlink "$SCRIPT_DIR/config/nvim" "$HOME/.config/nvim"
create_symlink "$SCRIPT_DIR/config/vim/vimrc" "$HOME/.vimrc"
