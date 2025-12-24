# Activepieces Activation Code Flows

This document describes the Activepieces flows needed to implement the activation code system for Everyday Christian PWA.

---

## Overview

The activation code system uses **two Activepieces flows**:

1. **Code Generation Flow** - Triggered by Stripe webhooks to generate activation codes
2. **Code Validation Flow** - API endpoint that validates and marks codes as used

---

## Flow 1: Activation Code Generation

### **Trigger:** Stripe Webhook (`invoice.payment_succeeded`)

### **Purpose:** Generate unique activation code when user completes payment

### **Flow Steps:**

```
1. Catch Webhook (Stripe event)
   ↓
2. Extract subscription details
   ↓
3. Generate activation code
   ↓
4. Store in Activepieces Table
   ↓
5. Add code to Stripe invoice metadata
   ↓
6. Send email with activation code
```

### **Implementation:**

#### **Step 1: Webhook Trigger**
- **Type:** Catch Webhook
- **URL:** `https://cloud.activepieces.com/api/v1/webhooks/A8CaLMQg80F4S5NPLiXwp`
- **Authentication:** None (Stripe signature verification optional)

#### **Step 2: Code Step - Generate Activation Code**

```javascript
export const code = async (inputs) => {
  const event = inputs.webhookData;
  const eventType = event.type;

  // Only process payment succeeded events
  if (eventType !== 'invoice.payment_succeeded') {
    return { skipped: true, reason: 'Not a payment success event' };
  }

  const eventData = event.data.object;

  // Get subscription details
  const subscriptionId = eventData.subscription;
  if (!subscriptionId) {
    return { error: 'No subscription ID found' };
  }

  // Determine tier from price ID
  const priceId = eventData.lines.data[0]?.price?.id || '';
  const tier = determineTier(priceId);

  // Generate activation code
  const prefix = tier === 'monthly' ? 'M' : tier === 'yearly' ? 'Y' : 'T';
  const randomPart = generateRandomCode(6); // Generate 6 random alphanumeric chars
  const activationCode = `${prefix}-${randomPart.slice(0,3)}-${randomPart.slice(3,6)}`;

  // Get customer details
  const customerId = eventData.customer;
  const customerEmail = eventData.customer_email || '';

  // Calculate expiry date
  const currentPeriodEnd = eventData.lines.data[0]?.period?.end ||
                           (Date.now() / 1000) + (30 * 24 * 60 * 60); // Default 30 days
  const expiresAt = new Date(currentPeriodEnd * 1000).toISOString();

  return {
    activationCode,
    tier,
    subscriptionId,
    customerId,
    customerEmail,
    expiresAt,
    invoiceId: eventData.id,
  };
};

function determineTier(priceId) {
  // Replace with your actual Stripe price IDs
  const MONTHLY_PRICE_ID = 'price_1ShctRIDgcZhXc4UfDnbNf1s';
  const YEARLY_PRICE_ID = 'price_1Shcv9IDgcZhXc4UUAD2Qfz3';

  if (priceId === MONTHLY_PRICE_ID) return 'monthly';
  if (priceId === YEARLY_PRICE_ID) return 'yearly';
  return 'trial';
}

function generateRandomCode(length) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Exclude ambiguous chars (0,O,1,I)
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}
```

#### **Step 3: Activepieces Table - Insert Code Record**

- **Action:** Insert Row
- **Table Name:** `activation_codes`
- **Data:**
  ```json
  {
    "code": "{{codeStep.activationCode}}",
    "customerId": "{{codeStep.customerId}}",
    "subscriptionId": "{{codeStep.subscriptionId}}",
    "tier": "{{codeStep.tier}}",
    "status": "unused",
    "createdAt": "{{now}}",
    "expiresAt": "{{codeStep.expiresAt}}",
    "usedAt": null,
    "deviceId": null
  }
  ```

#### **Step 4: Stripe API - Update Invoice Metadata**

- **Action:** HTTP Request (POST)
- **URL:** `https://api.stripe.com/v1/invoices/{{codeStep.invoiceId}}`
- **Headers:**
  ```
  Authorization: Bearer {{env.STRIPE_SECRET_KEY}}
  Content-Type: application/x-www-form-urlencoded
  ```
