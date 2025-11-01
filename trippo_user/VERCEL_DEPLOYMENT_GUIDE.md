# Vercel Deployment Guide for BTrips Unified App

This guide walks you through deploying your Flutter web app to Vercel for mobile testing.

## Prerequisites

1. ✅ Flutter SDK installed and in PATH
2. ✅ Vercel CLI installed: `npm i -g vercel`
3. ✅ Vercel account (free tier works fine)
4. ✅ Git initialized in project

## Quick Start

### Option 1: Using the Pre-Deployment Script (Recommended)

```bash
# Make the script executable
chmod +x pre-deploy-check.sh

# Run pre-deployment checks
./pre-deploy-check.sh

# If all checks pass, deploy
vercel --prod
```

### Option 2: Manual Deployment Steps

```bash
# 1. Clean previous builds
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Build for web (release mode with CanvasKit renderer)
flutter build web --release --web-renderer canvaskit

# 4. Test locally (optional but recommended)
cd build/web
python3 -m http.server 8000
# Visit http://localhost:8000 in your browser

# 5. Deploy to Vercel
cd ../..  # Back to project root
vercel --prod
```

## First-Time Deployment Setup

When you run `vercel` for the first time:

1. **Login**: The CLI will open your browser to authenticate
2. **Setup Project**:
   - Set up and deploy: **Yes**
   - Which scope: Select your account/team
   - Link to existing project: **No** (for new project)
   - Project name: `btrips-unified` (or your preferred name)
   - In which directory is your code located: `./` (press Enter)
   - Want to modify settings: **Yes**
   
3. **Build Settings**:
   - Build Command: `flutter build web --release --web-renderer canvaskit`
   - Output Directory: `build/web`
   - Development Command: (leave empty)
   
4. **Deploy**: Vercel will now build and deploy your app

## Configuration Files Explained

### `vercel.json`

This file tells Vercel how to build and serve your Flutter web app:

```json
{
  "buildCommand": "flutter build web --release --web-renderer canvaskit",
  "outputDirectory": "build/web",
  "routes": [...],  // SPA routing configuration
  "headers": [...]  // Security and caching headers
}
```

**Key configurations:**
- **CanvasKit Renderer**: More reliable for complex UIs and Google Maps
- **SPA Routing**: All routes redirect to `index.html` for client-side routing
- **Security Headers**: CORS, frame options, and content type protection
- **Cache Headers**: Assets cached for 1 year (immutable)

### `.vercelignore`

Excludes unnecessary files from deployment:
- Platform-specific code (iOS, Android, etc.)
- Build artifacts (except `build/web`)
- Sensitive files (credentials, keys)
- Development files (tests, scripts)

## Build Options

### Web Renderers

1. **CanvasKit** (Recommended for this app):
   ```bash
   flutter build web --release --web-renderer canvaskit
   ```
   - Better for complex UIs and animations
   - Full feature support for Google Maps
   - Larger initial download (~2MB)
   - Consistent across browsers

2. **HTML** (Alternative):
   ```bash
   flutter build web --release --web-renderer html
   ```
   - Smaller bundle size
   - May have compatibility issues with some plugins
   - Not recommended for Google Maps integration

3. **Auto** (Flutter decides):
   ```bash
   flutter build web --release --web-renderer auto
   ```
   - Mobile: uses HTML renderer
   - Desktop: uses CanvasKit renderer

## Environment-Specific Considerations

### Google Maps API Key

The API key is currently hardcoded in `web/index.html`:
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_KEY..."></script>
```

**Security Recommendations:**
1. Restrict the API key in Google Cloud Console:
   - Go to Google Cloud Console → APIs & Services → Credentials
   - Edit your API key
   - Add HTTP referrers: `https://your-app.vercel.app/*`
   - Restrict to specific APIs: Maps JavaScript API, Places API, Directions API

2. For multiple environments, consider using Vercel Environment Variables:
   - Create different API keys for dev/staging/prod
   - Use build-time environment variable substitution

### Firebase Configuration

Firebase config is in `lib/firebase_options.dart` and includes web configuration:
```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSy...',
  projectId: 'trippo-42089',
  // ...
);
```

**Note**: These are safe to include as they're client-side keys. Secure your Firebase:
1. Use Firestore Security Rules
2. Restrict API keys to specific domains
3. Enable App Check for additional security

## Testing After Deployment

### 1. Test on Desktop Browser
Visit your Vercel URL: `https://your-app.vercel.app`

Check:
- ✅ App loads without errors
- ✅ Authentication works
- ✅ Maps display correctly
- ✅ All routes work (refresh on different pages)

### 2. Test on Mobile Browser
Open the Vercel URL on your phone:

**iOS Safari**:
- Test location permissions
- Test in landscape/portrait
- Test "Add to Home Screen"

**Android Chrome**:
- Test location permissions  
- Test in landscape/portrait
- Test PWA installation

### 3. Developer Tools Checks
Open browser DevTools:
- **Console**: Check for JavaScript errors
- **Network**: Verify all assets load (200 status)
- **Application**: Check service worker registration
- **Lighthouse**: Run audit for performance and PWA score

## Common Issues and Solutions

### Issue 1: Blank White Screen
**Cause**: Base href mismatch or build errors
**Solution**:
```bash
flutter clean
flutter pub get
flutter build web --release
```

