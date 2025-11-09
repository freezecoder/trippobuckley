/**
 * Google Places API Proxy for Web
 * 
 * Handles CORS by proxying Google Places API calls through Cloud Functions
 */

const functions = require('firebase-functions');
const axios = require('axios');

const GOOGLE_MAPS_API_KEY = 'AIzaSyAnsK0I2lw7YP3qhUthMBtlsiJ31WVkPrY';
const PLACES_API_BASE = 'https://maps.googleapis.com/maps/api/place';

/**
 * Places Autocomplete
 * Searches for places based on user input
 * 
 * Request: { 
 *   input: string, 
 *   country?: string, 
 *   language?: string,
 *   latitude?: number,
 *   longitude?: number,
 *   radius?: number (in meters)
 * }
 * Response: { success: boolean, predictions: array }
 */
exports.placesAutocomplete = functions.https.onCall(async (data, context) => {
  try {
    const { input, country = 'us', language = 'en', latitude, longitude, radius } = data;

    // Validate input
    if (!input || input.length < 2) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Input must be at least 2 characters'
      );
    }

    const hasLocation = latitude !== undefined && longitude !== undefined;
    console.log(`🔍 Autocomplete: "${input}" (country: ${country}${hasLocation ? `, location: ${latitude},${longitude}` : ''})`);

    // Build API params
    const params = {
      input,
      key: GOOGLE_MAPS_API_KEY,
      language,
      components: `country:${country}`,
    };

    // Add location bias if coordinates provided
    if (hasLocation) {
      params.location = `${latitude},${longitude}`;
      params.radius = radius || 50000; // Default 50km
      console.log(`📍 Using location bias: ${params.location} (radius: ${params.radius}m)`);
    }

    // Call Google Places API
    const url = `${PLACES_API_BASE}/autocomplete/json`;
    const response = await axios.get(url, {
      params,
      timeout: 10000, // 10 second timeout
    });

    console.log(`📡 Google API Status: ${response.data.status}`);

    if (response.data.status === 'OK') {
      console.log(`✅ Found ${response.data.predictions.length} predictions`);
      return {
        success: true,
        predictions: response.data.predictions,
        status: response.data.status,
      };
    } else if (response.data.status === 'ZERO_RESULTS') {
      return {
        success: true,
        predictions: [],
        status: 'ZERO_RESULTS',
      };
    } else {
      console.error(`❌ API Error: ${response.data.status} - ${response.data.error_message}`);
      throw new functions.https.HttpsError(
        'internal',
        `Google Places API error: ${response.data.status} - ${response.data.error_message || 'Unknown error'}`
      );
    }
  } catch (error) {
    console.error('❌ Autocomplete error:', error.message);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      `Failed to search places: ${error.message}`
    );
  }
});

/**
 * Place Details
 * Gets detailed information including coordinates for a place
 * 
 * Request: { placeId: string }
 * Response: { success: boolean, name, latitude, longitude, address, placeId }
 */
exports.placeDetails = functions.https.onCall(async (data, context) => {
  try {
    const { placeId } = data;

    if (!placeId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'placeId is required'
      );
    }

    console.log(`📍 Place details: ${placeId}`);

    // Call Google Places API
    const url = `${PLACES_API_BASE}/details/json`;
    const response = await axios.get(url, {
      params: {
        place_id: placeId,
        key: GOOGLE_MAPS_API_KEY,
        fields: 'name,geometry,formatted_address,place_id',
      },
      timeout: 10000,
    });

    console.log(`📡 Google API Status: ${response.data.status}`);

    if (response.data.status === 'OK') {
      const result = response.data.result;
      console.log(`✅ Place: ${result.name}`);
      
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
        `Google Places API error: ${response.data.status} - ${response.data.error_message || 'Unknown error'}`
      );
    }
  } catch (error) {
    console.error('❌ Place details error:', error.message);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      `Failed to get place details: ${error.message}`
    );
  }
});

