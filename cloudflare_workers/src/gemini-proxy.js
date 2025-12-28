/**
 * Gemini AI Proxy Worker
 *
 * Securely proxies requests to Google's Gemini API.
 * API keys are stored in Cloudflare secrets, never exposed to client.
 *
 * Client sends keyIndex (1-20) for round-robin rotation.
 * Worker maps index to actual API key.
 *
 * Environment Variables (Cloudflare Secrets):
 * - GEMINI_API_KEY_1 through GEMINI_API_KEY_20
 */

export default {
  async fetch(request, env) {
    // CORS headers for PWA access
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Only accept POST requests
    if (request.method !== 'POST') {
      return jsonResponse({ error: 'Method not allowed' }, 405, corsHeaders);
    }

    try {
      const body = await request.json();
      const { keyIndex, model, contents, generationConfig, safetySettings } = body;

      // Validate keyIndex (1-20)
      if (!keyIndex || keyIndex < 1 || keyIndex > 20) {
        return jsonResponse({ error: 'Invalid keyIndex (must be 1-20)' }, 400, corsHeaders);
      }

      // Get API key from secrets based on index
      const apiKey = getApiKey(env, keyIndex);
      if (!apiKey) {
        return jsonResponse({ error: `API key ${keyIndex} not configured` }, 500, corsHeaders);
      }

      // Default model if not specified
      const geminiModel = model || 'gemini-2.0-flash';

      // Build Gemini API URL
      const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${apiKey}`;

      // Forward request to Gemini
      const geminiResponse = await fetch(geminiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents,
          generationConfig: generationConfig || {
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 2048,
          },
          safetySettings: safetySettings || [
            { category: 'HARM_CATEGORY_HARASSMENT', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
            { category: 'HARM_CATEGORY_HATE_SPEECH', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
            { category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
            { category: 'HARM_CATEGORY_DANGEROUS_CONTENT', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
          ],
        }),
      });

      // Parse Gemini response
      const geminiData = await geminiResponse.json();

      // Check for errors
      if (!geminiResponse.ok) {
        console.error('Gemini API error:', geminiData);
        return jsonResponse({
          error: 'Gemini API error',
          details: geminiData.error?.message || 'Unknown error',
          status: geminiResponse.status,
        }, geminiResponse.status, corsHeaders);
      }

      // Return successful response
      return jsonResponse(geminiData, 200, corsHeaders);

    } catch (error) {
      console.error('Proxy error:', error);
      return jsonResponse({
        error: 'Internal proxy error',
        message: error.message,
      }, 500, corsHeaders);
    }
  }
};

/**
 * Get API key from environment based on index (1-20)
 */
function getApiKey(env, index) {
  const keyName = `GEMINI_API_KEY_${index}`;
  return env[keyName] || null;
}

/**
 * Helper to create JSON responses
 */
function jsonResponse(data, status = 200, headers = {}) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
  });
}
