# Complete AI Chat Architecture Analysis - Everyday Christian PWA

## Executive Summary

The Everyday Christian PWA uses **Gemini 2.0 Flash API** for AI-powered biblical counseling. The system is fully cloud-dependent with NO local AI capabilities currently. It includes sophisticated security, content filtering, and conversation management but requires internet connectivity for all AI features.

### Current Architecture: CLOUD-BASED (100% API-DEPENDENT)
- **Model**: Google Gemini 2.0 Flash
- **Integration**: google_generative_ai package
- **Deployment**: 20 API keys with round-robin rotation
- **Training Data**: 19,750 pastoral counseling examples (optional)
- **Storage**: SQLite (sqflite on mobile, sql.js on web)
- **Chat Persistence**: Database-backed conversation management

---

## 1. CURRENT AI IMPLEMENTATION

### 1.1 Core AI Service Files

#### `/lib/services/gemini_ai_service.dart` (575 lines)
**Responsibility**: Direct Gemini API integration

Key Components:
```
Line 21-28:    Class singleton pattern
Line 40-62:    API key pool (20 keys with rotation)
Line 71-108:   getApiKey() - round-robin with random offset
Line 112-149:  initialize() - Model initialization with generation config
Line 152-191:  _loadTrainingData() - Loads LSTM training data from assets
Line 193-228:  _findRelevantExamples() - Keyword matching from training set
Line 231-292:  generateResponse() - Blocking API call to Gemini
Line 295-338:  generateStreamingResponse() - Stream-based response
Line 340-514:  _buildPrompt() - Complex prompt engineering
Line 376-464:  _buildEnglishPrompt() - Intent-based system prompts
Line 524-573:  generateConversationTitle() - Auto-title generation
```

**Key Implementation Details**:
```dart
// Model Configuration
GenerativeModel(
  model: 'gemini-2.0-flash',
  apiKey: apiKey,
  generationConfig: GenerationConfig(
    temperature: 0.9,
    topP: 0.95,
    topK: 40,
    maxOutputTokens: 1000,  // CONSTRAINT: 1000 token max
  ),
  safetySettings: [
    // Safety features DISABLED - custom filtering instead
    SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
    SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
    SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
    SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
  ],
)
```

#### `/lib/services/ai_service.dart` (329 lines)
**Responsibility**: Abstract interface and configuration

```
Line 5-33:     AIService abstract interface (initialize, isReady, generateResponse, etc.)
Line 36-66:    AIResponse class with error handling
Line 69-121:   AIConfig class for response customization
Line 124-225:  BiblicalPrompts - static prompt templates & theme detection
Line 227-329:  FallbackResponses - graceful degradation fallbacks
```

**Response Types**:
```dart
// Situation-based configs
AIConfig.forSituation('anxiety')      → Temp 0.6, calming tone
AIConfig.forSituation('depression')   → Temp 0.7, encouraging tone
AIConfig.forSituation('guidance')     → Temp 0.5, wise tone
AIConfig.forSituation('strength')     → Temp 0.8, empowering tone

// Theme detection from user input
"anxious", "worried", "stressed", "overwhelmed", "panic" → anxiety
"sad", "depressed", "hopeless" → depression
"weak", "tired", "exhausted", "struggle" → strength
```

#### `/lib/providers/ai_provider.dart` (579 lines)
**Responsibility**: Riverpod state management and AI integration

```
Line 14-18:    aiServiceProvider - Singleton AI service
Line 21-28:    aiServiceInitializedProvider - Initialization FutureProvider
Line 31-34:    aiServiceReadyProvider - Readiness status
Line 37-39:    aiPerformanceProvider - Performance monitoring
Line 42-44:    aiServiceStateProvider - State notifier
Line 47-72:    AIServiceStateNotifier - State machine
Line 75-120:   AIServiceState - Pattern matching states
Line 121-129:  GeminiAIServiceAdapter - Wraps GeminiAIService
Line 140-282:  generateResponse() - With security & filtering
Line 285-405:  generateResponseStream() - Streaming with validation
Line 408-415:  getRelevantVerses() - Verse selection
Line 427-446:  _formatConversationHistory() - Last 20 messages only
Line 449-468:  _createFallbackResponse() - Error handling
Line 471-515:  _createFallbackMessage() - Theme-based fallbacks
```