- **Body:**
  ```
  metadata[activation_code]={{codeStep.activationCode}}&metadata[tier]={{codeStep.tier}}
  ```

#### **Step 5: Send Email with Activation Code**

- **Action:** Send Email (Gmail/SendGrid/etc.)
- **To:** `{{codeStep.customerEmail}}`
- **Subject:** `Your Activation Code - Everyday Christian`
- **HTML Body:**

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .code-box {
      background: #f5f5f5;
      padding: 20px;
      border-radius: 8px;
      text-align: center;
      margin: 20px 0;
      border: 2px solid #4CAF50;
    }
    .code {
      font-size: 32px;
      font-weight: bold;
      letter-spacing: 4px;
      color: #4CAF50;
      font-family: monospace;
    }
    .instructions {
      background: #e3f2fd;
      padding: 15px;
      border-radius: 8px;
      margin: 20px 0;
    }
  </style>
</head>
<body>
  <div class="container">
    <h2>✅ Subscription Activated!</h2>
    <p>Thank you for subscribing to Everyday Christian Premium.</p>

    <div class="code-box">
      <p style="margin: 0; font-size: 14px; color: #666;">Your Activation Code:</p>
      <p class="code">{{codeStep.activationCode}}</p>
    </div>

    <div class="instructions">
      <p><strong>To activate your subscription:</strong></p>
      <ol>
        <li>Open the Everyday Christian app</li>
        <li>Tap "Activate Premium" or go to Settings</li>
        <li>Enter the code above when prompted</li>
        <li>Enjoy 150 messages per month!</li>
      </ol>
    </div>

    <p style="color: #666; font-size: 12px;">
      💡 <strong>Save this email</strong> - you'll need the code to reinstall the app or activate on a new device.
    </p>

    <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">

    <p style="font-size: 12px; color: #999;">
      Questions? Reply to this email or contact support@everydaychristian.com
    </p>
  </div>
</body>
</html>
```

---

## Flow 2: Activation Code Validation

### **Trigger:** HTTP Webhook (API Endpoint)

### **Purpose:** Validate activation code and mark as used

### **Flow Steps:**

```
1. Catch HTTP Request (POST)
   ↓
2. Extract code and deviceId from request
   ↓
3. Look up code in Table
   ↓
4. Validate code (exists, unused, not expired)
   ↓
5. Mark code as used
   ↓
6. Return success/error response
```

### **Implementation:**

#### **Step 1: HTTP Webhook Trigger**
- **Type:** Catch Webhook
- **Create new webhook URL** (will be used as `ACTIVEPIECES_CODE_VALIDATION_URL`)
- **Expected Request:**
  ```json
  {
    "code": "M-ABC-123",
    "deviceId": "1234567890_9876543210"
  }
  ```

#### **Step 2: Code Step - Validate Activation Code**

```javascript
export const code = async (inputs) => {
  const { code, deviceId } = inputs.webhookData;

  if (!code || !deviceId) {
    return {
      valid: false,
      error: 'Missing code or deviceId'
    };
  }

  // Look up code in Activepieces Table
  const codeRecord = await activepiecesTable.findOne({
    code: code.toUpperCase().trim()
  });

  if (!codeRecord) {
    return {
      valid: false,
      error: 'Invalid activation code'
    };
  }

  // Check if already used
  if (codeRecord.status === 'used') {
    return {
      valid: false,
      error: 'Code already used on another device'
    };
  }

  // Check if expired
  const now = new Date();
  const expiresAt = new Date(codeRecord.expiresAt);
  if (now > expiresAt) {
    return {
      valid: false,
      error: 'Code has expired'
    };
  }

  // Mark as used
  await activepiecesTable.update(codeRecord.id, {
    status: 'used',
    usedAt: new Date().toISOString(),
    deviceId: deviceId
  });

  return {
    valid: true,
    tier: codeRecord.tier,
    subscriptionId: codeRecord.subscriptionId,
    customerId: codeRecord.customerId,
    expiresAt: codeRecord.expiresAt
  };
};
```

#### **Step 3: Return HTTP Response**

- **Action:** Return HTTP Response
- **Status Code:** 200
- **Headers:**
  ```json
  {
    "Content-Type": "application/json"
  }
  ```
- **Body:** `{{codeStep}}`

---

## Activepieces Table Schema

### **Table Name:** `activation_codes`

| Column | Type | Description |
|--------|------|-------------|
| id | Auto-generated | Primary key |
| code | Text | Activation code (M-ABC-123) |
| customerId | Text | Stripe customer ID |
| subscriptionId | Text | Stripe subscription ID |
| tier | Text | monthly, yearly, or trial |
| status | Text | unused, used, or deactivated |
| createdAt | DateTime | When code was generated |
| expiresAt | DateTime | Subscription end date |
| usedAt | DateTime | When code was activated (null if unused) |
| deviceId | Text | Device that activated code (null if unused) |

---

## Environment Variables

Add these to your `.env` file after creating the flows:

```bash
# Stripe webhook URL (Flow 1 - already configured)
ACTIVEPIECES_STRIPE_WEBHOOK_URL=https://cloud.activepieces.com/api/v1/webhooks/A8CaLMQg80F4S5NPLiXwp

