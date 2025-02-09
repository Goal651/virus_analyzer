#!/bin/bash

# Define suspicious directories
DIRS=("/tmp" "/var/tmp" "/dev/shm" "/usr/local/tmp" "/root/.cache" "/home/*/.cache" "/run/user/*")

# Define file types to look for
FILE_TYPES=("*.sh" "*.exe" "*.bat" "*.js" "*.php" "*.py" "*.pl" "*.so" "*.out" "*.bin" "*.elf")

# Colors for output
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

echo -e "${YELLOW}Starting system scan for suspicious files, viruses, and rootkits...${RESET}"

# Function to check and install a package
install_package() {
    local package=$1
    if command -v "$package" &>/dev/null; then
        echo -e "${GREEN}[✔] $package is already installed.${RESET}"
        return 0
    fi

    echo -e "${YELLOW}[!] $package is not installed. Attempting to install...${RESET}"

    # Detect the package manager and install
    if command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y "$package"
    elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm "$package"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "$package"
    elif command -v yum &>/dev/null; then
        sudo yum install -y "$package"
    else
        echo -e "${RED}[✖] Package manager not found! Install $package manually.${RESET}"
        return 1
    fi

    if command -v "$package" &>/dev/null; then
        echo -e "${GREEN}[✔] $package installed successfully.${RESET}"
    else
        echo -e "${RED}[✖] Failed to install $package! Install manually.${RESET}"
    fi
}

# Ensure ClamAV and Rootkit Hunter are installed
install_package clamscan  # ClamAV
install_package rkhunter   # Rootkit Hunter

# Scan suspicious directories
for DIR in "${DIRS[@]}"; do
    echo -e "${GREEN}Checking directory: $DIR${RESET}"
    
    # Look for executable files
    find "$DIR" -type f -executable 2>/dev/null | while read -r file; do
        echo -e "${RED}[!] Suspicious Executable: $file${RESET}"
    done

    # Look for common malware file types
    for TYPE in "${FILE_TYPES[@]}"; do
        find "$DIR" -type f -name "$TYPE" 2>/dev/null | while read -r file; do
            echo -e "${RED}[!] Suspicious File Found: $file${RESET}"
        done
    done

    # Look for hidden files (potential backdoors)
    find "$DIR" -type f -name ".*" 2>/dev/null | while read -r file; do
        echo -e "${RED}[!] Hidden File: $file${RESET}"
    done

    # Run ClamAV scan
    if command -v clamscan &>/dev/null; then
        echo -e "${YELLOW}Running ClamAV scan on $DIR...${RESET}"
        clamscan -r --bell -i "$DIR"
    fi
done

# Run Rootkit Hunter scan
if command -v rkhunter &>/dev/null; then
    echo -e "${YELLOW}Running Rootkit Hunter scan...${RESET}"
    sudo rkhunter --check --sk
fi

echo -e "${YELLOW}System scan completed.${RESET}"
