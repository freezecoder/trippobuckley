#!/bin/bash

# Android APK Build Script for BTrips/Trippo User App
# This script builds a release APK for Android devices

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Android APK Build Script                         ║${NC}"
echo -e "${BLUE}║          BTrips/Trippo User App                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗ Flutter is not installed or not in PATH${NC}"
    echo "Please install Flutter from https://flutter.dev"
    exit 1
fi

echo -e "${GREEN}✓ Flutter found:${NC} $(flutter --version | head -1)"
echo ""

# Step 1: Clean previous builds
echo -e "${YELLOW}[1/4] Cleaning previous builds...${NC}"
flutter clean
echo -e "${GREEN}✓ Clean complete${NC}"
echo ""

# Step 2: Get dependencies
echo -e "${YELLOW}[2/4] Getting dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✓ Dependencies resolved${NC}"
echo ""

# Step 3: Build release APK
echo -e "${YELLOW}[3/4] Building release APK...${NC}"
echo "This may take a few minutes..."
echo ""

START_TIME=$(date +%s)
flutter build apk --release

if [ $? -eq 0 ]; then
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    echo ""
    echo -e "${GREEN}✓ APK built successfully in ${DURATION} seconds!${NC}"
    echo ""
    
    # Step 4: Show APK location and info
    echo -e "${YELLOW}[4/4] Build Information${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    
    APK_PATH="$SCRIPT_DIR/build/app/outputs/flutter-apk/app-release.apk"
    
    if [ -f "$APK_PATH" ]; then
        APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
        echo -e "${GREEN}📦 APK Location:${NC}"
        echo "   $APK_PATH"
        echo ""
        echo -e "${GREEN}📊 File Size:${NC} $APK_SIZE"
        echo ""
        echo -e "${GREEN}📱 Package Name:${NC} dev.hyderali.trippo_user"
        echo ""
        echo -e "${GREEN}🔧 Build Configuration:${NC}"
        echo "   • Gradle: 8.10"
        echo "   • Android Gradle Plugin: 8.7.1"
        echo "   • Kotlin: 2.1.0"
        echo "   • Min SDK: Flutter default"
        echo "   • Target SDK: Flutter default"
        echo ""
        echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${GREEN}📲 Installation Instructions:${NC}"
        echo ""
        echo "Option 1: USB Cable"
        echo "  1. Connect your Android device via USB"
        echo "  2. Enable USB debugging on your device"
        echo "  3. Run: adb install $APK_PATH"
        echo ""
        echo "Option 2: Manual Transfer"
        echo "  1. Copy the APK to your device"
        echo "  2. Enable 'Install from Unknown Sources' in Settings"
        echo "  3. Open the APK file on your device and install"
        echo ""
        echo -e "${YELLOW}⚠️  Note:${NC} This is a release build signed with debug keys."
        echo "   For production, configure proper signing in android/app/build.gradle"
        echo ""
        echo -e "${GREEN}✅ Build complete!${NC}"
        
        # Open folder (macOS)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo ""
            read -p "Open APK folder in Finder? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                open "$SCRIPT_DIR/build/app/outputs/flutter-apk/"
            fi
        fi
    else
        echo -e "${RED}✗ APK file not found at expected location${NC}"
        exit 1
    fi
else
    echo ""
    echo -e "${RED}✗ Build failed${NC}"
    echo "Check the error messages above for details."
    exit 1
fi

