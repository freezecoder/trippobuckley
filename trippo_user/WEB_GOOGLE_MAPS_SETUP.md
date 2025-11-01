# Google Maps Flutter Web Setup Guide

## Why Web Testing Matters

**YES, it absolutely matters!** Flutter web uses a completely different implementation:

1. **Android/iOS**: Uses native Google Maps SDK (`google_maps_flutter_android`, `google_maps_flutter_ios`)
2. **Web**: Uses `google_maps_flutter_web` which requires the **Google Maps JavaScript API** to be loaded in `index.html`

The web platform is fundamentally different and requires special setup.

## Current Setup Status

### ✅ What's Configured:

1. **Package**: `google_maps_flutter: ^2.8.0` includes `google_maps_flutter_web`
2. **Android Config**: API key in `AndroidManifest.xml`
3. **Web Script**: Google Maps JavaScript API script in `index.html`

### ⚠️ The Issue:

According to [official Flutter documentation](https://developers.google.com/maps/flutter-package/config), for web:

1. The Google Maps JavaScript API script **MUST load BEFORE Flutter**
2. The script should **NOT** use `defer` or `async` attributes
3. The `google_maps_flutter_web` package expects the API to be available when it initializes

## How `google_maps_flutter_web` Works

The package:
- Automatically detects if Google Maps JavaScript API is loaded
- Uses it to render the `GoogleMap` widget
- Handles map rendering, markers, polylines, etc.

## Our Additional Custom Code

We also use custom JavaScript interop (`google_places_web.dart`) for:
- **Places Autocomplete** (to bypass CORS)
- **Directions API** (to bypass CORS)
- **Geocoding** (to bypass CORS)

This is necessary because Google Maps REST APIs don't support CORS, so we use the JavaScript API directly.

## The Problem We're Seeing

From the console logs:
1. Google Maps API script loads with callback
2. But Flutter initializes before the callback fires
3. Our custom code checks for API but doesn't find it ready
4. Falls back to REST API → CORS error

## Solution

The `index.html` has been updated to:
1. Define callback BEFORE loading script
2. Load Google Maps script WITHOUT defer/async
3. Wait briefly for Google Maps to be ready before initializing Flutter
4. Verify all required APIs (places, DirectionsService, Geocoder) are loaded

## Verification

After the fix, you should see in browser console:
```
Google Maps API callback triggered - API is ready
Google Maps object available
Places: true
DirectionsService: true
Geocoder: true
Google Maps API confirmed ready, initializing Flutter
```

## Testing on Different Platforms

### Web (Current Issue)
- Requires `index.html` setup
- Uses JavaScript API
- Subject to CORS restrictions
- Needs proper script loading order

### Android
- Uses native SDK
- API key in `AndroidManifest.xml`
- No CORS issues
- Generally more reliable

### iOS  
- Uses native SDK
- API key in `AppDelegate.swift`
- No CORS issues
- Generally more reliable

## Best Practice

1. **Test on web during development** - Catch CORS and timing issues early
2. **Test on mobile before release** - Native implementations are more stable
3. **Use web as primary during development** - Faster iteration

## References

- [Official Flutter Maps Setup](https://developers.google.com/maps/flutter-package/config)
- [google_maps_flutter_web package](https://pub.dev/packages/google_maps_flutter_web)
- [Google Maps JavaScript API](https://developers.google.com/maps/documentation/javascript)

