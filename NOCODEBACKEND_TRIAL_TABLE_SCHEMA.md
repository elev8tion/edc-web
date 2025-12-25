# NoCodeBackend - Trial Tracking Table Schema

## Create New Table Instance

### Table Name
**Instance Name**: `36905_trial_tracking` (or similar, use your naming convention)

### Purpose
Dedicated table for tracking PWA trial usage to prevent abuse using IP + device fingerprint hybrid approach.

---

## Table Schema

### Fields Configuration

| Field Name | Type | Description | Required | Indexed | Default Value |
|------------|------|-------------|----------|---------|---------------|
| `id` | Auto-increment | Primary key | Yes | Yes | (auto) |
| `ip_hash` | Text | SHA-256 hash of IP address | Yes | Yes | - |
| `fingerprint_hash` | Text | SHA-256 hash of device fingerprint | Yes | Yes | - |
| `trial_started_at` | DateTime | When trial was activated | Yes | Yes | (current timestamp) |
| `trial_expires_at` | DateTime | When trial expires (3 days from start) | Yes | Yes | - |
| `status` | Text | "active", "expired" | Yes | Yes | "active" |
| `user_agent` | Text | Browser user agent (for debugging) | No | No | - |
| `timezone` | Text | User timezone (for debugging) | No | No | - |
| `messages_used` | Integer | Messages used during trial | No | No | 0 |

### Indexes

**Important**: Ensure these fields are indexed for fast lookups:
- `ip_hash` (Primary lookup field)
- `fingerprint_hash` (Primary lookup field)
- `trial_started_at` (For cleanup queries)
- `status` (For filtering active vs expired)

---

## Step-by-Step Creation in NoCodeBackend

### 1. Log in to NoCodeBackend
- Go to https://nocodebackend.com
- Log in to your account

### 2. Create New Instance
- Click "Instances" in sidebar
- Click "Create New Instance"
- **Name**: `trial_tracking` (or `36905_trial_tracking` to match your convention)
- **Description**: "PWA trial abuse prevention tracking"
- Click "Create"

### 3. Add Fields One by One

**Field 1: id** (Auto-generated)
```
Name: id
Type: Auto-increment
Required: Yes
Indexed: Yes
(This is usually created automatically as primary key)
```

**Field 2: ip_hash**
```
Name: ip_hash
Type: Text
Max Length: 64
Required: Yes
Indexed: Yes ⚠️ IMPORTANT
Default: (leave empty)
```

**Field 3: fingerprint_hash**
```
Name: fingerprint_hash
Type: Text
Max Length: 64
Required: Yes
Indexed: Yes ⚠️ IMPORTANT
Default: (leave empty)
```

**Field 4: trial_started_at**
```
Name: trial_started_at
Type: DateTime
Required: Yes
Indexed: Yes
Default: (current timestamp) or leave empty
```

**Field 5: trial_expires_at**
```
Name: trial_expires_at
Type: DateTime
Required: Yes
Indexed: Yes
Default: (leave empty)
```

**Field 6: status**
```
Name: status
Type: Text
Max Length: 20
Required: Yes
Indexed: Yes
Default: active
```

**Field 7: user_agent** (Optional, for debugging)
```
Name: user_agent
Type: Text
Max Length: 500
Required: No
Indexed: No
Default: (leave empty)
```

**Field 8: timezone** (Optional, for debugging)
```
Name: timezone
Type: Text
Max Length: 50
Required: No
Indexed: No
Default: (leave empty)
```

**Field 9: messages_used** (Optional, for analytics)
```
Name: messages_used
Type: Integer
Required: No
Indexed: No
Default: 0
```

### 4. Save Schema
- Click "Save Schema" or "Create Table"
- Wait for table creation to complete

### 5. Verify Table
- Go to "Data" tab
- Click "Add Record" to verify all fields appear
- You should see all 9 fields

### 6. Get API Details
- Go to "API" tab
- Copy the API URL (should look like: `https://api.nocodebackend.com/api/INSTANCE_ID`)
- Copy your API key
- Update Cloudflare Worker configuration with these values

---

## Sample Data Structure

Example record after a trial is created:

```json
{
  "id": 1,
  "ip_hash": "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8",
  "fingerprint_hash": "2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae",
  "trial_started_at": "2025-12-24T12:00:00.000Z",
  "trial_expires_at": "2025-12-27T12:00:00.000Z",
  "status": "active",
  "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)...",
  "timezone": "America/Los_Angeles",
  "messages_used": 0
}
```

