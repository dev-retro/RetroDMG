#!/bin/bash

# Script to download the latest GameBoy test ROMs for RetroDMG testing
# Based on: https://github.com/c-sp/game-boy-test-roms

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_ROMS_DIR="$PROJECT_ROOT/Tests/RetroDMGTests/Resources/test-roms"

echo "🎮 Downloading GameBoy Test ROMs for RetroDMG"
echo "Target directory: $TEST_ROMS_DIR"

# Create temporary directory for downloads
TEMP_DIR=$(mktemp -d)
echo "Using temporary directory: $TEMP_DIR"

# Function to cleanup on exit
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

cd "$TEMP_DIR"

# Download the latest release of game-boy-test-roms
echo "📦 Downloading latest test ROM collection..."
LATEST_RELEASE_URL="https://api.github.com/repos/c-sp/game-boy-test-roms/releases/latest"
DOWNLOAD_URL=$(curl -s "$LATEST_RELEASE_URL" | grep "browser_download_url.*\.zip" | cut -d '"' -f 4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "❌ Could not find download URL for latest release"
    exit 1
fi

echo "📥 Downloading from: $DOWNLOAD_URL"
curl -L -o game-boy-test-roms.zip "$DOWNLOAD_URL"

# Extract the archive
echo "📂 Extracting test ROMs..."
unzip -q game-boy-test-roms.zip

# The archive extracts directly to current directory
EXTRACTED_DIR="."

echo "📁 Found extracted directory: $EXTRACTED_DIR"

# Create target directories
mkdir -p "$TEST_ROMS_DIR/blargg"
mkdir -p "$TEST_ROMS_DIR/dmg-acid2"
mkdir -p "$TEST_ROMS_DIR/mooneye"
mkdir -p "$TEST_ROMS_DIR/misc"

# Copy Blargg CPU instruction tests
echo "📋 Copying Blargg CPU tests..."
if [ -d "$EXTRACTED_DIR/blargg" ]; then
    cp -r "$EXTRACTED_DIR/blargg"/* "$TEST_ROMS_DIR/blargg/" 2>/dev/null || true
fi

# Copy dmg-acid2
echo "🧪 Copying dmg-acid2 test..."
if [ -d "$EXTRACTED_DIR/dmg-acid2" ]; then
    cp -r "$EXTRACTED_DIR/dmg-acid2"/* "$TEST_ROMS_DIR/dmg-acid2/" 2>/dev/null || true
fi

# Copy Mooneye tests
echo "🌙 Copying Mooneye tests..."
if [ -d "$EXTRACTED_DIR/mooneye-test-suite" ]; then
    cp -r "$EXTRACTED_DIR/mooneye-test-suite"/* "$TEST_ROMS_DIR/mooneye/" 2>/dev/null || true
fi

# Copy other interesting tests
echo "📦 Copying miscellaneous tests..."
for dir in "age-test-roms" "bully" "cgb-acid-hell" "cgb-acid2" "gambatte" "gbmicrotest" "little-things-gb" "mbc3-tester" "mealybug-tearoom-tests" "mooneye-test-suite-wilbertpol" "rtc3test" "same-suite" "scribbltests" "strikethrough" "turtle-tests"; do
    if [ -d "$EXTRACTED_DIR/$dir" ]; then
        find "$EXTRACTED_DIR/$dir" -type f \( -name "*.gb" -o -name "*.gbc" \) -exec cp {} "$TEST_ROMS_DIR/misc/" \; 2>/dev/null || true
    fi
done

# Copy reference images if available
echo "🖼️  Copying reference images..."
find "$EXTRACTED_DIR" -type f \( -name "*.png" -o -name "*.bmp" \) -exec cp {} "$TEST_ROMS_DIR/misc/" \; 2>/dev/null || true

# Create a manifest file
echo "📝 Creating test ROM manifest..."
cat > "$TEST_ROMS_DIR/manifest.txt" << EOF
# GameBoy Test ROM Manifest
# Downloaded on: $(date)
# Source: https://github.com/c-sp/game-boy-test-roms

## Directory Structure:
- blargg/     : Blargg CPU instruction tests
- dmg-acid2/  : DMG ACID2 PPU test
- mooneye/    : Mooneye test suite
- misc/       : Other miscellaneous tests

## Test ROM Counts:
EOF

echo "Blargg tests: $(find "$TEST_ROMS_DIR/blargg" -name "*.gb" -o -name "*.gbc" | wc -l)" >> "$TEST_ROMS_DIR/manifest.txt"
echo "DMG-ACID2 tests: $(find "$TEST_ROMS_DIR/dmg-acid2" -name "*.gb" -o -name "*.gbc" | wc -l)" >> "$TEST_ROMS_DIR/manifest.txt"
echo "Mooneye tests: $(find "$TEST_ROMS_DIR/mooneye" -name "*.gb" -o -name "*.gbc" | wc -l)" >> "$TEST_ROMS_DIR/manifest.txt"
echo "Misc tests: $(find "$TEST_ROMS_DIR/misc" -name "*.gb" -o -name "*.gbc" | wc -l)" >> "$TEST_ROMS_DIR/manifest.txt"

# Create a .gitignore to exclude the ROMs from version control
cat > "$TEST_ROMS_DIR/.gitignore" << EOF
# Test ROMs are downloaded by script, not stored in git
*.gb
*.gbc
*.png
*.bmp
EOF

echo ""
echo "✅ Test ROM download complete!"
echo "📊 Summary:"
echo "   Blargg tests: $(find "$TEST_ROMS_DIR/blargg" -name "*.gb" -o -name "*.gbc" | wc -l)"
echo "   DMG-ACID2 tests: $(find "$TEST_ROMS_DIR/dmg-acid2" -name "*.gb" -o -name "*.gbc" | wc -l)"
echo "   Mooneye tests: $(find "$TEST_ROMS_DIR/mooneye" -name "*.gb" -o -name "*.gbc" | wc -l)"
echo "   Misc tests: $(find "$TEST_ROMS_DIR/misc" -name "*.gb" -o -name "*.gbc" | wc -l)"
echo ""
echo "🎯 Test ROMs are ready for use in RetroDMG tests!"
echo "   See: $TEST_ROMS_DIR/manifest.txt for details"
