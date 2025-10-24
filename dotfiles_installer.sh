#!/bin/bash

# macOS Dotfiles Installer
# Based on https://github.com/ChristianLempa/dotfiles

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_REPO="https://github.com/ChristianLempa/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Print colored message
print_message() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

print_success() { print_message "$GREEN" "✓ $@"; }
print_error() { print_message "$RED" "✗ $@"; }
print_info() { print_message "$BLUE" "ℹ $@"; }
print_warning() { print_message "$YELLOW" "⚠ $@"; }

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This installer is designed for macOS only."
        exit 1
    fi
    print_success "Running on macOS"
}

# Install Homebrew if not present
install_homebrew() {
    if ! command -v brew &> /dev/null; then
        print_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        print_success "Homebrew installed"
    else
        print_success "Homebrew already installed"
    fi
}

# Clone dotfiles repository
clone_dotfiles() {
    if [ -d "$DOTFILES_DIR" ]; then
        print_warning "Dotfiles directory already exists at $DOTFILES_DIR"
        read -p "Do you want to remove it and re-clone? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$DOTFILES_DIR"
            print_info "Removed existing dotfiles directory"
        else
            print_info "Using existing dotfiles directory"
            return
        fi
    fi
    
    print_info "Cloning dotfiles repository..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    print_success "Dotfiles repository cloned to $DOTFILES_DIR"
}

# Create backup directory
create_backup() {
    mkdir -p "$BACKUP_DIR"
    print_info "Backup directory created at $BACKUP_DIR"
}

# Backup and symlink a file
link_file() {
    local source=$1
    local target=$2
    
    # Create target directory if it doesn't exist
    mkdir -p "$(dirname "$target")"
    
    # Backup existing file/directory
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        print_warning "Backing up existing $(basename "$target")"
        mv "$target" "$BACKUP_DIR/$(basename "$target")"
    elif [ -L "$target" ]; then
        print_info "Removing existing symlink $(basename "$target")"
        rm "$target"
    fi
    
    # Create symlink
    ln -s "$source" "$target"
    print_success "Linked $(basename "$source")"
}

# Install zsh configuration
install_zsh_config() {
    print_info "Installing Zsh configuration..."
    
    # Main zsh files
    [ -f "$DOTFILES_DIR/.zshrc" ] && link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    [ -f "$DOTFILES_DIR/.zshenv" ] && link_file "$DOTFILES_DIR/.zshenv" "$HOME/.zshenv"
    [ -f "$DOTFILES_DIR/.hushlogin" ] && link_file "$DOTFILES_DIR/.hushlogin" "$HOME/.hushlogin"
    
    # .zsh directory with custom configs
    if [ -d "$DOTFILES_DIR/.zsh" ]; then
        link_file "$DOTFILES_DIR/.zsh" "$HOME/.zsh"
    fi
    
    print_success "Zsh configuration installed"
}

# Install starship prompt
install_starship() {
    print_info "Installing Starship prompt..."
    
    if ! command -v starship &> /dev/null; then
        print_info "Installing Starship via Homebrew..."
        brew install starship
    fi
    
    if [ -f "$DOTFILES_DIR/starship.toml" ]; then
        link_file "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
    fi
    
    print_success "Starship installed and configured"
}

# Install helix editor
install_helix() {
    print_info "Installing Helix editor..."
    
    if ! command -v hx &> /dev/null; then
        print_info "Installing Helix via Homebrew..."
        brew install helix
    fi
    
    if [ -d "$DOTFILES_DIR/helix" ]; then
        link_file "$DOTFILES_DIR/helix" "$HOME/.config/helix"
    fi
    
    print_success "Helix editor installed and configured"
}

# Install neofetch
install_neofetch() {
    print_info "Installing Neofetch..."
    
    if ! command -v neofetch &> /dev/null; then
        print_info "Installing Neofetch via Homebrew..."
        brew install neofetch
    fi
    
    if [ -d "$DOTFILES_DIR/neofetch" ]; then
        link_file "$DOTFILES_DIR/neofetch" "$HOME/.config/neofetch"
    fi
    
    print_success "Neofetch installed and configured"
}

# Install iTerm2 configuration
install_iterm2() {
    print_info "Installing iTerm2 configuration..."
    
    if [ -d "$DOTFILES_DIR/iterm2" ]; then
        # Create iTerm2 config directory
        mkdir -p "$HOME/.config/iterm2"
        
        # Link colorscheme and profile
        if [ -f "$DOTFILES_DIR/iterm2/colorscheme.itermcolors" ]; then
            link_file "$DOTFILES_DIR/iterm2/colorscheme.itermcolors" "$HOME/.config/iterm2/colorscheme.itermcolors"
        fi
        
        if [ -f "$DOTFILES_DIR/iterm2/profile.json" ]; then
            link_file "$DOTFILES_DIR/iterm2/profile.json" "$HOME/.config/iterm2/profile.json"
        fi
        
        print_success "iTerm2 configuration installed"
        print_info "Import the colorscheme and profile manually in iTerm2 preferences"
    fi
}

# Install Warp terminal configuration
install_warp() {
    print_info "Installing Warp terminal configuration..."
    
    if [ -d "$DOTFILES_DIR/.warp" ]; then
        link_file "$DOTFILES_DIR/.warp" "$HOME/.warp"
        print_success "Warp configuration installed"
    fi
}