---

## API Usage Examples

### Query by IP Hash
```bash
curl -X GET "https://api.nocodebackend.com/api/YOUR_INSTANCE_ID?ip_hash=5e8848..." \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Query by Fingerprint Hash
```bash
curl -X GET "https://api.nocodebackend.com/api/YOUR_INSTANCE_ID?fingerprint_hash=2c26b4..." \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Create Trial Record
```bash
curl -X POST "https://api.nocodebackend.com/api/YOUR_INSTANCE_ID" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "ip_hash": "5e8848...",
    "fingerprint_hash": "2c26b4...",
    "trial_started_at": "2025-12-24T12:00:00.000Z",
    "trial_expires_at": "2025-12-27T12:00:00.000Z",
    "status": "active",
    "user_agent": "Mozilla/5.0...",
    "timezone": "America/Los_Angeles",
    "messages_used": 0
  }'
```

### Update Messages Used
```bash
curl -X PATCH "https://api.nocodebackend.com/api/YOUR_INSTANCE_ID/RECORD_ID" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "messages_used": 5
  }'
```

---

## Data Cleanup (Recommended)

To keep table size manageable, periodically delete old expired trials:

### Manual Cleanup
1. Go to NoCodeBackend instance
2. Filter by: `status = "expired"` AND `trial_expires_at < 90 days ago`
3. Select all → Delete

### Automated Cleanup (Future Enhancement)
Create a Cloudflare Worker scheduled job to delete trials older than 90 days:

```javascript
// In Cloudflare Worker (future)
addEventListener('scheduled', event => {
  event.waitUntil(cleanupExpiredTrials());
});

async function cleanupExpiredTrials() {
  const ninetyDaysAgo = new Date();
  ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);

  // Query and delete old records
  // Implementation depends on NoCodeBackend's batch delete API
}
```

---

## Privacy & GDPR Compliance

### Data Stored
- ✅ IP hash (SHA-256) - NOT raw IP address
- ✅ Fingerprint hash (SHA-256) - NOT raw fingerprint
- ✅ User agent - Common browser string (no PII)
- ✅ Timezone - General location (no GPS coordinates)

### User Rights
- **Right to erasure**: Delete record by ID
- **Right to access**: Not applicable (no PII stored)
- **Right to portability**: Not applicable (hashed data)

### Data Retention
- Recommended: 90 days
- After 90 days: Automatically delete expired trials
- User can request deletion anytime

---

## Cost Estimate

NoCodeBackend Free Tier:
- ✅ Up to 10,000 records/month
- ✅ Up to 100,000 API calls/month

Expected usage for trial tracking:
- **Records created**: ~100-500/month (new trials)
- **API calls**: ~1,000-5,000/month (validation checks)

**Cost**: Free (well within limits)

---

## Security Considerations

### API Key Security
- ✅ API key stored in Cloudflare Worker environment variables
- ✅ NOT exposed to client-side code
- ✅ Only Cloudflare Worker can access NoCodeBackend

### Rate Limiting
Cloudflare Workers automatically rate limit:
- Free tier: 100,000 requests/day
- No additional rate limiting needed

### SQL Injection Prevention
NoCodeBackend uses parameterized queries:
- ✅ All inputs automatically sanitized
- ✅ No manual SQL escaping needed

---

## Troubleshooting

### Issue: "Field not indexed" warning
**Solution**: Re-create field with "Indexed: Yes" checkbox checked

### Issue: API returns 400 "Invalid field"
**Solution**: Check field names match exactly (case-sensitive)

### Issue: Duplicate records being created
**Solution**: NoCodeBackend doesn't enforce unique constraints - handle in Worker logic

### Issue: Query returns too many results
**Solution**: Add date filter to limit results:
```
?ip_hash=xxx&trial_started_at_gte=2025-12-01
```

---

## Next Steps After Table Creation

1. **Get instance details**:
   - Copy API URL
   - Copy API key

2. **Update Cloudflare Worker** (I'll do this next):
   - Replace `36905_activation_codes` with new instance
   - Update API URL in wrangler.toml

3. **Test table**:
   - Manually create test record
   - Query by ip_hash
   - Query by fingerprint_hash
   - Verify responses

4. **Deploy Worker**:
   - Deploy with new configuration
   - Test trial validation end-to-end

---

**Ready to create the table?** Let me know the instance name/ID once you've created it, and I'll update the Cloudflare Worker configuration! 🚀
