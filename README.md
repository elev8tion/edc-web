# 🙏 Everyday Christian

**A faith-centered mobile app providing personalized biblical guidance through AI-powered conversations.**

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)]()

---

## 📱 About

Everyday Christian is a pastoral counseling app that provides:

- 🤖 **AI-powered pastoral guidance** using Google Gemini API
- 📖 **31,103 Bible verses** from the World English Bible (WEB) translation
- 🛡️ **Crisis detection & intervention** (suicide, self-harm, abuse)
- 🎨 **Beautiful glassmorphic UI** with modern Flutter design
- 🔒 **Local data storage** - Bible verses and user data stored on device

---

## ✨ Features

### Core Functionality
- **Biblical AI Chat (Premium - ~$35/year):** -150 messages/month with Enhanced Pastoral Model, Trained in Real World Experience
- **Daily Verse:** Smart verse selection based on user preferences
- **Devotionals:** Structured reading plans and devotional content
- **Prayer Journal:** Track prayers with categories and streaks
- **Verse Library:** Full-text search across 31,103 verses
- **Reading Plans:** Guided Bible reading with progress tracking

### Safeguards
- ✅ Crisis detection (suicide, self-harm, abuse keywords)
- ✅ Security lockout (3 attempts = 30-min lockout, bypass with device PIN/biometric)
- ✅ Content filtering (prosperity gospel, hate speech)
- ✅ Professional referrals (therapy, hotlines, legal)
- ✅ Legal disclaimers (not professional counseling)

### Technical Features
- 🚀 **Fast AI responses** powered by Gemini API
- 💾 **SQLite database** (26 MB, 31,103 verses)
- 🔐 **Biometric authentication** (Face ID, Touch ID)
- 📊 **Progress tracking** (reading streaks, prayer stats)
- 🎨 **Beautiful glassmorphic UI** with modern design language
- 📴 **Always offline-first** (only AI chat requires internet)

---

## 💳 Pricing

### Free Version
- ✅ Daily verse, Bible search, prayer journal, reading plans, devotionals
- ✅ All features except AI pastoral chat

### Premium - ~$35/Year
- ✅ **3-day free trial** (15 AI messages total - use anytime)
- ✅ **AI pastoral chat** - Enhanced Pastoral Model, Trained in Real World Experience
- ✅ **150 messages/month** after trial
- ✅ **Small Payment** - 1 Year access for just $35/year
- ✅ Cancel anytime and will not renew

**Cost per message:** $0.0003
**Profit margin:** 98.5%

---

## 🏗️ Architecture

### Tech Stack
- **Frontend:** Flutter 3.0+ (Dart 3.0+)
- **State Management:** Riverpod 2.4.9
- **Database:** SQLite (sqflite 2.3.0)
- **AI/ML:** Google Generative AI (Gemini 2.0 Flash)
- **Storage:** SharedPreferences + FlutterSecureStorage

### AI System
- **AI Model:** Google Gemini 2.0 Flash API
- **Training Context:** 19,750 pastoral guidance examples for RAG (Retrieval-Augmented Generation)
- **Theme Detection:** Keyword-based classification (75 theme categories)
- **Bible Database:** 31,103 verses (WEB translation)
- **Response Generation:** Contextual responses with relevant Bible verses

