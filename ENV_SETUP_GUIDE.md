# 🔑 Environment Variables Setup Guide
**Everyday Christian App - API Keys & Configuration**

---

## Current Status ✅

**Development Environment:**
- ✅ `.env` file exists with GEMINI_API_KEY
- ✅ `.gitignore` properly excludes `.env` from version control
- ✅ `flutter_dotenv` package configured
- ✅ Environment variables load successfully at runtime
- ✅ API key is accessed securely via `dotenv.env['GEMINI_API_KEY']`

**Verification:**
```bash
# Check logs when app starts
flutter run -d "iPhone 16"
# Should see: ✅ Environment variables loaded successfully
```

---

## File Structure

```
everyday-christian/
├── .env                    # YOUR API KEY (never commit!)
├── .env.example            # Template for other developers
├── .gitignore              # Excludes .env from git
└── run_with_env.sh         # Script to run with env vars
```

---

## Development Setup

### 1. Verify .env File Exists

```bash
cd everyday-christian
cat .env
```

**Expected output:**
```
GEMINI_API_KEY=AIzaSy...your_key_here
```

### 2. Get Your Gemini API Key

**If you need a new key:**

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click **"Get API Key"**
4. Copy your key
5. Update `.env`:
   ```bash
   GEMINI_API_KEY=your_new_key_here
   ```

### 3. Verify Key is Working

```bash
# Run the app
flutter run -d "iPhone 16"

# Try sending a message in AI Chat
# If successful, the key is working!
```

---

## Production Deployment

### iOS Production (App Store)

**Option 1: Xcode Environment Variables (Recommended)**

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target
3. Go to **Build Settings** → **User-Defined**
4. Add: `GEMINI_API_KEY = your_production_key`
5. Update `Info.plist`:
   ```xml
   <key>GEMINI_API_KEY</key>
   <string>$(GEMINI_API_KEY)</string>
   ```

**Option 2: Bundle .env.production**

1. Create `.env.production`:
   ```bash
   GEMINI_API_KEY=your_production_key_here
   ```
2. Add to Xcode **Copy Bundle Resources**
3. Update `main.dart` to load `.env.production` in release mode:
   ```dart
   await dotenv.load(
     fileName: kReleaseMode ? ".env.production" : ".env"
   );
   ```

### Android Production (Google Play)

**Option 1: Gradle Properties**

1. Edit `android/gradle.properties`:
   ```properties
   GEMINI_API_KEY=your_production_key
   ```
2. Update `android/app/build.gradle`:
   ```gradle
   defaultConfig {
       ...
       buildConfigField "String", "GEMINI_API_KEY", "\"${GEMINI_API_KEY}\""
   }
   ```

**Option 2: Bundle .env.production**

Same as iOS Option 2 above.

---

## Security Best Practices

### ✅ DO:
- ✅ Keep `.env` in `.gitignore`
- ✅ Use different keys for dev/staging/production
- ✅ Rotate keys periodically (every 3-6 months)
- ✅ Set usage quotas in Google Cloud Console
- ✅ Monitor API usage for anomalies
- ✅ Use `.env.example` as template (no real keys)

### ❌ DON'T:
- ❌ Commit `.env` to git
- ❌ Share API keys in Slack/Discord
- ❌ Use production keys in development
- ❌ Hard-code keys in source code
- ❌ Include keys in screenshots or videos
- ❌ Use same key across multiple projects

---

## API Key Rotation

**When to rotate:**
- Key is accidentally exposed (git commit, screenshot, etc.)
- Team member leaves with access
- Quarterly security maintenance
- Suspicious API usage detected

**How to rotate:**

1. **Generate new key in Google AI Studio**
2. **Test new key in development:**
   ```bash
   # Update .env with new key
   GEMINI_API_KEY=new_key_here

   # Run app and test AI chat
   flutter run
   ```
3. **Update production:**
   - iOS: Update Xcode environment variable
   - Android: Update gradle.properties
   - Submit new build to App Store/Play Store
4. **Revoke old key** in Google Cloud Console (after new version is deployed)

---

## Troubleshooting

### "GEMINI_API_KEY not found in .env file"

**Cause:** Missing or empty .env file

**Fix:**
```bash
# Check if file exists
ls -la .env

# If missing, copy from example
cp .env.example .env

# Add your key
echo "GEMINI_API_KEY=your_key_here" > .env
```

### "Could not load .env file"

**Cause:** File not bundled with app

