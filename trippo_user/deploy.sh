#!/bin/bash

# Complete build and deploy script for Vercel
# This script cleans, builds, and optionally deploys your Flutter web app

set -e  # Exit on any error

echo "╔══════════════════════════════════════════════════════════╗"
echo "║     Flutter Web → Vercel Deployment Script              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Step 1: Clean old build
echo -e "${BLUE}[1/4]${NC} Cleaning old build..."
if [ -d "build/web" ]; then
    rm -rf build/web
    echo -e "${GREEN}✓${NC} Removed old build/web directory"
else
    echo -e "${YELLOW}⚠${NC} No existing build/web directory found"
fi
echo ""

# Step 2: Build Flutter web app
echo -e "${BLUE}[2/4]${NC} Building Flutter web app..."
echo -e "${YELLOW}→${NC} Running: flutter build web --release"
echo ""

if flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=false --no-tree-shake-icons; then
    echo ""
    echo -e "${GREEN}✓${NC} Build completed successfully!"
    
    # Show build size
    BUILD_SIZE=$(du -sh build/web | cut -f1)
    echo -e "${GREEN}✓${NC} Build output size: ${BUILD_SIZE}"
else
    echo ""
    echo -e "${RED}✗${NC} Build failed!"
    exit 1
fi
echo ""

# Step 3: Copy vercel.json to build directory
echo -e "${BLUE}[3/4]${NC} Preparing for Vercel deployment..."
if [ -f "vercel.json" ]; then
    cp vercel.json build/web/
    echo -e "${GREEN}✓${NC} Copied vercel.json to build/web/"
else
    echo -e "${RED}✗${NC} vercel.json not found in project root!"
    exit 1
fi

# Verify critical files
echo -e "${YELLOW}→${NC} Verifying build output..."
if [ -f "build/web/index.html" ]; then
    echo -e "${GREEN}✓${NC} index.html exists"
else
    echo -e "${RED}✗${NC} index.html missing!"
    exit 1
fi

if [ -f "build/web/main.dart.js" ]; then
    MAIN_SIZE=$(ls -lh build/web/main.dart.js | awk '{print $5}')
    echo -e "${GREEN}✓${NC} main.dart.js exists (${MAIN_SIZE})"
else
    echo -e "${RED}✗${NC} main.dart.js missing!"
    exit 1
fi

if [ -f "build/web/vercel.json" ]; then
    echo -e "${GREEN}✓${NC} vercel.json exists"
else
    echo -e "${RED}✗${NC} vercel.json missing!"
    exit 1
fi

echo ""

# Step 4: Deploy or show instructions
echo -e "${BLUE}[4/4]${NC} Deployment options..."
echo ""
echo "Your build is ready! Choose an option:"
echo ""
echo "  ${GREEN}1)${NC} Deploy to production:    ${YELLOW}cd build/web && vercel --prod${NC}"
echo "  ${GREEN}2)${NC} Deploy preview:          ${YELLOW}cd build/web && vercel${NC}"
echo "  ${GREEN}3)${NC} Test locally:            ${YELLOW}cd build/web && python3 -m http.server 8000${NC}"
echo ""

# Ask user if they want to deploy now
read -p "Deploy to Vercel now? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    read -p "Production or preview? (prod/preview): " deploy_type
    
    cd build/web
    
    if [[ $deploy_type == "prod" ]]; then
        echo -e "${YELLOW}→${NC} Deploying to production..."
        vercel --prod
    else
        echo -e "${YELLOW}→${NC} Deploying preview..."
        vercel
    fi
else
    echo ""
    echo -e "${GREEN}✓${NC} Build complete and ready to deploy manually!"
    echo ""
    echo "To deploy, run:"
    echo -e "  ${YELLOW}cd build/web${NC}"
    echo -e "  ${YELLOW}vercel --prod${NC}"
    echo ""
fi

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                    ✓ All Done!                          ║"
echo "╚══════════════════════════════════════════════════════════╝"

