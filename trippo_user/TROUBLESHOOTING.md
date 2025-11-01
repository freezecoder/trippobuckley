# Troubleshooting: App Not Showing Up

## Quick Fixes

### 1. Check Browser Console
Open the browser developer console (F12 or Cmd+Option+I) and look for:
- JavaScript errors (red messages)
- Flutter initialization errors
- Network errors (failed to load scripts)

### 2. Try Running Without Port Specification
```bash
flutter run -d chrome
```
Then check what port it assigns.

### 3. Clear Browser Cache
- Hard refresh: `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)
- Or clear browser cache entirely

### 4. Check if Port 8088 is Available
```bash
# Check if port is in use
lsof -i :8088

# Kill process if needed
kill -9 <PID>
```

### 5. Run in Release Mode
```bash
flutter run -d chrome --web-port=8088 --release
```

### 6. Check Flutter Output
Look for errors in the terminal when running:
- Firebase initialization errors
- Route configuration errors
- Missing dependencies

## Common Issues

### Issue: Blank White Screen
**Possible Causes:**
1. JavaScript error preventing Flutter from initializing
2. Google Maps API blocking (fixed in latest index.html)
3. Firebase initialization error

**Solutions:**
1. Check browser console for errors
2. Try running: `flutter run -d chrome --web-port=8088 --verbose`
3. Check if `flutter.js` and other assets are loading

### Issue: "BTrips" Text Shows But Nothing Else
**This means Flutter is working!**
- The app is waiting for location permission
- Check browser console for permission prompts
- On web, location permission must be granted manually
- After granting, app should navigate to login/home

### Issue: Location Permission Blocking
**Web browsers require user interaction for location:**
- The app requests location permission on startup
- User must click "Allow" in browser prompt
- If denied, app shows error and might exit

**Solution:** Grant location permission when browser asks.

### Issue: Google Maps API Errors
**If you see CORS or API errors:**
- Check Google Maps API key is valid
- Verify API key has proper restrictions
- Check browser console for specific error messages

## Debug Steps

### Step 1: Verify Basic Flutter Web
```bash
cd btrips_user
flutter clean
flutter pub get
flutter run -d chrome --web-port=8088
```

### Step 2: Check Browser Network Tab
1. Open DevTools → Network tab
2. Refresh page
3. Look for:
   - Failed requests (red)
   - `flutter.js` loading successfully
   - `main.dart.js` loading successfully
   - Google Maps API script loading

### Step 3: Check Console Logs
Look for:
```
Flutter initialization error: ...
Google Maps API loaded successfully
FCM Token: ...
```

### Step 4: Test Minimal Route
Temporarily modify `app_routes.dart` to use a simple test screen:
```dart
initialLocation: '/test',
// Add simple test route
GoRoute(
  path: '/test',
  builder: (context, state) => Scaffold(
    body: Center(child: Text('App is working!')),
  ),
)
```

### Step 5: Run in Debug Mode with Verbose
```bash
flutter run -d chrome --web-port=8088 --verbose 2>&1 | tee run.log
```
Then check `run.log` for errors.

## Web-Specific Issues

### Location Permission on Web
- Web browsers show location permission prompt
- Must click "Allow" for app to continue
- If denied, app shows error message
- On localhost, permission is usually granted easily

### Firebase on Web
- Check `firebase_options.dart` has web configuration
- Verify web app is registered in Firebase Console
- Check browser console for Firebase errors

### Google Maps on Web
- API key must allow localhost origins
- Check Google Cloud Console → API restrictions
- Add `http://localhost:8088` to allowed origins

## Still Not Working?

1. **Try different browser:** Edge, Firefox, Safari
2. **Try different port:** `--web-port=3000`
3. **Check Flutter version:** `flutter doctor -v`
4. **Check for Dart errors:** `flutter analyze`
5. **Rebuild from scratch:**
   ```bash
   flutter clean
   rm -rf .dart_tool
   flutter pub get
   flutter run -d chrome --web-port=8088
   ```

## Expected Behavior

When working correctly:
1. Browser opens to `http://localhost:8088`
2. You see "BTrips" text (splash screen)
3. Browser asks for location permission
4. After granting, app navigates to login or home screen

If you see "BTrips" text → App is working! Just waiting for location permission.