### Project Structure
```
lib/
├── core/
│   ├── database/        # SQLite helpers, migrations, models
│   ├── services/        # Business logic (AppLockoutService, 18+ services)
│   ├── providers/       # Riverpod state management
│   └── widgets/         # Reusable UI components
├── features/
│   ├── auth/            # Authentication & biometrics
│   └── chat/            # AI conversation interface
├── screens/             # 14 main screens
├── services/            # AI services (LSTM, theme classifier)
└── theme/               # App theming & styles
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.0+ ([Install Flutter](https://docs.flutter.dev/get-started/install))
- Xcode 14+ (for iOS) or Android Studio (for Android)
- macOS (for iOS builds)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/elev8tion/edc.git
   cd edc
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run code generation:**
   ```bash
   dart run build_runner build
   ```

4. **Run the app:**
   ```bash
   # iOS Simulator
   flutter run -d ios

   # Android Emulator
   flutter run -d android

   # macOS Desktop
   flutter run -d macos
   ```

---

## 🧪 Testing

### Run Tests
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Test Coverage
- **50+ test files** (unit, widget, integration)
- Comprehensive service tests (database, AI, auth, safeguards)
- AppLockoutService tests (18 tests covering OS authentication)
- Mock implementations for external dependencies

---

## 📦 Building for Production

### iOS

1. **Configure signing:**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select your team and provisioning profile

2. **Build release:**
   ```bash
   flutter build ipa --release
   ```

3. **Upload to TestFlight:**
   ```bash
   xcrun altool --upload-app --file build/ios/ipa/*.ipa
   ```

### Android

1. **Generate signing key:**
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Build release:**
   ```bash
   flutter build appbundle --release
   ```

3. **Upload to Play Console:**
   - Navigate to [Play Console](https://play.google.com/console)
   - Upload `build/app/outputs/bundle/release/app-release.aab`

---

## 📊 Project Stats

- **Lines of Code:** 44,042 (lib/)
- **Dart Files:** 140 (lib) + 49 (test)
- **Development Time:** 8 days (Sept 30 - Oct 8, 2025)
- **Commits:** 50+
- **Training Examples:** 19,750
- **Bible Verses:** 31,103
- **Supported Themes:** 75

---

## 🛡️ Privacy & Security

### Privacy-First Design

**Unlike other religious apps, we don't monetize your spiritual journey.**

In recent years, major faith apps have faced scandals:
- Pray.com suffered data breaches exposing millions of users
- Muslim Pro sold user location data to military contractors
- Popular apps mine prayers as "business assets" for data brokers

**Everyday Christian is different:**

### What We DON'T Collect
- ❌ **No user accounts** - download and use immediately, no sign-up required
- ❌ **No authentication data** - we never see your device PIN or biometric data
- ❌ **No personal information** - no emails, names, phone numbers, or profiles
- ❌ **No location tracking** - we don't track where you pray or worship
- ❌ **No user analytics** - we don't monitor your behavior or app usage
- ❌ **No data monetization** - your prayers are never sold to data brokers
- ❌ **No social features** - no sharing that could expose your spiritual struggles

### What Stays On Your Device
- ✅ **All Bible verses** - 31,103 verses stored locally (works offline)
- ✅ **All prayers** - your prayer journal stays on your device
- ✅ **All favorites & bookmarks** - stored in local SQLite database
- ✅ **All settings & preferences** - stored locally with SharedPreferences
- ✅ **All reading history** - never leaves your phone

### Third-Party Services
- ⚠️ **AI Chat uses Google Gemini API** - when you use the AI chat feature, your messages are sent to Google's servers for AI processing. Google may collect: message content, IP address, and timestamps. However, we do NOT send any user identifier, account info, or link messages to your identity. Each request is anonymous from your perspective.

### Security Features
- 🔐 **OS-native authentication** - Uses your device's PIN, Face ID, or Touch ID
- 🚫 **No user accounts** - No passwords to remember or data to breach
- 🔓 **Privacy-first lockout** - After 3 wrong attempts, use device auth to unlock (no account bans)
- 🔒 **Secure local storage** - FlutterSecureStorage for sensitive data
- 🛡️ **Crisis detection** - Built-in safeguards for mental health emergencies
- ⚠️ **Content filtering** - Automatic detection of harmful theology

### Your Data, Your Control
- **No cloud sync** means no data breach risk from our servers (we don't have any)
- **No account** means no password to leak or credentials to steal
- **Uninstall = complete deletion** - all data removed when you delete the app

---

## ⚖️ Legal

### Disclaimer
**This app provides pastoral guidance, NOT professional counseling.**

- Not a substitute for licensed therapy
- Not medical or legal advice
- AI responses may contain errors
- Crisis situations require professional help

**Crisis Resources:**
- **Suicide & Crisis Lifeline:** 988 (call or text)
- **Crisis Text Line:** Text HOME to 741741
- **RAINN (Sexual Assault):** 800-656-4673

### License
Proprietary - All rights reserved

**Bible Content:**
- World English Bible (WEB) - Public Domain
- Original source: [eBible.org](https://ebible.org)

---

## 🙏 Acknowledgments

- **Bible Translation:** World English Bible (WEB) from eBible.org
- **Flutter Team:** Excellent cross-platform framework
- **Riverpod:** State management
- **Claude Code:** Development assistance

---

## 📞 Contact

- **Developer:** elev8tion
- **GitHub:** [elev8tion/edc](https://github.com/elev8tion/edc)
- **Issues:** [GitHub Issues](https://github.com/elev8tion/edc/issues)

---

## 🔄 Version History

See [CHANGELOG.md](CHANGELOG.md) for version history.

---

**Built with ❤️ for the body of Christ**

*"In nothing be anxious, but in everything, by prayer and petition with thanksgiving, let your requests be made known to God."* - Philippians 4:6 (WEB)