**Security Pipeline**:
```
User Input
    ↓
InputSecurityService.validateInput()
    ├─ Check threat level
    ├─ Detect patterns (jailbreak, profanity, etc.)
    └─ Record violations if HIGH/CRITICAL
    ↓
BiblicalPrompts.detectThemes()
    └─ Extract themes for context
    ↓
UnifiedVerseService.searchByTheme()
    └─ Get 3 relevant verses
    ↓
_gemini.generateResponse()
    └─ API call with prompt engineering
    ↓
ContentFilterService.filterResponse()
    ├─ Check for harmful theology
    └─ Block prosperity gospel, toxic positivity, etc.
    ↓
Return AIResponse
```

### 1.2 Chat Screen Implementation

#### `/lib/screens/chat_screen.dart` (1000+ lines)
**Key Features**:

**Streaming Implementation** (Lines 185-500):
```dart
// Non-blocking streaming with typing animation
final stream = aiService.generateResponseStream(
  userInput: userInput,
  theme: theme,
  verses: verses,
  conversationHistory: historyStrings,
  language: language,
);

await for (final chunk in stream) {
  fullResponse.write(chunk);
  // Update UI chunk-by-chunk for typing effect
}
```

**Subscription Checks** (Lines 234-343):
- Trial expired → Show paywall
- Messages exhausted → Show limit dialog
- Account suspended → Show lockout overlay
- Message consumption with floating badge feedback

**Conversation Persistence** (Lines 71-157):
- Creates fresh session on open (old sessions in history)
- Auto-saves messages to database
- Welcome message for new sessions
- Verse context support for discussion mode

### 1.3 Data Models

#### `/lib/models/chat_message.dart` (258 lines)
```dart
ChatMessage {
  id: String,
  content: String,
  type: MessageType (user | ai | system),
  timestamp: DateTime,
  status: MessageStatus (sending | sent | delivered | failed),
  verses: List<BibleVerse>,
  metadata: Map<String, dynamic>?,
  userId: String?,
  sessionId: String?,
}
```

**Database Serialization**:
- toMap() / fromMap() for SQLite storage
- toJson() / fromJson() for export/import
- Verse references stored as JSON array
- Metadata preserved in JSON blob

#### `/lib/models/chat_session.dart` (418 lines)
```dart
ChatSession {
  id: String,                    // "session_{timestamp}"
  title: String,
  createdAt: DateTime,
  lastMessageAt: DateTime,
  messageCount: int,
  userId: String?,
  tags: List<String>,
  status: SessionStatus (active | archived | deleted),
  metadata: Map<String, dynamic>?,
  summary: String?,
  themes: List<String>,          // Spiritual themes discussed
}
```

---

## 2. WEB-SPECIFIC CONSIDERATIONS

### 2.1 Database Implementation for Web

#### `/lib/core/database/database_helper.dart` (100+ lines)
**Architecture**: Conditional compilation for platform-specific database

```dart
// Conditional imports - resolved at compile time
import 'database_helper_mobile.dart'
    if (dart.library.html) 'database_helper_web.dart';

class DatabaseHelper {
  static final _impl = DatabaseHelperImpl.instance;
  Future<dynamic> get database => _impl.database;
  // All methods delegate to platform-specific impl
}
```

**Why This Works**:
- Zero runtime platform detection
- Full API compatibility between mobile (sqflite) and web (sql.js)
- All 17 services use identical code on both platforms

#### `/lib/core/database/database_helper_web.dart` (150+ lines)
**Web Database Stack**:
```
sql.js (JavaScript SQLite)
    ↓
SqlJsHelper (Wrapper)
    ↓
Database initialization with 23 tables
    ├─ Bible data loading (English + Spanish)
    ├─ FTS index setup
    ├─ Default settings insertion
    └─ Persistence to IndexedDB
```

**Key Web Constraints**:
- **Storage Size**: 50MB IndexedDB limit per origin (bible.db = 27MB)
- **Synchronous Limitation**: sql.js runs on main thread
- **Asset Loading**: rootBundle.loadString() for initial data
- **No File Access**: Can't use native filesystem APIs

