import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

/**
 * Google Places API Proxy for Web
 * 
 * This Cloud Function acts as a proxy to bypass CORS restrictions
 * when calling Google Places API from web browsers.
 */

const GOOGLE_MAPS_API_KEY = 'AIzaSyAnsK0I2lw7YP3qhUthMBtlsiJ31WVkPrY';
const PLACES_API_BASE = 'https://maps.googleapis.com/maps/api/place';

/**
 * Autocomplete - Get place predictions
 * 
 * Usage:
 * POST /placesAutocomplete
 * Body: { "input": "Target", "country": "us" }
 */
export const placesAutocomplete = functions.https.onCall(async (data, context) => {
  try {
    const { input, country = 'us', language = 'en' } = data;

    if (!input || input.length < 2) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Input must be at least 2 characters'
      );
    }

    console.log(`🔍 Autocomplete search: "${input}"`);

    const url = `${PLACES_API_BASE}/autocomplete/json`;
    const params = {
      input,
      key: GOOGLE_MAPS_API_KEY,
      language,
      components: `country:${country}`,
    };

    const response = await axios.get(url, { params });

    console.log(`📡 API Status: ${response.data.status}`);
    console.log(`📊 Results: ${response.data.predictions?.length || 0}`);

    if (response.data.status === 'OK') {
      return {
        success: true,
        predictions: response.data.predictions,
      };
    } else {
      console.error(`❌ API Error: ${response.data.status} - ${response.data.error_message}`);
      throw new functions.https.HttpsError(
        'internal',
        `Google Places API error: ${response.data.status}`
      );
    }
  } catch (error: any) {
    console.error('❌ Autocomplete error:', error);
    throw new functions.https.HttpsError(
      'internal',
      error.message || 'Failed to search places'
    );
  }
});

/**
 * Place Details - Get coordinates for a place
 * 
 * Usage:
 * POST /placeDetails
 * Body: { "placeId": "ChIJ..." }
 */
export const placeDetails = functions.https.onCall(async (data, context) => {
  try {
    const { placeId } = data;

    if (!placeId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'placeId is required'
      );
    }

    console.log(`📍 Getting details for place: ${placeId}`);

    const url = `${PLACES_API_BASE}/details/json`;
    const params = {
      place_id: placeId,
      key: GOOGLE_MAPS_API_KEY,
      fields: 'name,geometry,formatted_address,place_id',
    };

    const response = await axios.get(url, { params });

    console.log(`📡 API Status: ${response.data.status}`);

    if (response.data.status === 'OK') {
      const result = response.data.result;
      return {
        success: true,
        name: result.name,
        latitude: result.geometry.location.lat,
        longitude: result.geometry.location.lng,
        address: result.formatted_address,
        placeId: result.place_id,
      };
    } else {
      console.error(`❌ API Error: ${response.data.status} - ${response.data.error_message}`);
      throw new functions.https.HttpsError(
        'internal',
        `Google Places API error: ${response.data.status}`
      );
    }
  } catch (error: any) {
    console.error('❌ Place details error:', error);
    throw new functions.https.HttpsError(
      'internal',
      error.message || 'Failed to get place details'
    );
  }
});

