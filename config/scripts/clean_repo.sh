#!/bin/bash

echo "Removing files and folders"
rm -rf config/git/gitconfig.work
rm -rf config/gnome/*
rm -rf config/scripts/backup_script.conf
rm -rf config/ssh/*
rm -rf config/zsh/alias
rm -rf config/zsh/zshrc.work

echo "Add keep and dummy files"
touch config/git/gitconfig.work
touch config/gnome/.gitkeep
touch config/ssh/config
touch config/ssh/config.work
touch config/zsh/alias
touch config/zsh/zshrv.work

cat <<EOT > config/zsh/alias
#!/bin/bash

# Alias settings for all systems

# Get OS infos
source /etc/os-release

# Replace ls with exa
if which eza >/dev/null; then
	alias ls="eza --icons -a --group-directories-first"	
fi

if [[ \$ID == fedora ]]; then
	alias apt="dnf"
else
	if which nala >/dev/null; then
		alias apt="nala"
	fi
fi

# General linux
if [[ \$OSTYPE == linux* ]]; then
	
	# cat to batcat
	if which bat >/dev/null; then
		alias cat="bat"
	fi
	
	# WSL
	if uname -r | grep -q "microsoft"; then
		alias src="cd /mnt/c/src/"
	else
		alias src="cd \$HOME/src"
	fi

	# Update dotfiles
	alias dotfiles="cd \$HOME/.dotfiles/; ./bootstrap.sh --run-all; cd -"

	# Do not use nano
	alias nano="vim"
	alias nani="/usr/bin/nano"

	# Backup script
	alias backup="\$HOME/.local/bin/backup_home"

fi

# macOS aliasses
if [[ \$OSTYPE == darwin* ]]; then
	
	# cat to batcat
	if which bat >/dev/null; then
		alias cat="bat"
	fi
	
	# Tailing test with batcat
	alias btail="tail -f \$@ | bat --paging=never -l log"
	
	# Update dotfiles
	alias dotfiles="export org=\$PWD; cd \$HOME/.dotfiles/; ./install; cd \$org"
fi

# For all Systems

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
EOT