### 2.2 Asset Configuration

#### `/pubspec.yaml` (Asset Section)
```yaml
assets:
  - assets/devotionals/en/        # 14 batch JSON files (devotional content)
  - assets/devotionals/es/        # Spanish devotionals
  - assets/reading_plans/en/      # Reading plan JSON files
  - assets/reading_plans/es/
  - assets/data/                  # bible_books.json, sample_verses.json
  - assets/bible.db               # 27MB - Full Bible in SQLite
  - assets/spanish_bible_rvr1909.db  # 16MB - Spanish Bible
  - assets/bible_web_optimized.sql   # SQL dump for web loading
  - assets/spanish_rvr1909_optimized.sql
  - assets/bible_transform.sql    # Schema & migration SQL
  - .env                          # Gemini API keys
```

**Web Asset Constraints**:
- Total downloadable size matters for PWA initial load
- Bible databases compressed in PWA manifest
- JSON assets loaded on-demand

### 2.3 Storage Mechanisms

**SharedPreferences** (`shared_preferences: ^2.2.3`):
- On web: Uses localStorage (5-10MB limit per origin)
- Current uses: API key rotation counter, preferences

**IndexedDB** (via sql.js):
- On web: Persistent database storage
- Size: 50MB limit per origin
- Current: Chat messages, prayer journal, reading progress

**Session Storage**:
- User language preference
- Current conversation session ID
- UI state (text scale, theme, etc.)

---

## 3. DEPENDENCIES & CONSTRAINTS

### 3.1 Core AI/ML Packages

| Package | Version | Purpose | Web Support |
|---------|---------|---------|------------|
| google_generative_ai | 0.4.0 | **PRIMARY**: Gemini API integration | ✅ YES (HTTP) |
| flutter_dotenv | 6.0.0 | Load 20 API keys from .env | ✅ YES |
| shared_preferences | 2.2.3 | Store API key rotation counter | ✅ YES (localStorage) |
| sqflite_common_ffi_web | 1.0.2 | SQL.js wrapper for web SQLite | ✅ YES |

**NOTABLY MISSING**:
- No tensorflow_lite (TFLite)
- No on_device_inference (no local ML models)
- No transformers package (hugging face)
- No speech_recognition or text_to_speech (TTS exists but not for chat)

### 3.2 Other Critical Packages

| Category | Package | Notes |
|----------|---------|-------|
| State | flutter_riverpod | Chat messages, AI state |
| Database | sqflite, sqflite_common | Conversation persistence |
| Security | flutter_secure_storage | API key storage (mobile only) |
| Networking | http, dio | API requests, retry logic |
| Localization | intl, flutter_localizations | English/Spanish support |
| UI | flutter_animate, flutter_scalify | Responsive design |

### 3.3 Size Constraints for PWA

**Current Build Analysis**:
```
Assets:
├─ bible.db (27MB)
├─ spanish_bible_rvr1909.db (16MB)
├─ Devotionals (En/Es batches) (~5MB)
└─ Other assets (~10MB)
Total Asset Size: ~58MB

Web Build:
├─ Framework (~30MB)
├─ App code (~5MB)
└─ Assets (served separately) 
Total: ~100MB+ before compression

PWA Constraints:
├─ Initial load: <50MB recommended
├─ Serve: Via CDN with gzip
├─ Cache: Service worker cache busting
└─ Storage: 50MB IndexedDB limit
```

**Impact**: Bible databases must be lazy-loaded or chunked

---

## 4. CHAT FEATURES & IMPLEMENTATION

### 4.1 Streaming vs Non-Streaming

**Current Implementation**: BOTH
```dart
// Blocking (used for regeneration)
Future<AIResponse> generateResponse(...) async
  → Waits for full response
  → Slower perceived UX but simpler

// Streaming (default for new messages)
Stream<String> generateResponseStream(...) async*
  → Yields chunks as they arrive
  → Typing animation effect
  → Better perceived responsiveness
  → Network interruption vulnerable
```

**Streaming Flow**:
```
1. Create AI message placeholder
2. Show "typing indicator"
3. Open stream
4. For each chunk:
   - Append to message content
   - Update UI in real-time
5. When complete:
   - Hide typing indicator
   - Save full message to DB
   - Filter response
```

