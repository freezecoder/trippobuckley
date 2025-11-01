#!/bin/bash

# Simple build script - just clean and build (no prompts)

set -e

echo "🧹 Cleaning old build..."
rm -rf build/web

echo "🏗️  Building Flutter web app..."
flutter build web --release

echo "📋 Copying vercel.json..."
cp vercel.json build/web/

echo ""
echo "✅ Build complete!"
echo ""
echo "Build output: build/web/"
echo "Build size: $(du -sh build/web | cut -f1)"
echo ""
echo "To deploy:"
echo "  cd build/web && vercel --prod"

