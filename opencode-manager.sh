#!/data/data/com.termux/files/usr/bin/bash

set -Eeuo pipefail

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
HOME_DIR="${HOME:-/data/data/com.termux/files/home}"

VERSION="1.18.31"
DOWNLOAD_URL="https://github.com/anomalyco/opencode/releases/download/v${VERSION}/opencode-linux-arm64.tar.gz"

LAUNCHER="$PREFIX/bin/opencode"
TEMP_SCRIPT="$PREFIX/tmp/opencode-manager-setup.sh"

RESET='\033[0m'
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
DIM='\033[2m'

pause() {
    echo ""
    read -rp "Press Enter to continue..."
}

header() {
    clear
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}║          OPENCODE TERMUX MANAGER             ║${RESET}"
    echo -e "${CYAN}${BOLD}╠══════════════════════════════════════════════╣${RESET}"
    echo -e "${CYAN}║${RESET} Version: ${GREEN}${VERSION}${RESET}"
    echo -e "${CYAN}║${RESET} Platform: ${GREEN}Android ARM64 / Termux${RESET}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════╝${RESET}"
    echo ""
}

success() {
    echo -e "${GREEN}✔ $1${RESET}"
}

error() {
    echo -e "${RED}✖ $1${RESET}"
}

info() {
    echo -e "${CYAN}ℹ $1${RESET}"
}

check_architecture() {
    if [ "$(uname -m)" != "aarch64" ]; then
        error "This installer requires ARM64/aarch64."
        exit 1
    fi
}

check_dependencies() {
    pkg update -y
    pkg install -y proot-distro wget curl tar ca-certificates file
}

check_ubuntu() {
    if proot-distro login ubuntu -- /bin/true >/dev/null 2>&1; then
        success "Ubuntu is ready."
    else
        info "Ubuntu is not installed. Installing..."
        proot-distro install ubuntu
        success "Ubuntu installed."
    fi
}

create_ubuntu_setup() {
    mkdir -p "$PREFIX/tmp"

    cat > "$TEMP_SCRIPT" <<'SCRIPT'
#!/bin/bash

set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

VERSION="1.18.31"
URL="https://github.com/anomalyco/opencode/releases/download/v${VERSION}/opencode-linux-arm64.tar.gz"

INSTALL_DIR="/root/.opencode/bin"
TEMP_DIR="/tmp/opencode-install"

apt update -y
apt install -y wget curl ca-certificates tar file

rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

cd "$TEMP_DIR"

echo "Downloading OpenCode ${VERSION}..."

wget \
    --progress=bar:force:noscroll \
    -O opencode.tar.gz \
    "$URL"

echo ""
echo "Extracting..."

mkdir -p extracted
tar -xzf opencode.tar.gz -C extracted

BINARY="$(find extracted -type f -name opencode | head -n 1 || true)"

if [ -z "$BINARY" ]; then
    echo "ERROR: OpenCode executable not found."
    find extracted -type f
    exit 1
fi

mkdir -p "$INSTALL_DIR"

rm -f "$INSTALL_DIR/opencode"

cp "$BINARY" "$INSTALL_DIR/opencode"
chmod +x "$INSTALL_DIR/opencode"

echo ""
echo "Installed version:"
"$INSTALL_DIR/opencode" --version

SCRIPT

    chmod +x "$TEMP_SCRIPT"
}

install_opencode() {
    header

    echo -e "${BOLD}${BLUE}Installing OpenCode...${RESET}"
    echo ""

    check_architecture
    check_dependencies
    check_ubuntu
    create_ubuntu_setup

    proot-distro copy \
        "$TEMP_SCRIPT" \
        ubuntu:/root/opencode-setup.sh

    proot-distro login ubuntu -- bash /root/opencode-setup.sh

    create_launcher

    rm -f "$TEMP_SCRIPT"

    success "OpenCode installed successfully."
    pause
}

reinstall_opencode() {
    header

    echo -e "${BOLD}${YELLOW}Reinstalling OpenCode...${RESET}"
    echo ""

    check_architecture
    check_dependencies
    check_ubuntu

    echo "Removing existing OpenCode installation..."

    proot-distro login ubuntu -- bash -c '
        rm -rf /root/.opencode
    '

    rm -f "$LAUNCHER"

    create_ubuntu_setup

    proot-distro copy \
        "$TEMP_SCRIPT" \
        ubuntu:/root/opencode-setup.sh

    proot-distro login ubuntu -- bash /root/opencode-setup.sh

    create_launcher

    rm -f "$TEMP_SCRIPT"

    success "OpenCode reinstalled successfully."
    pause
}