# Code validation URL (Flow 2 - create this flow and add URL here)
ACTIVEPIECES_CODE_VALIDATION_URL=https://cloud.activepieces.com/api/v1/webhooks/YOUR_VALIDATION_WEBHOOK_ID
```

---

## Testing the Flows

### **Test Flow 1 (Code Generation):**

```bash
# Use Stripe CLI to trigger test webhook
stripe trigger invoice.payment_succeeded
```

**Expected Result:**
- Activation code generated (e.g., M-A7B-92K)
- Code stored in Activepieces Table
- Code added to Stripe invoice metadata
- Email sent with activation code

### **Test Flow 2 (Code Validation):**

```bash
# Test with curl
curl -X POST https://YOUR_VALIDATION_URL \
  -H "Content-Type: application/json" \
  -d '{
    "code": "M-A7B-92K",
    "deviceId": "test_device_123"
  }'
```

**Expected Response (Valid Code):**
```json
{
  "valid": true,
  "tier": "monthly",
  "subscriptionId": "sub_xxxxx",
  "customerId": "cus_xxxxx",
  "expiresAt": "2025-02-23T00:00:00Z"
}
```

**Expected Response (Invalid Code):**
```json
{
  "valid": false,
  "error": "Invalid activation code"
}
```

---

## Security Considerations

1. **One-Time Use:** Each code can only be used once (enforced by checking `status === 'used'`)
2. **Device Tracking:** Store `deviceId` to track which device activated the code
3. **Expiry Validation:** Codes expire with the subscription
4. **HTTPS Only:** All webhook URLs must use HTTPS
5. **Code Format Validation:** App validates code format before calling API
6. **Rate Limiting:** Consider adding rate limits to validation endpoint

---

## Troubleshooting

### **Issue: Code validation returns 404**
- **Cause:** `ACTIVEPIECES_CODE_VALIDATION_URL` not set in `.env`
- **Fix:** Create Flow 2 and add webhook URL to `.env`

### **Issue: Email not sent**
- **Cause:** Email action not configured in Flow 1
- **Fix:** Add email service (Gmail/SendGrid) and configure Step 5

### **Issue: Code already used**
- **Cause:** Attempting to activate same code twice
- **Fix:** Contact support to manually reset code status (for legitimate cases)

### **Issue: Code expired**
- **Cause:** Subscription period ended
- **Fix:** User needs to re-subscribe (new code will be generated)

---

## Next Steps

1. ✅ Create Flow 1 (Code Generation) in Activepieces
2. ✅ Create Flow 2 (Code Validation) in Activepieces
3. ✅ Create Activepieces Table (`activation_codes`)
4. ✅ Update `.env` with `ACTIVEPIECES_CODE_VALIDATION_URL`
5. ✅ Test both flows
6. ✅ Update paywall screen with purchase buttons
7. ✅ Test end-to-end user flow

---

## Support

For issues with activation codes:
- Check Activepieces flow logs for errors
- Verify Stripe webhook is firing correctly
- Ensure `.env` variables are set correctly
- Contact support@everydaychristian.com with transaction ID