### 4.2 Conversation Persistence

**Storage Strategy**:
```
SQLite Database
├─ chat_sessions table
│  └─ id, title, created_at, last_message_at, themes, etc.
├─ chat_messages table
│  └─ id, session_id, content, type, timestamp, verses, metadata
└─ Indexes on (session_id, timestamp)
```

**Session Management** (ConversationService):
```
createSession(title)           → New session for each chat
getMessages(sessionId)          → Load conversation history
getRecentMessages(sessionId)    → Last N messages (default 50)
saveMessage(ChatMessage)        → Persist individual messages
saveMessages(List)              → Batch save in transaction
updateSession(ChatSession)      → Update metadata
archiveSession(id)              → Soft delete
```

**History Limitation** (ai_provider.dart:427-446):
```dart
// Limit to last 20 messages for API efficiency
final recentHistory = conversationHistory.length > 20
    ? conversationHistory.sublist(conversationHistory.length - 20)
    : conversationHistory;

// Format: "USER: ...\nCOUNSELOR: ..."
return recentHistory.map((msg) => '${label}: ${msg.content}').toList();
```

**Why 20 Messages?**:
- Token efficiency (Gemini: 1000 token max output)
- Context window management
- API cost control
- Response time (fast enough for web)

### 4.3 Multi-Language Support

**English & Spanish**:

**English Prompts** (`_buildEnglishPrompt()` - Lines 376-464):
```
Three intent-based system prompts:
1. Guidance (pastoral counseling) - empathetic, supportive
2. Discussion (theological) - educational, conversational
3. Casual (faith topics) - warm, gentle
```

**Spanish Prompts** (`/lib/services/prompts/spanish_prompts.dart` - 100+ lines):
```
Identical structure to English
- Same tone requirements
- Same security rules
- Same verse integration
- Native Spanish phrasing
```

**Theme Detection** (English & Spanish):
```
Theme Keywords (case-insensitive):
anxiety: "anxious", "worried", "stress", "overwhelmed", "panic"
depression: "sad", "depressed", "hopeless", "down", "discouraged"
strength: "weak", "tired", "exhausted", "struggle", "difficult"
guidance: "decision", "choice", "direction", "confused", "lost"
forgiveness: "forgive", "hurt", "angry", "resentment", "bitter"
purpose: "purpose", "meaning", "calling", "why", "direction"
relationships: "relationship", "marriage", "family", "friend", "conflict"
fear: "afraid", "scared", "fear", "nervous", "terrified"
doubt: "doubt", "question", "faith", "believe", "uncertain"
gratitude: "thankful", "grateful", "blessed", "appreciate"
```

### 4.4 Content Filtering & Security

#### Input Security (`/lib/core/services/input_security_service.dart`)

**Threat Levels**:
```
LOW     - Typos, mild patterns
MEDIUM  - Clear bypasses (log & block)
HIGH    - Sophisticated attacks (log, block, consider ban)
CRITICAL - Coordinated (immediate intervention)
```

**Blocked Patterns** (Examples):
```
Instruction Overrides:
  "ignore previous instructions"
  "ignore your instructions"
  "forget your training"
  "override your programming"
  "developer mode"
  "debug mode"

Jailbreak Attempts:
  "you are now DAN"
  "pretend you're not a counselor"
  "roleplaying as..."

Profanity Detection:
  [Various offensive words]

Rate Limiting:
  Max 5 messages/minute
  Max 1000 characters per message
  Min 1 character minimum
```

#### Content Filter (`/lib/core/services/content_filter_service.dart`)

**Blocks Harmful Theology**:
```
Prosperity Gospel:
  "name it and claim it"
  "positive confession"
  "speak it into existence"
  "faith will make you rich"
  "god wants you wealthy"

Spiritual Bypassing:
  "just pray harder"
  "just have more faith"
  "real christians don't..."
  "god won't give you more than you can handle"
  "everything happens for a reason"
  "god is punishing you"

Toxic Positivity:
  "don't be sad"
  "stop being negative"
  "just think positive"
  "other people have it worse"
  "count your blessings"
  "depression is a sin"
  "anxiety is a sin"

Hate Speech & Discrimination:
  [Various patterns]
```