### Issue 2: Routes Don't Work (404 on Refresh)
**Cause**: Missing SPA routing configuration
**Solution**: Ensure `vercel.json` has the rewrite rule:
```json
"rewrites": [
  { "source": "/(.*)", "destination": "/index.html" }
]
```

### Issue 3: Google Maps Not Loading
**Cause**: API key restrictions or CORS issues
**Solutions**:
1. Check browser console for specific error
2. Verify API key in Google Cloud Console
3. Check that key is restricted to your Vercel domain
4. Ensure `web/index.html` has correct API key

### Issue 4: Firebase Connection Errors
**Cause**: Incorrect Firebase config or CORS
**Solution**:
1. Verify Firebase project settings
2. Add Vercel domain to Firebase authorized domains:
   - Firebase Console → Authentication → Settings → Authorized Domains
   - Add: `your-app.vercel.app`

### Issue 5: Assets Not Loading (Fonts, Images)
**Cause**: Incorrect asset paths after build
**Solution**:
1. Check `pubspec.yaml` has correct asset declarations
2. Verify assets exist in `build/web/assets` after build
3. Check browser Network tab for 404 errors

### Issue 6: Large Bundle Size / Slow Loading
**Solutions**:
1. Use tree-shaking: `flutter build web --release --tree-shake-icons`
2. Optimize images before adding to assets
3. Consider using HTML renderer: `--web-renderer html`
4. Enable code splitting (experimental)

## Monitoring and Analytics

### Vercel Analytics
Enable in Vercel dashboard:
1. Go to your project settings
2. Navigate to "Analytics"
3. Enable Web Analytics (free for personal projects)

### Performance Monitoring
Add to your app:
```bash
flutter pub add firebase_performance
```

### Error Tracking
Consider adding:
- Sentry: `flutter pub add sentry_flutter`
- Firebase Crashlytics (mobile apps)

## Continuous Deployment

### Git Integration (Recommended)

1. **Connect Git Repository**:
   ```bash
   # Push to GitHub/GitLab/Bitbucket
   git add .
   git commit -m "Initial commit"
   git push origin main
   ```

2. **Link to Vercel**:
   - Go to Vercel Dashboard
   - "Import Project" → Select your Git repository
   - Vercel auto-detects Flutter and uses `vercel.json` settings

3. **Auto-Deploy**:
   - Push to `main` → deploys to production
   - Push to other branches → creates preview deployments
   - Pull requests get unique preview URLs

### Manual Deployment

```bash
# Deploy to production
vercel --prod

# Deploy preview (test environment)
vercel

# Deploy with specific name
vercel --prod --name my-app-name
```

## Build Optimization Tips

### 1. Reduce Bundle Size
```bash
# Enable tree-shaking
flutter build web --release --tree-shake-icons

# Split vendor and app bundles
flutter build web --release --split-per-abi
```

### 2. Improve Load Time
- Use `--web-renderer auto` for automatic renderer selection
- Lazy load routes with `go_router`
- Optimize images (use WebP format)
- Enable compression in Vercel (automatic)

### 3. PWA Optimization
Update `web/manifest.json`:
- Add proper icons (192x192, 512x512)
- Set correct `start_url`
- Configure `display` mode
- Add `theme_color` and `background_color`

## Environment Variables (Advanced)

If you need different configs for dev/staging/prod:

### 1. Create `.env` files:
```bash
# .env.development
API_KEY=dev-key

# .env.production  
API_KEY=prod-key
```

### 2. Add to Vercel:
- Dashboard → Project Settings → Environment Variables
- Add variables for each environment

### 3. Use in code:
```dart
const apiKey = String.fromEnvironment('API_KEY', defaultValue: 'fallback');
```

### 4. Build with env:
```bash
flutter build web --release --dart-define=API_KEY=your-key
```

## Rollback and Version Management

### Rollback to Previous Deployment
```bash
# List deployments
vercel ls

# Promote previous deployment to production
vercel promote <deployment-url>
```

### Version Tracking
Update `pubspec.yaml`:
```yaml
version: 2.0.0+1  # Increment before each major deployment
```

## Support and Resources

- **Flutter Web Docs**: https://docs.flutter.dev/platform-integration/web
- **Vercel Docs**: https://vercel.com/docs
- **Flutter Web Renderers**: https://docs.flutter.dev/platform-integration/web/renderers
- **Issue Tracker**: Create issues in your project repository

## Checklist Before Going Live

- [ ] Run `./pre-deploy-check.sh` successfully
- [ ] Test all core features on desktop browser
- [ ] Test on iOS Safari and Android Chrome
- [ ] Verify Google Maps API key restrictions
- [ ] Add Vercel domain to Firebase authorized domains
- [ ] Set up custom domain (if applicable)
- [ ] Enable Vercel Analytics
- [ ] Configure environment variables (if needed)
- [ ] Set up continuous deployment with Git
- [ ] Document any environment-specific configurations
- [ ] Test authentication flow end-to-end
- [ ] Verify all routes work (with page refresh)
- [ ] Check mobile responsiveness
- [ ] Test location permissions on mobile
- [ ] Run Lighthouse audit (aim for 90+ score)

---

**Ready to deploy?** Run `./pre-deploy-check.sh` and follow the prompts! 🚀

