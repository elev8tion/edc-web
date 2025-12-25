#!/bin/bash

# KB Tools Installer
# Installs the Knowledge Base toolkit to any project or globally

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INSTALL]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat << EOF
KB Tools Installer

Usage: ./install.sh [option]

Options:
    --global          Install globally (adds to PATH)
    --project <dir>   Install to specific project
    --here            Install to current directory
    --help            Show this help

Examples:
    ./install.sh --global                # Install to ~/bin
    ./install.sh --project ~/my-project  # Install to project
    ./install.sh --here                  # Install to current dir

EOF
}

install_global() {
    log "Installing KB tools globally..."

    # Create ~/bin if it doesn't exist
    mkdir -p "$HOME/bin"

    # Copy kb tool
    cp "$SCRIPT_DIR/kb" "$HOME/bin/kb"
    chmod +x "$HOME/bin/kb"

    # Create kb-tools directory
    mkdir -p "$HOME/.kb-tools"
    cp "$SCRIPT_DIR/../"*.{sh,py} "$HOME/.kb-tools/" 2>/dev/null || true
    cp -r "$SCRIPT_DIR/"* "$HOME/.kb-tools/" 2>/dev/null || true

    success "KB tools installed to ~/bin/kb"
    log ""
    log "Add ~/bin to your PATH if not already there:"
    log "  echo 'export PATH=\"\$HOME/bin:\$PATH\"' >> ~/.bashrc"
    log "  echo 'export PATH=\"\$HOME/bin:\$PATH\"' >> ~/.zshrc"
    log ""
    log "Then run: kb --help"
}

install_project() {
    local project_dir="$1"

    if [ -z "$project_dir" ]; then
        echo "Error: Project directory required"
        show_help
        exit 1
    fi

    if [ ! -d "$project_dir" ]; then
        echo "Error: Directory not found: $project_dir"
        exit 1
    fi

    log "Installing KB tools to: $project_dir"

    # Create kb-tools directory in project
    mkdir -p "$project_dir/kb-tools"

    # Copy files
    cp "$SCRIPT_DIR/kb" "$project_dir/kb-tools/kb"
    cp "$SCRIPT_DIR/../"*.{sh,py} "$project_dir/kb-tools/" 2>/dev/null || true
    chmod +x "$project_dir/kb-tools/kb"

    # Create wrapper script
    cat > "$project_dir/kb" << 'EOF'
#!/bin/bash
"$(dirname "$0")/kb-tools/kb" "$@"
EOF
    chmod +x "$project_dir/kb"

    success "KB tools installed to $project_dir"
    log ""
    log "Usage from project directory:"
    log "  cd $project_dir"
    log "  ./kb init \"MyTopic\""
    log "  ./kb add urls.txt"
    log "  ./kb build"
}

install_here() {
    install_project "$(pwd)"
}

case "${1:-}" in
    --global)
        install_global
        ;;
    --project)
        install_project "$2"
        ;;
    --here)
        install_here
        ;;
    --help|-h|"")
        show_help
        ;;
    *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
