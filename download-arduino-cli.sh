#!/bin/bash
# Download and organize arduino-cli binaries

set -e

VERSION="1.3.1"
BASE_URL="https://github.com/arduino/arduino-cli/releases/download/v${VERSION}"
RESOURCE_DIR="src/main/resources/arduino-cli"

echo "Downloading arduino-cli v${VERSION} binaries..."

# Create directory structure
mkdir -p "${RESOURCE_DIR}"/{linux-x86_64,linux-aarch64,macos-x86_64,macos-aarch64,windows-x86_64}

# Download and extract Linux x86_64
echo "Downloading Linux x86_64..."
curl -L "${BASE_URL}/arduino-cli_${VERSION}_Linux_64bit.tar.gz" | tar -xz -C "${RESOURCE_DIR}/linux-x86_64" arduino-cli

# Download and extract Linux ARM64
echo "Downloading Linux ARM64..."
curl -L "${BASE_URL}/arduino-cli_${VERSION}_Linux_ARM64.tar.gz" | tar -xz -C "${RESOURCE_DIR}/linux-aarch64" arduino-cli

# Download and extract macOS x86_64
echo "Downloading macOS x86_64..."
curl -L "${BASE_URL}/arduino-cli_${VERSION}_macOS_64bit.tar.gz" | tar -xz -C "${RESOURCE_DIR}/macos-x86_64" arduino-cli

# Download and extract macOS ARM64
echo "Downloading macOS ARM64..."
curl -L "${BASE_URL}/arduino-cli_${VERSION}_macOS_ARM64.tar.gz" | tar -xz -C "${RESOURCE_DIR}/macos-aarch64" arduino-cli

# Download and extract Windows x86_64
echo "Downloading Windows x86_64..."
TEMP_DIR=$(mktemp -d)
curl -L -o "${TEMP_DIR}/windows.zip" "${BASE_URL}/arduino-cli_${VERSION}_Windows_64bit.zip"
unzip -q "${TEMP_DIR}/windows.zip" arduino-cli.exe -d "${RESOURCE_DIR}/windows-x86_64"
rm -rf "${TEMP_DIR}"

# Set executable permissions
chmod +x "${RESOURCE_DIR}"/linux-*/arduino-cli
chmod +x "${RESOURCE_DIR}"/macos-*/arduino-cli

echo "Done! Arduino CLI binaries downloaded and organized."
echo ""
echo "Directory structure:"
find "${RESOURCE_DIR}" -type f -name "arduino-cli*" | sort
