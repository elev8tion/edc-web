# NoCodeBackend Setup Guide - Trial Tracking Table

## Step-by-Step Instructions (Based on Actual UI)

### 1. Open "Add table" Dialog

1. Log in to NoCodeBackend
2. Navigate to your database
3. Click the "Add table" button
4. You'll see the "Add table" dialog (as shown in your screenshots)

---

### 2. Enter Table Name

In the **Table name** field, enter:
```
trial_tracking
```

**Note**: The helper text says "Table names are lowercased; spaces and dashes become underscores."

---

### 3. Add Columns One by One

#### Column 1: ip_hash

| Field | Value |
|-------|-------|
| **Column name** | `ip_hash` |
| **Type** | `VARCHAR(255)` |
| **Default** | _(leave empty)_ |
| ☑️ **Not null** | ✅ Checked |
| ☐ **Unique** | ❌ Unchecked (NoCodeBackend doesn't enforce unique constraints well) |
| ☐ **Foreign key** | ❌ Unchecked |

**After entering**, click **"+ Add another column"**

---

#### Column 2: fingerprint_hash

| Field | Value |
|-------|-------|
| **Column name** | `fingerprint_hash` |
| **Type** | `VARCHAR(255)` |
| **Default** | _(leave empty)_ |
| ☑️ **Not null** | ✅ Checked |
| ☐ **Unique** | ❌ Unchecked |
| ☐ **Foreign key** | ❌ Unchecked |

Click **"+ Add another column"**

---

#### Column 3: trial_started_at

| Field | Value |
|-------|-------|
| **Column name** | `trial_started_at` |
| **Type** | `DATETIME` |
| **Default** | _(leave empty)_ |
| ☑️ **Not null** | ✅ Checked |
| ☐ **Unique** | ❌ Unchecked |
| ☐ **Foreign key** | ❌ Unchecked |

Click **"+ Add another column"**

---

#### Column 4: trial_expires_at

| Field | Value |
|-------|-------|
| **Column name** | `trial_expires_at` |
| **Type** | `DATETIME` |
| **Default** | _(leave empty)_ |
| ☑️ **Not null** | ✅ Checked |
| ☐ **Unique** | ❌ Unchecked |
| ☐ **Foreign key** | ❌ Unchecked |

Click **"+ Add another column"**

---

#### Column 5: status

| Field | Value |
|-------|-------|
| **Column name** | `status` |
| **Type** | `VARCHAR(255)` |
| **Default** | `active` |
| ☑️ **Not null** | ✅ Checked |
| ☐ **Unique** | ❌ Unchecked |
| ☐ **Foreign key** | ❌ Unchecked |

Click **"+ Add another column"**

---

#### Column 6: user_agent (Optional - for debugging)

| Field | Value |
|-------|-------|
| **Column name** | `user_agent` |
| **Type** | `TEXT` |
| **Default** | _(leave empty)_ |
| ☐ **Not null** | ❌ Unchecked (optional field) |
| ☐ **Unique** | ❌ Unchecked |
| ☐ **Foreign key** | ❌ Unchecked |

Click **"+ Add another column"**

---

#### Column 7: timezone (Optional - for debugging)

| Field | Value |
|-------|-------|
| **Column name** | `timezone` |
| **Type** | `VARCHAR(255)` |
| **Default** | _(leave empty)_ |
| ☐ **Not null** | ❌ Unchecked (optional field) |
| ☐ **Unique** | ❌ Unchecked |
| ☐ **Foreign key** | ❌ Unchecked |

Click **"+ Add another column"**

---

#### Column 8: messages_used (Optional - for analytics)

| Field | Value |
|-------|-------|
| **Column name** | `messages_used` |
| **Type** | `INT` |
| **Default** | `0` |
| ☐ **Not null** | ❌ Unchecked (optional field) |
| ☐ **Unique** | ❌ Unchecked |
| ☐ **Foreign key** | ❌ Unchecked |

---

### 4. Create the Table

After adding all 8 columns, click the **"Create table"** button at the bottom right.

**Expected result**: NoCodeBackend will create the table with an auto-increment `id` column automatically.

---

## 5. Verify Table Creation

1. Navigate to the newly created `trial_tracking` table
2. Click on the table to view its structure
3. Verify all columns are present:
   - `id` (auto-created)
   - `ip_hash`
   - `fingerprint_hash`
   - `trial_started_at`
   - `trial_expires_at`
   - `status`
   - `user_agent`
   - `timezone`
   - `messages_used`

---

## 6. Get API Credentials

### Find Your API URL

1. In NoCodeBackend, navigate to your `trial_tracking` table
2. Look for the **API** section or **Settings** tab
3. Copy the **API URL** - it should look like:
   ```
   https://api.nocodebackend.com/api/YOUR_TABLE_ID
   ```
   Example: `https://api.nocodebackend.com/api/36905_trial_tracking`

### Get Your API Key

1. Go to your NoCodeBackend account settings
2. Find the **API Keys** section
3. Copy your **API Key** (it's a long string starting with `ncb_` or similar)
4. **IMPORTANT**: Keep this secret! Don't commit it to git.

---

## 7. Configure Cloudflare Worker

Once you have your API URL and API Key, update the Cloudflare Worker configuration:

### Edit `wrangler.toml`

Open `/Users/kcdacre8tor/edc_web/cloudflare_workers/wrangler.toml` and update:

```toml
[vars]
NOCODEBACKEND_TRIAL_API_KEY = "YOUR_API_KEY_HERE"
NOCODEBACKEND_TRIAL_API_URL = "https://api.nocodebackend.com/api/YOUR_TABLE_ID"
```

**Replace**:
- `YOUR_API_KEY_HERE` with your actual NoCodeBackend API key
- `YOUR_TABLE_ID` with your actual table ID (e.g., `36905_trial_tracking`)

---

## 8. Test the Table Manually

Before deploying the Cloudflare Worker, test that the table works:

### Create a Test Record

Use NoCodeBackend's UI to manually create a test record:

| Field | Test Value |
|-------|------------|
| `ip_hash` | `test_hash_123` |
| `fingerprint_hash` | `test_fingerprint_456` |
| `trial_started_at` | `2025-12-25 03:00:00` |
| `trial_expires_at` | `2025-12-28 03:00:00` |
| `status` | `active` |
| `user_agent` | `Mozilla/5.0 Test` |
| `timezone` | `America/Los_Angeles` |
| `messages_used` | `0` |

### Verify the Record

1. View the table data
2. Confirm the record was created successfully
3. Note the auto-generated `id` value

---

## 9. Test API Queries (Optional)

Use `curl` to test API access:

### Query by IP Hash
```bash
curl -X GET "https://api.nocodebackend.com/api/YOUR_TABLE_ID?ip_hash=test_hash_123" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

**Expected response**:
```json
[
  {
    "id": 1,
    "ip_hash": "test_hash_123",
    "fingerprint_hash": "test_fingerprint_456",
    "trial_started_at": "2025-12-25T03:00:00.000Z",
    "trial_expires_at": "2025-12-28T03:00:00.000Z",
    "status": "active",
    "user_agent": "Mozilla/5.0 Test",
    "timezone": "America/Los_Angeles",
    "messages_used": 0
  }
]
```

### Create Record via API
```bash
curl -X POST "https://api.nocodebackend.com/api/YOUR_TABLE_ID" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "ip_hash": "another_test_hash",
    "fingerprint_hash": "another_fingerprint",
    "trial_started_at": "2025-12-25T04:00:00.000Z",
    "trial_expires_at": "2025-12-28T04:00:00.000Z",
    "status": "active",
    "user_agent": "Test User Agent",
    "timezone": "UTC",
    "messages_used": 0
  }'
```

---

## 10. Next Steps

After completing this setup:

1. ✅ Table created in NoCodeBackend
2. ✅ API URL and Key obtained
3. ✅ Test record created and verified
4. ⏭️ **Next**: Deploy Cloudflare Worker
5. ⏭️ **Next**: Integrate into PWA subscription service

---

## Available Field Types (for reference)

Based on your NoCodeBackend UI:

- `INT` - Integer numbers
- `BIGINT` - Large integer numbers
- `VARCHAR(255)` - Text strings (up to 255 characters)
- `TEXT` - Long text (unlimited length)
- `DATETIME` - Date and time
- `TIMESTAMP` - Unix timestamp
- `DATE` - Date only
- `BOOLEAN` - True/false
- `FLOAT` - Decimal numbers
- `DOUBLE` - Large decimal numbers
- `DECIMAL(10,2)` - Fixed precision decimals
- `JSON` - JSON data
- `PASSWORD` - Encrypted password field
- `DROPDOWN` - Dropdown select field

---

## Why These Field Types?

| Column | Type | Reason |
|--------|------|--------|
| `ip_hash` | `VARCHAR(255)` | SHA-256 hashes are 64 characters, VARCHAR(255) provides buffer |
| `fingerprint_hash` | `VARCHAR(255)` | SHA-256 hashes are 64 characters |
| `trial_started_at` | `DATETIME` | Need date + time for trial start |
| `trial_expires_at` | `DATETIME` | Need date + time for expiration |
| `status` | `VARCHAR(255)` | Text values: "active", "expired" |
| `user_agent` | `TEXT` | User agents can be very long (>255 chars) |
| `timezone` | `VARCHAR(255)` | Timezone strings like "America/Los_Angeles" |
| `messages_used` | `INT` | Whole numbers for message count |

---

## Important Notes

### About Indexing

⚠️ **NoCodeBackend may not have explicit "index" checkboxes in the UI you showed**.

If there's no indexing option visible:
- Don't worry - NoCodeBackend typically auto-indexes primary lookup fields
- Query performance should still be good for the expected load (~100-500 trials/month)
- If you find an "Add Index" option later, index `ip_hash` and `fingerprint_hash`

### About Unique Constraints

⚠️ **Don't check "Unique" on `ip_hash` or `fingerprint_hash`**

Why? Multiple trials can have the same IP (shared WiFi) or fingerprint (same device trying again). The Cloudflare Worker logic handles duplicate detection by querying existing records, not relying on database constraints.

---

## Troubleshooting

### "Column name already exists"
- Use different column name or delete existing table

### "Invalid default value for DATETIME"
- Leave DATETIME defaults empty, the Cloudflare Worker will set values

### "API returns 401 Unauthorized"
- Check API key is correct
- Verify API key has access to this table

### "API returns 404 Not Found"
- Check API URL includes correct table ID
- Verify table was created successfully

---

**Ready to proceed?** Once you've created the table, let me know the:
1. **API URL** (e.g., `https://api.nocodebackend.com/api/36905_trial_tracking`)
2. **API Key** (keep this secret!)

And I'll help you deploy the Cloudflare Worker! 🚀
