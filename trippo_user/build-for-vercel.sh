#!/bin/bash

# Build Flutter web app and prepare for Vercel deployment

echo "🏗️  Building Flutter web app..."
flutter build web --release

if [ $? -eq 0 ]; then
    echo "✅ Build completed successfully"
    
    echo "📋 Copying vercel.json to build directory..."
    cp vercel.json build/web/vercel.json
    
    echo "✅ Ready to deploy!"
    echo ""
    echo "Next steps:"
    echo "  cd build/web"
    echo "  vercel --prod"
else
    echo "❌ Build failed"
    exit 1
fi

