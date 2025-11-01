# 🚀 Deployment Scripts Guide

## Available Scripts

You now have two scripts to help with building and deploying:

### 1. `deploy.sh` - Interactive Full Build & Deploy
The complete solution with prompts and options.

### 2. `build-only.sh` - Quick Non-Interactive Build
Just clean, build, and copy config. No prompts.

---

## 🎯 Quick Start

### Option 1: Interactive Deploy (Recommended)

```bash
./deploy.sh
```

**What it does:**
1. ✅ Removes old `build/web/`
2. ✅ Builds fresh with `flutter build web --release`
3. ✅ Copies `vercel.json` to `build/web/`
4. ✅ Verifies build output
5. ✅ Asks if you want to deploy now

**Interactive prompts:**
- "Deploy to Vercel now?" → `y` or `n`
- "Production or preview?" → `prod` or `preview`

### Option 2: Build Only (No Deploy)

```bash
./build-only.sh
```

**What it does:**
1. ✅ Removes old `build/web/`
2. ✅ Builds fresh
3. ✅ Copies `vercel.json`
4. ✅ Shows deploy command

Then manually:
```bash
cd build/web
vercel --prod
```

---

## 📋 Complete Workflow Examples

### Workflow 1: One Command Deploy

```bash
# From trippo_user directory
./deploy.sh

# Choose:
# Deploy to Vercel now? y
# Production or preview? prod

# Done! 🎉
```

### Workflow 2: Build Then Review

```bash
# Build first
./build-only.sh

# Test locally (optional)
cd build/web
python3 -m http.server 8000
# Visit http://localhost:8000

# If looks good, deploy
vercel --prod
```

### Workflow 3: Manual Control

```bash
# Clean
rm -rf build/web

# Build
flutter build web --release

# Copy config
cp vercel.json build/web/

# Deploy
cd build/web
vercel --prod
```

---

## 🔍 What Each Script Does

### `deploy.sh` Details

```bash
╔══════════════════════════════════════════════════════════╗
║     Flutter Web → Vercel Deployment Script              ║
╚══════════════════════════════════════════════════════════╝

[1/4] Cleaning old build...
✓ Removed old build/web directory

[2/4] Building Flutter web app...
→ Running: flutter build web --release
✓ Build completed successfully!
✓ Build output size: 33M

[3/4] Preparing for Vercel deployment...
✓ Copied vercel.json to build/web/
→ Verifying build output...
✓ index.html exists
✓ main.dart.js exists (3.6M)
✓ vercel.json exists

[4/4] Deployment options...
Deploy to Vercel now? (y/N): _
```

### `build-only.sh` Details

```bash
🧹 Cleaning old build...
🏗️  Building Flutter web app...
📋 Copying vercel.json...

✅ Build complete!

Build output: build/web/
Build size: 33M

To deploy:
  cd build/web && vercel --prod
```

---

## ✅ Benefits of Using Scripts

### Why Use Scripts?

1. **Always Fresh Build**
   - Removes old build directory
   - No stale files or cache issues
   
2. **Automatic Config**
   - Always copies latest `vercel.json`
   - No manual steps to forget

3. **Verification**
   - Checks that critical files exist
   - Shows build size
   - Catches errors early

4. **Consistency**
   - Same process every time
   - No human errors
   - Reproducible builds

5. **Speed**
   - One command instead of many
   - No need to remember steps

---

## 🔧 Customizing the Scripts

### Make Them Faster

Edit `deploy.sh` or `build-only.sh` and add build flags:

```bash
# Skip tree-shaking (faster build, larger size)
flutter build web --release --no-tree-shake-icons

# Use specific renderer
flutter build web --release --web-renderer html

# Disable Wasm warnings
flutter build web --release --no-wasm-dry-run
```

### Add Pre-Build Checks

Add to the top of the script:

```bash
# Check Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found!"
    exit 1
fi

# Run tests first
echo "Running tests..."
flutter test
```

### Add Post-Deploy Actions

Add at the end:

```bash
# Open deployed URL
echo "Opening deployment..."
vercel open

# Send notification
osascript -e 'display notification "Deployment complete!" with title "Vercel"'
```

---

## 🎯 Recommended Usage

For most cases, use the **interactive script**:

```bash
./deploy.sh
```

Benefits:
- ✅ Guides you through the process
- ✅ Verifies everything before deploying
- ✅ Option to test locally first
- ✅ Choose production or preview

---

## 🐛 Troubleshooting

### Script Permission Denied

```bash
chmod +x deploy.sh build-only.sh
```

### Build Fails

Check Flutter installation:
```bash
flutter doctor
flutter --version
```

### vercel Command Not Found

Install Vercel CLI:
```bash
npm i -g vercel
```

### Old Build Still There

The scripts should auto-remove, but you can force:
```bash
rm -rf build/web
./build-only.sh
```

---

## 📝 Pro Tips

### 1. Create Aliases

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
alias deploy-trippo='cd /Users/azayed/aidev/trippobuckley/trippo_user && ./deploy.sh'
alias build-trippo='cd /Users/azayed/aidev/trippobuckley/trippo_user && ./build-only.sh'
```

Then from anywhere:
```bash
deploy-trippo
```

### 2. Git Hook for Auto-Deploy

Create `.git/hooks/post-commit`:
```bash
#!/bin/bash
read -p "Deploy to Vercel? (y/N): " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./deploy.sh
fi
```

### 3. Watch Mode

For development (not deployment):
```bash
# Terminal 1: Watch and rebuild
while true; do
  inotifywait -r lib/
  ./build-only.sh
done

# Terminal 2: Serve
cd build/web && python3 -m http.server 8000
```

---

## 🚀 Quick Reference

| Task | Command |
|------|---------|
| **Full interactive deploy** | `./deploy.sh` |
| **Build only** | `./build-only.sh` |
| **Manual deploy** | `cd build/web && vercel --prod` |
| **Preview deploy** | `cd build/web && vercel` |
| **Test locally** | `cd build/web && python3 -m http.server 8000` |
| **Clean build** | `rm -rf build/web` |
| **Check build size** | `du -sh build/web` |

---

## ✨ Summary

**Best Practice Workflow:**

1. Make changes to your Flutter code
2. Run `./deploy.sh`
3. Choose to deploy
4. Test the deployed URL
5. Done! 🎉

**That's it!** No more manual steps, no more forgetting to copy `vercel.json`, no more stale builds.

---

Generated: November 1, 2025