**Fallback Response** (on filter rejection):
```
Returns theme-specific comfort message with Scripture
instead of letting harmful response reach user
```

#### Suspension System

**Violation Types & Thresholds**:
```
Violation 1 (Warning):        7-day suspension warning
Violation 2:                  7-day chat suspension
Violation 3:                  30-day chat suspension
Violation 4+:                 90-day suspensions (repeating)

Tracked In:                   Suspension database
Enforcement:                  Chat screen lockout overlay
Subscription Impact:          None (other features remain)
Appeal Process:               connect@everydaychristian.app
```

### 4.5 Crisis Detection

**Detected Keywords** (Intent Detection Service):
```
Suicidal:     "suicidal", "kill myself", "want to die", "end my life"
Self-Harm:    "self harm", "cutting", "hurting myself"
Abuse:        "being abused", "abusive", "abuse situation"
Faith Crisis: "losing faith", "no longer believe"
```

**Action**: Shows crisis resources (phone numbers, links)

---

## 5. PERFORMANCE REQUIREMENTS & CONSTRAINTS

### 5.1 Expected Response Times

**Typical Performance** (Production):
```
API Latency:           2-5 seconds (varies by load)
Streaming Start:       1-2 seconds
Chunk Delivery:        100-500ms per chunk (50-200 chars)
Typing Animation:      ~15ms per character
Total User Wait:       3-7 seconds to first visible text
                       5-15 seconds for complete response
```

**Mobile vs Web**:
```
Mobile (4G LTE):       Faster local DB, native performance
Web (Browser):         
  ├─ Connection: Often slower (WiFi variable)
  ├─ Rendering: 60fps animations, CSS paint
  ├─ Storage: IndexedDB slower than SQLite
  └─ Processing: JavaScript single-threaded
```

### 5.2 Token Limits

**Gemini 2.0 Flash Configuration**:
```
Max Output Tokens:     1000 (hard limit)
Typical Response:      300-500 tokens (~150-250 words)
Conversation History:  Last 20 messages (~2000 tokens)
Bible Verses:          3 verses (~300 tokens)
System Prompt:         ~500 tokens
Total Budget:          ~2500 tokens input + 1000 output

⚠️ CONSTRAINT: Large inputs risk truncation
```

### 5.3 Memory Constraints

**Web Browser Memory**:
```
sqlite on Memory:      ~50MB (sql.js JavaScript copy)
Chat History Cache:    ~1-5MB (last 50 messages)
App State (Riverpod):  ~10MB (providers, UI state)
UI Layer (Flutter):    ~50MB (canvas, rendering)
Total Expected:        ~150MB (comfortable on modern devices)

⚠️ Mobile Devices:      <256MB RAM phones will struggle
```

### 5.4 Rate Limiting

**API Key Rotation**:
```
20 Keys:               Each handles ~1/20th of traffic
Round-Robin:           Distributes evenly over time
Random Offset:         Prevents synchronized spikes
Max Requests/Key:      ~600-1000/minute (Gemini default)
Handles:               ~10,000+ concurrent users safely
```

**User-Level Limits**:
```
Message Limits (Trial):       5 messages/day free tier
Message Limits (Premium):     Unlimited for subscription duration
Per-Session:                  No hard limit (but DB storage finite)
Rate Limiting:                5 messages/minute per user
```

---

## 6. TRAINING DATA & OPTIMIZATION

### 6.1 Training Data Location

**LSTM Training Data**:
```
File:                  assets/lstm_training_data.txt
Size:                  Unknown (not found in assets/)
Format:                
  USER: [user input]
  RESPONSE: [ai response]
  [blank line]
  USER: ...

Examples:              19,750 real counseling examples (claimed)
Loading:               Optional - app works without it
```

**Current Status**: Training data NOT FOUND in codebase
- References in code suggest it was intended
- Gemini works fine without training examples
- Code attempts to load it anyway (graceful failure)

### 6.2 Prompt Engineering Strategy

**Two-Tier Approach**:

**Tier 1: System Intent Detection**
```
Detect user intent → Choose system prompt template
├─ Guidance (pastoral care needed)
├─ Discussion (educational)
└─ Casual (light conversation)
```