# Install SSH configuration
install_ssh_config() {
    print_info "Installing SSH configuration..."
    
    if [ -d "$DOTFILES_DIR/.ssh" ]; then
        # Backup existing SSH config
        if [ -f "$HOME/.ssh/config" ]; then
            print_warning "Backing up existing SSH config"
            cp "$HOME/.ssh/config" "$BACKUP_DIR/ssh_config"
        fi
        
        # Link SSH config
        if [ -f "$DOTFILES_DIR/.ssh/config" ]; then
            link_file "$DOTFILES_DIR/.ssh/config" "$HOME/.ssh/config"
            chmod 600 "$HOME/.ssh/config"
        fi
        
        print_success "SSH configuration installed"
    fi
}

# Install Ansible configuration
install_ansible() {
    print_info "Installing Ansible configuration..."
    
    [ -f "$DOTFILES_DIR/.ansible.cfg" ] && link_file "$DOTFILES_DIR/.ansible.cfg" "$HOME/.ansible.cfg"
    
    if [ -d "$DOTFILES_DIR/.ansible" ]; then
        link_file "$DOTFILES_DIR/.ansible" "$HOME/.ansible"
    fi
    
    print_success "Ansible configuration installed"
}

# Install goto directory bookmarks
install_goto() {
    print_info "Installing goto directory bookmarks..."
    
    if [ -d "$DOTFILES_DIR/goto" ]; then
        link_file "$DOTFILES_DIR/goto" "$HOME/.goto"
        print_success "Goto bookmarks installed"
    fi
}

# Install yadm configuration
install_yadm() {
    print_info "Installing YADM configuration..."
    
    if [ -d "$DOTFILES_DIR/yadm" ]; then
        if ! command -v yadm &> /dev/null; then
            print_info "Installing YADM via Homebrew..."
            brew install yadm
        fi
        
        link_file "$DOTFILES_DIR/yadm" "$HOME/.config/yadm"
        print_success "YADM configuration installed"
    fi
}

# Install additional .config directories
install_config_dirs() {
    print_info "Installing additional config directories..."
    
    if [ -d "$DOTFILES_DIR/.config" ]; then
        for config_dir in "$DOTFILES_DIR/.config"/*; do
            if [ -d "$config_dir" ]; then
                local config_name=$(basename "$config_dir")
                # Skip if already handled by specific installers
                if [[ "$config_name" != "helix" && "$config_name" != "neofetch" && "$config_name" != "starship" && "$config_name" != "iterm2" && "$config_name" != "yadm" ]]; then
                    link_file "$config_dir" "$HOME/.config/$config_name"
                fi
            fi
        done
        print_success "Additional config directories installed"
    fi
}

# Install Apple Terminal theme
install_apple_terminal() {
    if [ -d "$DOTFILES_DIR/misc/apple-terminal" ]; then
        print_info "Apple Terminal theme available in $DOTFILES_DIR/misc/apple-terminal"
        print_info "Import manually via Terminal > Preferences > Profiles"
    fi
}

# Install packages from Brewfile if it exists
install_packages() {
    if [ -f "$DOTFILES_DIR/Brewfile" ]; then
        print_info "Installing packages from Brewfile..."
        cd "$DOTFILES_DIR"
        brew bundle install
        print_success "Packages installed"
    else
        print_warning "No Brewfile found, skipping package installation"
    fi
    
    # Install additional tools mentioned in the repo
    print_info "Installing additional tools (duf, dust)..."
    brew install duf dust 2>/dev/null || true
}

# Set macOS defaults
set_macos_defaults() {
    if [ -f "$DOTFILES_DIR/macos/.macos" ]; then
        print_info "Setting macOS defaults..."
        read -p "Do you want to apply macOS system defaults? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            bash "$DOTFILES_DIR/macos/.macos"
            print_success "macOS defaults applied"
        else
            print_info "Skipped macOS defaults"
        fi
    fi
}

# Main installation flow
main() {
    echo
    print_info "╔════════════════════════════════════════╗"
    print_info "║  macOS Dotfiles Installation Script   ║"
    print_info "║  Christian Lempa's Dotfiles           ║"
    print_info "╚════════════════════════════════════════╝"
    echo
    
    check_macos
    install_homebrew
    clone_dotfiles
    create_backup
    
    echo
    print_info "Installing configurations..."
    echo
    
    install_zsh_config
    install_starship
    install_helix
    install_neofetch
    install_iterm2
    install_warp
    install_ssh_config
    install_ansible
    install_goto
    install_yadm
    install_config_dirs
    install_packages
    install_apple_terminal
    set_macos_defaults
    
    echo
    print_success "╔════════════════════════════════════════╗"
    print_success "║     Installation Complete! 🎉         ║"
    print_success "╚════════════════════════════════════════╝"
    echo
    print_info "📁 Backup location: $BACKUP_DIR"
    print_info "📁 Dotfiles location: $DOTFILES_DIR"
    echo
    print_warning "⚠️  Next steps:"
    print_warning "   1. Restart your terminal or run: source ~/.zshrc"
    print_warning "   2. Import iTerm2 colorscheme manually if using iTerm2"
    print_warning "   3. Import Apple Terminal theme manually if using Terminal.app"
    echo
}

# Run main function
main