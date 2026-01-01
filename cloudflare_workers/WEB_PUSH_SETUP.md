# Web Push Notification Setup Guide

## Overview

This guide walks you through deploying the Web Push notification system using Cloudflare Workers and KV storage.

## Prerequisites

- Cloudflare account with Workers enabled
- `wrangler` CLI installed (`npm install -g wrangler`)
- Logged in to Wrangler (`wrangler login`)

## Step 1: Generate VAPID Keys

VAPID (Voluntary Application Server Identification) keys are required for Web Push authentication.

```bash
cd cloudflare_workers

# Option A: Using web-push (recommended)
npx web-push generate-vapid-keys

# Output will look like:
# Public Key: BNbxGnR...
# Private Key: 3KSW8sC...
```

Save both keys - you'll need them in Step 3.

## Step 2: Create KV Namespace

```bash
# Create the KV namespace for storing subscriptions
wrangler kv:namespace create PUSH_SUBSCRIPTIONS -c wrangler-webpush.toml

# Output will show something like:
# Add the following to your wrangler.toml:
# [[kv_namespaces]]
# binding = "PUSH_SUBSCRIPTIONS"
# id = "abc123..."
```

Copy the `id` value and update `wrangler-webpush.toml`:

```toml
[[kv_namespaces]]
binding = "PUSH_SUBSCRIPTIONS"
id = "abc123..."  # <-- Replace with your actual ID
```

## Step 3: Set VAPID Secrets

```bash
# Set the public key
wrangler secret put VAPID_PUBLIC_KEY -c wrangler-webpush.toml
# Paste your public key when prompted

# Set the private key
wrangler secret put VAPID_PRIVATE_KEY -c wrangler-webpush.toml
# Paste your private key when prompted
```

## Step 4: Deploy the Worker

```bash
wrangler deploy -c wrangler-webpush.toml
```

Your worker will be available at:
`https://edc-web-push.connect-2a2.workers.dev`

## Step 5: Verify Deployment

```bash
curl https://edc-web-push.connect-2a2.workers.dev/status
```

Should return:
```json
{
  "status": "ok",
  "vapidConfigured": true,
  "kvConfigured": true,
  "subscriberCount": 0
}
```

## Step 6: Update Flutter App

The VAPID public key needs to be set in the Flutter app. Update `web/web-push-client.js`:

```javascript
// In web-push-client.js, the VAPID key is fetched from the worker
// No changes needed - it auto-fetches from /vapid-public-key
```

Or hardcode it in `lib/core/services/web_push_notification_service.dart`:

```dart
// In your app initialization
WebPushNotificationService.setVapidKey('YOUR_PUBLIC_KEY_HERE');
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/subscribe` | POST | Store push subscription |
| `/unsubscribe` | POST | Remove subscription |
| `/send` | POST | Send to specific user |
| `/send-all` | POST | Broadcast to all |
| `/vapid-public-key` | GET | Get VAPID public key |
| `/status` | GET | Service health check |

### Subscribe Example

```bash
curl -X POST https://edc-web-push.connect-2a2.workers.dev/subscribe \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "subscription": {
      "endpoint": "https://fcm.googleapis.com/...",
      "keys": {
        "p256dh": "...",
        "auth": "..."
      }
    }
  }'
```

### Send Notification Example

```bash
curl -X POST https://edc-web-push.connect-2a2.workers.dev/send \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "title": "Daily Devotional",
    "body": "Your devotional is ready!",
    "badgeCount": 1,
    "url": "/devotional"
  }'
```

## Scheduled Notifications

The worker includes a cron trigger that runs daily at 6:00 AM UTC to send devotional reminders to all subscribers. Modify the cron schedule in `wrangler-webpush.toml`:

```toml
[triggers]
crons = ["0 6 * * *"]  # 6 AM UTC daily
```

## Troubleshooting

### "VAPID key not configured"
Run `wrangler secret put VAPID_PUBLIC_KEY -c wrangler-webpush.toml`

### "KV namespace not found"
Create it with `wrangler kv:namespace create PUSH_SUBSCRIPTIONS`

### Push not received
- Check browser notification permissions
- Verify service worker is registered
- Check browser console for errors

## Cost Estimate

- **Free tier**: Up to 100K requests/day, 1GB KV storage
- Typical usage: ~1K requests/day = **$0/month**