update_opencode() {
    header

    echo -e "${BOLD}${BLUE}Updating OpenCode...${RESET}"
    echo ""

    check_architecture
    check_dependencies
    check_ubuntu

    create_ubuntu_setup

    proot-distro copy \
        "$TEMP_SCRIPT" \
        ubuntu:/root/opencode-update.sh

    proot-distro login ubuntu -- bash /root/opencode-update.sh

    create_launcher

    rm -f "$TEMP_SCRIPT"

    success "OpenCode updated successfully."
    pause
}

uninstall_opencode() {
    header

    echo -e "${BOLD}${RED}Uninstall OpenCode${RESET}"
    echo ""

    read -rp "Are you sure? Type YES to continue: " CONFIRM

    if [ "$CONFIRM" != "YES" ]; then
        info "Uninstall cancelled."
        pause
        return
    fi

    echo ""
    echo "Removing OpenCode from Ubuntu..."

    if proot-distro login ubuntu -- /bin/true >/dev/null 2>&1; then
        proot-distro login ubuntu -- bash -c '
            rm -rf /root/.opencode
            rm -f /root/opencode-setup.sh
            rm -f /root/opencode-update.sh
        '
    fi

    rm -f "$LAUNCHER"
    rm -f "$HOME_DIR/.opencode/bin/opencode"

    sed -i '/\.opencode\/bin/d' "$HOME_DIR/.bashrc" 2>/dev/null || true

    hash -r 2>/dev/null || true

    success "OpenCode has been uninstalled."
    pause
}

create_launcher() {
    cat > "$LAUNCHER" <<'LAUNCHER'
#!/data/data/com.termux/files/usr/bin/bash

set -e

CURRENT_DIR="$(pwd)"
PROJECT_DIR="/root"

if [[ "$CURRENT_DIR" == "$HOME"* ]]; then
    PROJECT_DIR="/root/termux-home${CURRENT_DIR#$HOME}"
fi

if [[ "$CURRENT_DIR" == /storage/* ]]; then
    PROJECT_DIR="/root/termux-storage$CURRENT_DIR"
fi

exec proot-distro login ubuntu \
    --bind "$HOME:/root/termux-home" \
    --bind "/storage:/root/termux-storage" \
    -- bash -c '
        export PATH="/root/.opencode/bin:$PATH"

        PROJECT="$1"
        shift

        if [ -d "$PROJECT" ]; then
            cd "$PROJECT"
        else
            echo "Warning: Project directory unavailable: $PROJECT"
            cd /root
        fi

        exec /root/.opencode/bin/opencode "$@"
    ' -- "$PROJECT_DIR" "$@"
LAUNCHER

    chmod +x "$LAUNCHER"

    export PATH="$PREFIX/bin:$PATH"
    hash -r 2>/dev/null || true
}

show_status() {
    header

    echo -e "${BOLD}${BLUE}OpenCode Status${RESET}"
    echo ""

    if [ -x "$LAUNCHER" ]; then
        success "Termux launcher: Installed"
        echo "Path: $LAUNCHER"
    else
        error "Termux launcher: Not installed"
    fi

    echo ""

    if proot-distro login ubuntu -- /root/.opencode/bin/opencode --version >/dev/null 2>&1; then
        success "Ubuntu OpenCode: Installed"
        echo -n "Version: "
        proot-distro login ubuntu -- /root/.opencode/bin/opencode --version
    else
        error "Ubuntu OpenCode: Not installed"
    fi

    pause
}

main_menu() {
    while true; do
        header

        echo -e "${BOLD}${GREEN}1.${RESET} Install OpenCode"
        echo -e "${BOLD}${YELLOW}2.${RESET} Reinstall OpenCode"
        echo -e "${BOLD}${BLUE}3.${RESET} Update OpenCode"
        echo -e "${BOLD}${RED}4.${RESET} Uninstall OpenCode"
        echo -e "${BOLD}${CYAN}5.${RESET} Check Status"
        echo -e "${BOLD}${DIM}6.${RESET} Exit"

        echo ""
        echo -e "${DIM}────────────────────────────────────────────────${RESET}"

        read -rp "Select an option [1-6]: " OPTION

        case "$OPTION" in
            1)
                install_opencode
                ;;
            2)
                reinstall_opencode
                ;;
            3)
                update_opencode
                ;;
            4)
                uninstall_opencode
                ;;
            5)
                show_status
                ;;
            6)
                clear
                echo "Exiting OpenCode Manager."
                exit 0
                ;;
            *)
                error "Invalid option."
                sleep 1
                ;;
        esac
    done
}

main_menu