**Fix:**
1. Ensure `.env` is in project root (not in subdirectories)
2. For iOS: Check Xcode **Copy Bundle Resources**
3. For Android: File should be in `assets/` folder
4. Run `flutter clean && flutter pub get`

### "API key invalid" or "403 Forbidden"

**Causes:**
- Key expired or revoked
- API not enabled in Google Cloud
- Quota exceeded
- Key restrictions (IP/domain) blocking requests

**Fix:**
1. **Verify key in Google AI Studio:**
   - Go to [API Keys](https://makersuite.google.com/app/apikey)
   - Check key status
2. **Enable Gemini API:**
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Enable "Generative Language API"
3. **Check quota:**
   - View usage in Google Cloud Console
   - Increase quota if needed
4. **Remove restrictions:**
   - For mobile apps, API keys should have minimal restrictions
   - iOS bundle ID and Android package name restrictions are recommended

---

## Environment Variables Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `GEMINI_API_KEY` | ✅ Yes | None | Google Gemini API key for AI chat |

### Future Variables (when needed):

| Variable | Purpose |
|----------|---------|
| `SENTRY_DSN` | Error tracking (production) |
| `FIREBASE_API_KEY` | Firebase services |
| `ANALYTICS_ID` | Google Analytics tracking |
| `APP_ENV` | Environment (dev/staging/prod) |

---

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/build.yml
name: Build App

env:
  GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}

steps:
  - name: Create .env
    run: |
      echo "GEMINI_API_KEY=$GEMINI_API_KEY" > .env

  - name: Build
    run: flutter build ios --release
```

**Setup:**
1. Go to **GitHub repo → Settings → Secrets → Actions**
2. Add secret: `GEMINI_API_KEY`
3. Value: Your production API key

---

## Testing Different Keys

### Development Key (Current)
```bash
# .env
GEMINI_API_KEY=your_development_key_here
```

### Staging Key (Future)
```bash
# .env.staging
GEMINI_API_KEY=staging_key_here
```

### Production Key (Future)
```bash
# .env.production
GEMINI_API_KEY=production_key_here
```

**Load based on environment:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final envFile = kDebugMode ? '.env' : '.env.production';
  await dotenv.load(fileName: envFile);

  runApp(MyApp());
}
```

---

## Monitoring & Quotas

### Check API Usage

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Navigate to **APIs & Services → Dashboard**
3. Select **Generative Language API**
4. View **Metrics** tab

### Set Quotas

**Free Tier Limits (Gemini 1.5 Flash):**
- 15 requests per minute (RPM)
- 1 million tokens per minute (TPM)
- 1,500 requests per day (RPD)

**Production Tier (Gemini 1.5 Pro):**
- Higher limits with billing enabled
- Pay-as-you-go pricing
- Set budget alerts

---

## Quick Reference

**Check current setup:**
```bash
# Verify .env exists and has key
cat .env | grep GEMINI_API_KEY

# Check .gitignore includes .env
grep "\.env" .gitignore

# Test loading in app
flutter run | grep "Environment variables"
```

**Common commands:**
```bash
# Copy example to create .env
cp .env.example .env

# Edit .env
nano .env

# Verify key format (starts with AIza)
cat .env | grep -o "AIza[A-Za-z0-9_-]*"

# Clean and rebuild
flutter clean && flutter pub get && flutter run
```

---

## Checklist for App Store Submission

- [ ] Production API key generated
- [ ] `.env` is in `.gitignore` (not committed)
- [ ] Production key configured in Xcode/Gradle
- [ ] API quota is sufficient for launch
- [ ] Monitoring/alerts set up in Google Cloud
- [ ] Key rotation schedule documented
- [ ] Team knows how to rotate keys if needed
- [ ] Backup plan if key is compromised

---

## Support & Resources

**Google AI Studio:**
- [Get API Key](https://makersuite.google.com/app/apikey)
- [Documentation](https://ai.google.dev/docs)
- [Pricing](https://ai.google.dev/pricing)

**Flutter Dotenv:**
- [Package Documentation](https://pub.dev/packages/flutter_dotenv)
- [GitHub](https://github.com/java-james/flutter_dotenv)

**Google Cloud Console:**
- [Console Home](https://console.cloud.google.com)
- [API Dashboard](https://console.cloud.google.com/apis/dashboard)
- [Billing](https://console.cloud.google.com/billing)

---

**Last Updated:** October 16, 2025
**Status:** ✅ PRODUCTION READY (with production key setup)
