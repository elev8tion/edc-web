# EmailIt Integration - Complete Setup

**Status:** Worker updated with EmailIt API (50,000 emails/month)
**Email:** All emails sent from `connect@everydaychristian.app`

---

## ✅ What's Already Done

- [x] Updated stripe-webhook.js to use EmailIt API
- [x] Changed all email addresses to `connect@everydaychristian.app`
- [x] Deployed updated worker
- [x] Worker URL: `https://stripe-webhook-handler.connect-2a2.workers.dev`

---

## 📋 Next Steps (5 minutes)

### Step 1: Add EmailIt API Key to Worker

**Get your API key:**
1. Log into EmailIt dashboard
2. Go to Credentials section
3. Copy your API key

**Add to worker:**
```bash
cd /Users/kcdacre8tor/edc_web/cloudflare_workers
wrangler secret put EMAILIT_API_KEY --name stripe-webhook-handler
```

When prompted, paste your EmailIt API key.

---

### Step 2: Configure Sending Domain in EmailIt

EmailIt requires you to verify your sending domain before sending emails.

**Set up domain:**
1. Go to EmailIt Dashboard → Sending Domains
2. Add domain: `everydaychristian.app`
3. Add the DNS records they provide (TXT, DKIM, etc.)
4. Wait for verification (usually 5-10 minutes)
5. Set `connect@everydaychristian.app` as verified sender

**Important:** You must verify the domain before emails will send!

---

### Step 3: Update Stripe Webhook

**Current:** Old Activepieces URL (not working)
**New:** `https://stripe-webhook-handler.connect-2a2.workers.dev`

**Steps:**
1. Go to [Stripe Dashboard → Webhooks](https://dashboard.stripe.com/test/webhooks)
2. Find existing webhook (if any) and delete it
3. Click "+ Add endpoint"
4. Endpoint URL: `https://stripe-webhook-handler.connect-2a2.workers.dev`
5. Select event: `invoice.payment_succeeded`
6. Click "Add endpoint"
7. Copy the webhook signing secret
8. Update `.env` line 105:
   ```
   STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxx
   ```

---

### Step 4: Test the Complete Flow

**Test Stripe webhook:**
```bash
stripe trigger invoice.payment_succeeded
```

**Watch worker logs in real-time:**
```bash
wrangler tail stripe-webhook-handler
```

**What should happen:**
1. Stripe sends webhook → Worker receives it
2. Worker generates code (e.g., M-A7B-92K)
3. Worker saves to NoCodeBackend ✅
4. Worker updates Stripe invoice metadata ✅
5. Worker sends email via EmailIt ✅
6. You receive email at customer's address with activation code

---

## 🔍 Verify EmailIt Integration

**Check if EmailIt is working:**

After triggering the test webhook, check:
1. Worker logs: `wrangler tail stripe-webhook-handler`
2. EmailIt Dashboard → Events → Check for sent email
3. Check customer's inbox for activation email

**If email doesn't send:**
- Verify domain is configured in EmailIt
- Check API key is correct: `wrangler secret list --name stripe-webhook-handler`
- View detailed logs for errors

---

## 📧 Email Template Preview

**Subject:** Your Activation Code - Everyday Christian

**From:** Everyday Christian <connect@everydaychristian.app>

**Reply-to:** connect@everydaychristian.app

**Content:**
```
✅ Subscription Activated!

Thank you for subscribing to Everyday Christian Premium.

Your Activation Code:
M-ABC-123

To activate your subscription:
1. Open the Everyday Christian app
2. Tap "Activate Premium" or go to Settings
3. Enter the code above when prompted
4. Enjoy 150 messages per month!

💡 Save this email - you'll need the code to reinstall the app
or activate on a new device.

Questions? Reply to this email or contact connect@everydaychristian.app
```

---

## 🛠️ EmailIt API Details

**Endpoint:** `https://api.emailit.com/v1/emails`

**Authentication:** Bearer token (your API key)

**Request format:**
```json
{
  "from": "Everyday Christian <connect@everydaychristian.app>",
  "to": "customer@example.com",
  "reply_to": "connect@everydaychristian.app",
  "subject": "Your Activation Code - Everyday Christian",
  "html": "..."
}
```

**Response:** Success (200) or error details

---

## 💰 EmailIt Plan

**Your plan:** 50,000 emails/month
**Current usage:** 0 emails (new integration)
**Cost per email:** $0 (included in plan)

This is more than enough for your app's needs.

---

## ❓ Troubleshooting

**EmailIt errors in logs?**
- Check domain is verified in EmailIt dashboard
- Verify API key is correct
- Check sending limits haven't been reached

**Email not received?**
- Check spam/junk folder
- Verify customer email is valid
- Check EmailIt Events dashboard for delivery status

**Worker errors?**
- View logs: `wrangler tail stripe-webhook-handler`
- Check all environment variables are set
- Verify NoCodeBackend API key is correct

---

## 📊 Monitoring

**View real-time logs:**
```bash
wrangler tail stripe-webhook-handler
```

**EmailIt Dashboard:**
- View sent emails
- Check delivery status
- Monitor usage

**Cloudflare Dashboard:**
- Worker metrics
- Request counts
- Error rates

---

**Next:** Complete steps 1-4 above, then test your complete activation flow! 🚀
