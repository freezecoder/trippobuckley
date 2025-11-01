#!/bin/bash

# Pre-deployment check script for Vercel deployment
# This script verifies that everything is ready for deployment

set -e

echo "🚀 BTrips Unified App - Pre-Deployment Checklist"
echo "================================================"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to print info
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check 1: Flutter installation
echo "Checking Flutter installation..."
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    print_status 0 "Flutter is installed: $FLUTTER_VERSION"
else
    print_status 1 "Flutter is not installed or not in PATH"
    exit 1
fi
echo ""

# Check 2: Flutter dependencies
echo "Checking Flutter dependencies..."
if flutter pub get; then
    print_status 0 "Flutter dependencies resolved successfully"
else
    print_status 1 "Failed to resolve Flutter dependencies"
    exit 1
fi
echo ""

# Check 3: Analyze code for errors
echo "Analyzing Dart code..."
if flutter analyze --no-fatal-infos; then
    print_status 0 "Code analysis passed (warnings are okay)"
else
    print_status 1 "Code analysis found critical issues"
    print_warning "Review the analysis output above"
fi
echo ""

# Check 4: Firebase configuration
echo "Checking Firebase configuration..."
if [ -f "lib/firebase_options.dart" ]; then
    print_status 0 "Firebase options file exists"
    
    # Check if web configuration exists
    if grep -q "static const FirebaseOptions web" lib/firebase_options.dart; then
        print_status 0 "Web Firebase configuration found"
    else
        print_status 1 "Web Firebase configuration missing"
        exit 1
    fi
else
    print_status 1 "Firebase options file missing"
    exit 1
fi
echo ""

# Check 5: Web directory
echo "Checking web directory..."
if [ -d "web" ]; then
    print_status 0 "Web directory exists"
    
    # Check critical web files
    if [ -f "web/index.html" ]; then
        print_status 0 "index.html exists"
    else
        print_status 1 "index.html missing"
        exit 1
    fi
    
    if [ -f "web/manifest.json" ]; then
        print_status 0 "manifest.json exists"
    else
        print_status 1 "manifest.json missing"
        exit 1
    fi
else
    print_status 1 "Web directory missing"
    exit 1
fi
echo ""

# Check 6: Google Maps API key
echo "Checking Google Maps configuration..."
if grep -q "maps.googleapis.com/maps/api/js?key=" web/index.html; then
    print_status 0 "Google Maps API key found in index.html"
    
    # Extract and check if it's not a placeholder
    API_KEY=$(grep -o 'key=[A-Za-z0-9_-]*' web/index.html | head -n 1 | cut -d'=' -f2)
    if [ ${#API_KEY} -gt 20 ]; then
        print_status 0 "API key appears valid (length: ${#API_KEY} chars)"
    else
        print_warning "API key might be a placeholder"
    fi
else
    print_status 1 "Google Maps API key not found"
    exit 1
fi
echo ""

# Check 7: Assets
echo "Checking assets..."
if [ -d "assets" ]; then
    print_status 0 "Assets directory exists"
    
    if [ -d "assets/imgs" ]; then
        IMG_COUNT=$(find assets/imgs -type f | wc -l)
        print_info "Found $IMG_COUNT image(s)"
    fi
    
    if [ -d "assets/fonts" ]; then
        FONT_COUNT=$(find assets/fonts -type f -name "*.ttf" | wc -l)
        print_info "Found $FONT_COUNT font file(s)"
    fi
else
    print_warning "Assets directory not found"
fi
echo ""

# Check 8: Build test
echo "Attempting test build..."
print_info "This may take a few minutes..."
if flutter build web --release; then
    print_status 0 "Test build completed successfully"
    
    # Check build output
    if [ -d "build/web" ]; then
        BUILD_SIZE=$(du -sh build/web | cut -f1)
        print_info "Build output size: $BUILD_SIZE"
        
        # Check critical files in build
        if [ -f "build/web/index.html" ]; then
            print_status 0 "index.html generated"
        fi
        
        if [ -f "build/web/main.dart.js" ] || [ -f "build/web/main.dart.js.map" ]; then
            print_status 0 "Dart JavaScript generated"
        fi
        
        if [ -d "build/web/assets" ]; then
            print_status 0 "Assets copied to build"
        fi
    else
        print_status 1 "Build directory not created"
        exit 1
    fi
else
    print_status 1 "Test build failed"
    exit 1
fi
echo ""

# Check 9: Vercel configuration
echo "Checking Vercel configuration..."
if [ -f "vercel.json" ]; then
    print_status 0 "vercel.json exists"
else
    print_warning "vercel.json not found (Vercel will use default settings)"
fi

if [ -f ".vercelignore" ]; then
    print_status 0 ".vercelignore exists"
else
    print_warning ".vercelignore not found"
fi
echo ""

# Check 10: Vercel CLI
echo "Checking Vercel CLI..."
if command -v vercel &> /dev/null; then
    VERCEL_VERSION=$(vercel --version)
    print_status 0 "Vercel CLI is installed: $VERCEL_VERSION"
    
    print_info "You can now deploy with: vercel --prod"
else
    print_warning "Vercel CLI not installed"
    print_info "Install with: npm i -g vercel"
fi
echo ""

# Summary
echo "================================================"
echo -e "${GREEN}✓ Pre-deployment checks completed!${NC}"
echo ""
echo "Next steps:"
echo "  1. Review any warnings above"
echo "  2. Commit your changes: git add . && git commit -m 'Ready for deployment'"
echo "  3. Deploy to Vercel: vercel --prod"
echo ""
echo "For first-time deployment:"
echo "  1. Run: vercel"
echo "  2. Follow the prompts to link/create project"
echo "  3. Deploy production: vercel --prod"
echo ""

