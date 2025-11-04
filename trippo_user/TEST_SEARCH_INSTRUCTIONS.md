# Google Places Search - Standalone Test

## 🧪 Purpose

This standalone test page helps debug the Google Places search independently from the main app.

---

## 🚀 How to Run

### Method 1: Temporarily Replace Main

1. **Backup your current main.dart:**
   ```bash
   cp lib/main.dart lib/main.dart.backup
   ```

2. **Update main.dart to run the test:**
   ```dart
   // At the top of lib/main.dart, add:
   import 'package:btrips_unified/test_search_page.dart';
   
   // Replace the runApp line with:
   void main() {
     runApp(const TestSearchPage());
   }
   ```

3. **Run the app:**
   ```bash
   flutter run -d chrome
   ```

4. **Restore main.dart after testing:**
   ```bash
   mv lib/main.dart.backup lib/main.dart
   ```

---

### Method 2: Create Separate Entry Point

1. **Create a new test file:**
   ```bash
   # The file lib/test_search_page.dart already has main() function
   ```

2. **Run it directly:**
   ```bash
   cd /Users/azayed/aidev/trippobuckley/trippo_user
   flutter run -t lib/test_search_page.dart -d chrome
   ```

---

## 🔍 What to Test

1. **Open the test page** - You'll see:
   - Info card showing platform and API key
   - Search field
   - Empty state with instructions

2. **Type "Target"** in the search field

3. **Wait 800ms** for debounce

4. **Check console** for debug output:
   ```
   🔍 TEST: Searching for: "Target"
   🔑 TEST: Using API key: AIzaSyAnsK0I2lw7YP3qh...
   🌐 TEST: Platform: WEB
   📱 TEST: Calling GooglePlacesWeb.getPlacePredictions()
   ✅ TEST: Got 5 raw predictions
      - Target, Main St, New York
      - Target, Broadway, Los Angeles
      ...
   ✅ TEST: Successfully parsed 5 places
   ```

5. **See results** in the UI:
   - Each result shown in a card
   - Number, name, address, place ID

---

## 🎯 What This Tests

### ✅ Verified:
- Google Maps JavaScript API loading
- API key validity
- Places Autocomplete working
- JSON parsing
- UI rendering

### ⚠️ If You See Errors:

#### Error: "GooglePlacesWeb not found"
**Cause:** JavaScript API not loaded  
**Fix:** Check `web/index.html` has the Google Maps script

#### Error: "Assertion failed: window.dart:99:12"
**Cause:** Rendering issue (same as main app)  
**Solution:** This is a Flutter web engine issue, try:
```bash
flutter clean
flutter pub get
flutter run -d chrome --web-renderer html
```

#### Error: "REQUEST_DENIED"
**Cause:** API key restrictions  
**Fix:** Check Google Cloud Console:
- Enable "Places API"
- Remove domain restrictions for testing
- Check billing is enabled

#### No results appearing
**Cause:** Could be several things  
**Debug:**
1. Open browser DevTools (F12)
2. Check Console tab for errors
3. Check Network tab - look for API calls
4. Click "Force Test" button - check console logs

---

## 🐛 Debugging Features

### Console Logging

The test page prints detailed logs:
```
🔍 = Search initiated
🔑 = API key being used
🌐 = Platform detected
📱 = API method being called
✅ = Success
❌ = Error
```

### Force Test Button

Blue button at bottom right:
- Click to manually trigger search
- Prints current state to console
- Useful if debounce isn't firing

### Clear Button

X button in search field:
- Clears text
- Resets results
- Clears errors

---

## 📊 Expected Results

### For "Target":
```
Found 5 results:
1. Target - 123 Main St, New York, NY
2. Target - 456 Broadway, Los Angeles, CA
3. Target - 789 Oak Ave, Chicago, IL
...
```

### For "Starbucks":
```
Found 5 results:
1. Starbucks - 100 Market St, San Francisco, CA
2. Starbucks Coffee - 200 Pine St, Seattle, WA
...
```

---

## 🔧 Troubleshooting

### Issue: Assertion failures (window.dart:99:12)

This is the **same error** you're seeing in the main app. It's a Flutter web rendering issue.

