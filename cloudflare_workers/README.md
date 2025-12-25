# Everyday Christian - Cloudflare Workers

Clean, simple activation code system using Cloudflare Workers + NoCodeBackend.

## Architecture

```
Stripe Payment → Worker 1 (Webhook) → NoCodeBackend → Email
Flutter App → Worker 2 (Validation) → NoCodeBackend → App
```

## Files

- `src/stripe-webhook.js` - Handles Stripe webhooks, generates codes
- `src/code-validation.js` - Validates codes from Flutter app
- `wrangler.toml` - Cloudflare configuration

## Setup (5 minutes)

### 1. Install Wrangler CLI

```bash
npm install -g wrangler
```

### 2. Login to Cloudflare

```bash
wrangler login
```

This will open your browser to authenticate.

### 3. Deploy Workers

```bash
cd cloudflare_workers
npm install
npm run deploy:all
```

This deploys both workers and gives you URLs like:
- Stripe webhook: `https://stripe-webhook-handler.YOUR-SUBDOMAIN.workers.dev`
- Validation API: `https://code-validation-api.YOUR-SUBDOMAIN.workers.dev`

### 4. Add Resend API Key (for emails)

1. Sign up at [resend.com](https://resend.com) (free 3k emails/month)
2. Get your API key
3. Add to Worker 1:

```bash
wrangler secret put RESEND_API_KEY --name stripe-webhook-handler
```

Paste your Resend API key when prompted.

### 5. Configure Stripe Webhook

1. Go to Stripe Dashboard → Webhooks
2. Add endpoint: `https://stripe-webhook-handler.YOUR-SUBDOMAIN.workers.dev`
3. Select event: `invoice.payment_succeeded`
4. Save

### 6. Update Flutter App

Update your `.env` file:

```env
ACTIVEPIECES_CODE_VALIDATION_URL=https://code-validation-api.YOUR-SUBDOMAIN.workers.dev
```

## Testing

### Test Stripe Webhook Locally

```bash
npm run dev:stripe
```

Then use Stripe CLI:

```bash
stripe trigger invoice.payment_succeeded
```

### Test Validation API

```bash
curl -X POST https://code-validation-api.YOUR-SUBDOMAIN.workers.dev \\
  -H "Content-Type: application/json" \\
  -d '{"code":"M-ABC-123","deviceId":"test-device-123"}'
```

## Environment Variables

Already configured in `wrangler.toml`:

- `NOCODEBACKEND_API_KEY` - Your NoCodeBackend secret key
- `NOCODEBACKEND_API_URL` - API endpoint
- `STRIPE_API_KEY` - Stripe secret key
- `MONTHLY_PRICE_ID` - Stripe monthly price ID
- `YEARLY_PRICE_ID` - Stripe yearly price ID

Add manually:
- `RESEND_API_KEY` - For sending emails (use `wrangler secret put`)

## How It Works

### Worker 1: Stripe Webhook

1. Stripe sends `invoice.payment_succeeded` event
2. Worker generates activation code (M-XXX-XXX format)
3. Saves to NoCodeBackend database
4. Updates Stripe invoice metadata
5. Sends email with code to customer

### Worker 2: Code Validation

1. Flutter app sends `POST` with `{code, deviceId}`
2. Worker looks up code in NoCodeBackend
3. Validates: exists, unused, not expired
4. Marks as used with device ID
5. Returns subscription details to app

## Updating Workers

After making changes:

```bash
npm run deploy:all
```

Changes deploy instantly.

## Monitoring

View logs in real-time:

```bash
wrangler tail stripe-webhook-handler
wrangler tail code-validation-api
```

Or check Cloudflare Dashboard → Workers → Logs

## Cost

**Free tier includes:**
- 100,000 requests/day
- Unlimited script size
- Zero cold starts

This is more than enough for your app.

## Troubleshooting

**Worker not receiving requests?**
- Check worker URL in Stripe/Flutter app
- View logs: `wrangler tail <worker-name>`

**NoCodeBackend errors?**
- Verify API key in wrangler.toml
- Check database has all 9 columns

**Email not sending?**
- Add RESEND_API_KEY: `wrangler secret put RESEND_API_KEY --name stripe-webhook-handler`
- Verify domain in Resend dashboard

## Migration from Activepieces

✅ Old Activepieces flows archived to `activepieces_setup_ARCHIVE/`

Changes needed:
1. ✅ Workers deployed
2. ✅ Update Stripe webhook URL
3. ✅ Update `.env` with validation URL
4. Test end-to-end flow

## Support

- Cloudflare Docs: https://developers.cloudflare.com/workers/
- Wrangler CLI: https://developers.cloudflare.com/workers/wrangler/
- Resend Docs: https://resend.com/docs