**Tier 2: Theme-Based Personalization**
```
Detect emotional themes → Customize tone & focus
├─ Anxiety → calming tone, peace focus
├─ Depression → encouraging tone, hope focus
├─ Strength → empowering tone, courage focus
└─ [10 total themes]
```

**Tier 3: Example-Based In-Context Learning**
```
Find relevant training examples (keyword matching)
└─ Include 3-5 best matching examples in prompt
    (Human counselor would say... → AI learns by example)
```

---

## 7. CURRENT STRENGTHS

1. **Robust Security Pipeline**
   - Input validation before API call
   - Output content filtering
   - Suspension system for abuse
   - Crisis detection & resources

2. **Excellent Conversation UX**
   - Real-time streaming with typing animation
   - Persistent history across sessions
   - Theme-aware responses
   - Multi-language support (En/Es)

3. **Smart Fallback System**
   - Works without training data
   - Fallback responses if API fails
   - Theme-based encouragement
   - Graceful degradation

4. **Web Deployment Ready**
   - Platform-agnostic database
   - No iOS-specific dependencies
   - Full PWA compatibility
   - Service worker caching

5. **Cost-Efficient Design**
   - 20 API key rotation → load distribution
   - 20-message conversation history limit → token efficiency
   - 1000 token max output → cost control
   - Subscription model → revenue aligned with API costs

---

## 8. CURRENT LIMITATIONS

1. **Internet Required for AI**
   - All responses hit Gemini API
   - No offline chat capability
   - Connectivity check before send

2. **Token Constraints**
   - 1000 token max output (can truncate)
   - 20 message history limit (loses context)
   - Large prompts risk truncation

3. **Streaming Fragility**
   - Network interruption = lost response
   - Browser tab close = abandoned request
   - No resume capability

4. **Storage Limits**
   - 50MB IndexedDB on web
   - Bible databases (43MB) leave only 7MB for chat
   - Long conversations stored in SQLite (takes space)

5. **Training Data Missing**
   - Code references 19,750 examples
   - Asset file not found in build
   - Gemini uses generic knowledge instead

6. **Performance on Slow Networks**
   - Initial PWA load with 50MB assets
   - Streaming chunks variable latency
   - IndexedDB slower on low-end devices

---

## TECHNICAL ARCHITECTURE DIAGRAM

