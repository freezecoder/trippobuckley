# CORS Solution for Web Development

## Problem
Google Maps REST APIs (Geocoding, Places, Directions) don't support CORS for direct browser requests. This causes errors like:
```
Access to XMLHttpRequest at 'https://maps.googleapis.com/...' from origin 'http://localhost:56686' 
has been blocked by CORS policy: Request header field content-type is not allowed by 
Access-Control-Allow-Headers in preflight response.
```

## Solution Implemented ✅

### 1. **JavaScript API Integration**
All Google Maps APIs now use the **JavaScript API** on web platform to bypass CORS completely:

- ✅ **Places Autocomplete** → Uses `AutocompleteService` from JavaScript API
- ✅ **Place Details** → Uses `PlacesService` from JavaScript API  
- ✅ **Reverse Geocoding** → Uses `Geocoder` from JavaScript API
- ✅ **Directions** → Uses `DirectionsService` from JavaScript API

### 2. **How It Works**

#### For Web Platform:
1. Checks if Google Maps JavaScript API is loaded (from `index.html`)
2. Uses JavaScript interop (`dart:js`) to call the JavaScript API directly
3. No CORS issues because JavaScript API is designed for browser use
4. Falls back to REST API if JavaScript API fails

#### For Mobile/Desktop:
- Uses REST API directly (no CORS restrictions on native platforms)

### 3. **Files Modified**

1. **`lib/Container/utils/google_places_web.dart`**:
   - Added `reverseGeocode()` method
   - Added `getDirections()` method
   - Uses Google Maps JavaScript API via Dart JS interop

2. **`lib/Container/Repositories/address_parser_repo.dart`**:
   - Now uses `GooglePlacesWeb.reverseGeocode()` on web
   - Falls back to REST API for mobile/desktop

3. **`lib/Container/Repositories/direction_polylines_repo.dart`**:
   - Now uses `GooglePlacesWeb.getDirections()` on web
   - Falls back to REST API for mobile/desktop

4. **`lib/Container/utils/http_client.dart`**:
   - Removes `Content-Type` header for GET requests to Google Maps APIs on web
   - This prevents CORS preflight issues

### 4. **Testing Locally on Web**

#### Prerequisites:
- Google Maps JavaScript API must be loaded in `index.html` ✅ (Already done)
- API key must be valid and have required APIs enabled

#### Run the app:
```bash
cd btrips_user
flutter run -d chrome
# or
flutter run -d edge
```

#### What to expect:
- ✅ No CORS errors
- ✅ Places autocomplete works
- ✅ Reverse geocoding works
- ✅ Directions API works
- ✅ All Google Maps features work seamlessly

### 5. **How to Verify It's Working**

1. **Check Console Logs**:
   - No CORS errors should appear
   - You may see "JavaScript API failed, falling back to REST" if API isn't loaded yet
   - Once Google Maps API loads, all requests use JavaScript API

2. **Test Features**:
   - Type in search box → Should show place suggestions (using JavaScript API)
   - Select a location → Should show address (using JavaScript API)
   - Request a ride → Should show route polyline (using JavaScript API)

### 6. **Alternative: Local Development Server**

If you need to test REST API calls directly, you can use a local proxy server:

#### Option A: Using CORS Proxy (Not Recommended for Production)
```bash
# Install cors-anywhere locally
npm install -g cors-anywhere
cors-anywhere
```

Then modify your API URLs to use the proxy (NOT recommended for production).

#### Option B: Use Mobile/Desktop Platforms (Recommended)
```bash
# Run on Android/iOS/macOS/Windows (no CORS issues)
flutter run -d <device-id>

# List available devices
flutter devices
```

### 7. **Why This Solution Works**

1. **JavaScript API** is designed for browser use and doesn't have CORS restrictions
2. **Automatic Fallback** ensures the app still works if JavaScript API fails
3. **Platform Detection** automatically chooses the right method
4. **No Code Changes Needed** for mobile/desktop - they use REST API as before

### 8. **Troubleshooting**

#### If CORS errors still appear:
1. **Check Google Maps API is loaded**:
   - Open browser DevTools → Console
   - Type: `google.maps` → Should return object (not undefined)

2. **Verify API Key**:
   - Check `web/index.html` has the correct API key
   - Ensure key has these APIs enabled:
     - Maps JavaScript API
     - Places API
     - Geocoding API
     - Directions API

3. **Check JavaScript API Loading**:
   - The code waits up to 5 seconds for Google Maps to load
   - If timeout occurs, it falls back to REST API (which will show CORS error)
   - Solution: Ensure Google Maps script loads before Flutter app starts

#### If features don't work:
1. **Check Console for Errors**:
   - Look for JavaScript errors
   - Check if `google.maps` object is available

2. **Verify Libraries**:
   - `index.html` includes: `libraries=places,geometry,drawing`
   - These are required for the JavaScript API features

3. **API Key Restrictions**:
   - If API key has HTTP referrer restrictions, ensure `localhost` is allowed
   - For development, you can temporarily remove restrictions

### 9. **Production Considerations**

#### For Production Web Deployment:
1. **Keep JavaScript API approach** (recommended) - No backend needed
2. **Or use Backend Proxy** - Route all Google Maps API calls through your backend
3. **API Key Restrictions** - Restrict API key to your production domain

#### Recommended Production Setup:
```
Frontend (Flutter Web) → JavaScript API → Google Maps
                     ↓ (if needed)
Backend API → REST API → Google Maps (for sensitive operations)
```

### 10. **Current Status**

✅ **All Google Maps APIs work on web without CORS errors:**
- Places Autocomplete
- Place Details  
- Reverse Geocoding
- Directions

✅ **Automatic platform detection:**
- Web → JavaScript API
- Mobile/Desktop → REST API

✅ **Fallback mechanism:**
- If JavaScript API fails → Falls back to REST (with CORS error message)
- Ensures app doesn't completely break

---

**Result**: You can now develop and test the app locally on web without CORS issues! 🎉

The app automatically uses the JavaScript API when running on web, which completely bypasses CORS restrictions.