**Try these fixes:**

1. **Use HTML renderer instead of CanvasKit:**
   ```bash
   flutter run -d chrome --web-renderer html
   ```

2. **Clear Flutter cache:**
   ```bash
   flutter clean
   rm -rf build/
   flutter pub get
   flutter run -d chrome
   ```

3. **Check Flutter version:**
   ```bash
   flutter --version
   # Consider upgrading if very old
   ```

4. **Try different browser:**
   ```bash
   flutter run -d edge  # or firefox
   ```

### Issue: "Failed to load resource: 403"

**If you see cors-anywhere:**
- The test page should NOT use cors-anywhere
- It uses JavaScript API directly
- If you see this, check the console logs

**If you see maps.googleapis.com 403:**
- API key issue
- Check Google Cloud Console
- Verify "Places API" is enabled
- Check billing account

### Issue: Search works in test but not in main app

**This means:**
- ✅ API is working fine
- ✅ API key is valid
- ❌ Issue is in main app integration

**Check:**
1. Where To screen navigation
2. State management (providers)
3. Map controller initialization
4. Build method errors

---

## 🎨 Test Page Features

### Info Card (Blue)
Shows current configuration:
- Platform (Web/Mobile)
- API Key (first 20 chars)
- Country restriction
- Debounce time

### Search Field
- Autocomplete disabled (browser)
- 800ms debounce
- Clear button when text present

### Results Display
- Numbered list (1, 2, 3...)
- Place name (bold)
- Address (subtitle)
- Place ID preview

### Loading State
- Spinner + "Searching..." text
- Disables input during search

### Error Display
- Red box with error icon
- Full error message
- Visible in UI

---

## 📝 Test Checklist

- [ ] Test page loads without errors
- [ ] Info card shows correct platform
- [ ] Can type in search field
- [ ] Typing triggers search after 800ms
- [ ] Console shows debug logs
- [ ] Results appear in UI
- [ ] Can click clear button
- [ ] Force Test button works
- [ ] No CORS errors
- [ ] No assertion failures

---

## 🎉 Success Criteria

### ✅ Test Passes If:
1. You type "Target"
2. Console shows successful logs
3. Results appear in UI (5+ items)
4. No errors in console
5. No assertion failures

### ❌ Test Fails If:
1. No results appear
2. Console shows errors
3. Assertion failures appear
4. 403/404 HTTP errors
5. "GooglePlacesWeb not found"

---

## 🔄 Next Steps

### If Test Passes:
- API is working ✅
- Issue is in main app integration
- Check Where To screen code
- Check provider updates
- Check navigation flow

### If Test Fails:
- API issue ❌
- Check API key in Google Cloud Console
- Enable required APIs
- Check billing
- Remove domain restrictions
- Try different API key

---

## 💻 Console Commands

### View detailed logs:
1. Open browser DevTools (F12)
2. Go to Console tab
3. Look for emoji indicators (🔍, ✅, ❌)

### Force a search:
```javascript
// In browser console:
console.log("Testing search...");
```

### Check Google Maps API:
```javascript
// In browser console:
window.google && window.google.maps ? "✅ Loaded" : "❌ Not loaded"
```

---

## 📖 Example Session

```bash
# 1. Run test page
flutter run -t lib/test_search_page.dart -d chrome

# 2. App opens in Chrome
# 3. Type "Target" in search field
# 4. Wait 800ms

# Console output:
🔍 TEST: Searching for: "Target"
🔑 TEST: Using API key: AIzaSyAnsK0I2lw7YP3qh...
🌐 TEST: Platform: WEB
📱 TEST: Calling GooglePlacesWeb.getPlacePredictions()
✅ TEST: Got 5 raw predictions
   - Target, 123 Main St
   - Target, 456 Broadway
   ...
✅ TEST: Successfully parsed 5 places

# UI shows:
Found 5 results:
1. Target - 123 Main St, New York, NY
2. Target - 456 Broadway, Los Angeles, CA
...
```

---

**Status:** Test page ready to run  
**Location:** `lib/test_search_page.dart`  
**Command:** `flutter run -t lib/test_search_page.dart -d chrome`

🧪 **Run this to isolate the search issue!**