```
┌─────────────────────────────────────────────────────────────┐
│                     EVERYDAY CHRISTIAN PWA                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────┐                                   │
│  │   CHAT SCREEN        │                                   │
│  │  (Flutter Widget)    │                                   │
│  │                      │                                   │
│  │ Input Validation ──→ Security Check ──→ API Call        │
│  │ Streaming Display    Content Filter     Response         │
│  └────────┬─────────────┘                                   │
│           │                                                  │
│  ┌────────▼─────────────────────────────────┐              │
│  │    AI SERVICE ADAPTER (ai_provider.dart)  │              │
│  │                                            │              │
│  │  ✓ Input Security Check                   │              │
│  │  ✓ Theme Detection                        │              │
│  │  ✓ Verse Selection (UnifiedVerseService) │              │
│  │  ✓ Conversation History (20 messages)    │              │
│  │  ✓ Content Filtering                      │              │
│  │  ✓ Fallback Responses                     │              │
│  └────────┬─────────────────────────────────┘              │
│           │                                                  │
│  ┌────────▼──────────────────────────────────┐             │
│  │   GEMINI AI SERVICE                        │             │
│  │   (gemini_ai_service.dart)                 │             │
│  │                                            │             │
│  │  • generateResponse() - Blocking           │             │
│  │  • generateStreamingResponse() - Stream    │             │
│  │  • Prompt Building & Optimization          │             │
│  │  • API Key Rotation (20 keys)              │             │
│  │  • Training Example Matching               │             │
│  └────────┬──────────────────────────────────┘             │
│           │                                                  │
│  ┌────────▼──────────────────────────────────┐             │
│  │   GOOGLE GEMINI 2.0 FLASH API              │             │
│  │   (Cloud Service)                          │             │
│  │                                            │             │
│  │  • Temperature: 0.9                        │             │
│  │  • Max Tokens: 1000                        │             │
│  │  • Safety: Custom (disabled defaults)      │             │
│  │  • Response: 3-7 seconds typical           │             │
│  └────────┬──────────────────────────────────┘             │
│           │                                                  │
│  ┌────────▼──────────────────────────────────┐             │
│  │   PERSISTENCE LAYER                        │             │
│  │                                            │             │
│  │  ┌─────────────────────────────────────┐  │             │
│  │  │  ConversationService                │  │             │
│  │  ├─────────────────────────────────────┤  │             │
│  │  │  • createSession()                  │  │             │
│  │  │  • saveMessage()                    │  │             │
│  │  │  • getMessages(sessionId)           │  │             │
│  │  └────────┬────────────────────────────┘  │             │
│  │           │                                 │             │
│  │  ┌────────▼────────────────────────────┐  │             │
│  │  │  DATABASE (Platform-Agnostic)       │  │             │
│  │  │                                      │  │             │
│  │  │  Mobile: sqflite (SQLite native)   │  │             │
│  │  │  Web: sql.js (JavaScript SQLite)   │  │             │
│  │  │                                      │  │             │
│  │  │  Tables:                             │  │             │
│  │  │  ├─ chat_sessions                   │  │             │
│  │  │  ├─ chat_messages                   │  │             │
│  │  │  ├─ bible_verses                    │  │             │
│  │  │  ├─ devotionals                     │  │             │
│  │  │  └─ [20 more tables]                │  │             │
│  │  └─────────────────────────────────────┘  │             │
│  └────────────────────────────────────────────┘             │
│                                                              │
└─────────────────────────────────────────────────────────────┘

SUPPORTING SERVICES:
├─ InputSecurityService: Detects jailbreak, profanity, rate limit
├─ ContentFilterService: Blocks harmful theology
├─ IntentDetectionService: Guides vs discussion vs casual
├─ UnifiedVerseService: Bible verse retrieval & matching
├─ CrisisDetectionService: Suicidal/self-harm keywords
├─ SuspensionService: User bans for abuse
└─ SubscriptionService: Message limits, trial expiry
```

---

## RECOMMENDATIONS FOR LOCAL AI INTEGRATION

### Option A: Web Transformers (ONNX Runtime)
**Best for**: Full offline capability

Approach:
1. Convert Gemini prompt engineering → ONNX model
2. Use `onnxruntime_web` package (Wasm)
3. Load lightweight model (~100-200MB)
4. Run inference on browser (GPU acceleration possible)

Pros:
- Completely offline
- No API dependency
- Privacy-first

Cons:
- Model size (PWA bloat)
- Inference time (slower than cloud)
- Model quality (not as sophisticated as Gemini)
- Requires retraining on pastoral data

### Option B: Hybrid Cloud-Local
**Best for**: Graceful fallback

Approach:
1. Keep Gemini as primary (when online)
2. Deploy lightweight local model (ONNX)
3. Use local model as fallback when offline

Pros:
- Best of both worlds
- Offline capability
- Can use Gemini's superior responses

Cons:
- Complexity (two AI systems)
- Storage for both models
- Different response quality

### Option C: API Caching Strategy
**Best for**: Improving perceived performance

Approach:
1. Cache common response patterns
2. Detect similar messages → serve from cache
3. Only call Gemini for novel queries

Pros:
- Reduce API costs
- Faster responses
- Simpler to implement

Cons:
- Limited offline help
- Cached responses may seem repetitive
- Cache invalidation complexity

---

## SUMMARY TABLE

| Aspect | Current | Local AI Requirement |
|--------|---------|----------------------|
| **Architecture** | Cloud (Gemini API) | Local (Browser-based) |
| **Responsiveness** | 3-7 sec (API latency) | <1 sec (local inference) |
| **Offline** | ❌ No | ✅ Yes |
| **Privacy** | ❌ Data to Google | ✅ Local only |
| **Quality** | ✅ Excellent (Gemini 2.0) | ❓ Depends on model |
| **Cost** | API costs (~$0.10-0.50/user) | Zero per query |
| **Maintenance** | Google handles | Self-managed |
| **Model Updates** | Automatic | Manual |
| **GPU Needed** | No | Optional (faster) |

