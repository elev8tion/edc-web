# Local AI Implementation Roadmap for Everyday Christian PWA

## Overview

This document provides a concrete roadmap for implementing 100% local AI capabilities using web transformers and ONNX Runtime, allowing the app to work completely offline while maintaining response quality.

---

## Phase 1: Model Selection & Preparation

### 1.1 Choose Your Model

**Recommended Models for Web Transformers**:

| Model | Size | Speed | Quality | License | Notes |
|-------|------|-------|---------|---------|-------|
| distilbert-base-uncased-finetuned | 67MB | Fast | Good | MIT | Lightweight, good for classification |
| microsoft/phi-2 | 1.4GB | Slow | Excellent | MIT | Small but capable language model |
| tinyLLAMA-1.1B | 1.1GB | Slow | Good | MIT | Small general-purpose LLM |
| DistilGPT-2 | 350MB | Fast | Moderate | MIT | Distilled version of GPT-2 |
| Qwen/Qwen-1.8B | 1.8GB | Moderate | Excellent | Custom | Fast, good reasoning |

**Recommendation for Biblical Counseling**:
- **Primary**: Fine-tune `tinyLLAMA-1.1B` on 19,750 pastoral examples
- **Fallback**: `microsoft/phi-2` (if size permits)
- **Web Size**: Quantized to 400-600MB ONNX format

### 1.2 Model Conversion Pipeline

```bash
# 1. Get base model from Hugging Face
huggingface-cli download microsoft/phi-2 --local-dir ./phi-2

# 2. Quantize for web (reduce size by 50-75%)
python convert_to_onnx.py \
  --model phi-2 \
  --quantization int8 \
  --output-path ./models/phi-2-onnx-int8

# 3. Optimize for web execution
python optimize_onnx.py \
  --model phi-2-onnx-int8 \
  --target-platform web \
  --optimizations all
```

**Size Optimization**:
```
Original Model:        1.1GB (float32)
→ Quantized (int8):    275MB
→ Compressed (gzip):   85MB
→ Chunked (3x30MB):    For progressive loading

PWA Total Size Target: ~500MB
├─ Original assets:    100MB
└─ AI model:           ~400MB (compressed, split into chunks)
```

---

## Phase 2: ONNX Runtime Integration

### 2.1 Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  # ... existing packages ...
  
  # ONNX Runtime for web inference
  onnxruntime_web: ^1.17.0  # Web-specific ONNX runtime
  
  # Optional: GPU acceleration
  onnxruntime_web_gpu: ^1.17.0  # WASM + GPU support
```

### 2.2 Create Local AI Service

```dart
// lib/services/local_ai_service.dart
import 'package:onnxruntime_web/onnxruntime_web.dart';

class LocalAIService implements AIService {
  late Session _session;
  late Tokenizer _tokenizer;
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    // Load ONNX model from assets
    final modelBytes = await rootBundle.load('assets/models/phi-2-onnx.ort');
    
    // Initialize ONNX Runtime
    _session = await OrtSession.fromBytes(
      modelBytes.buffer.asUint8List(),
      modelProvider: OrtSessionOptions()
        ..graphOptimizationLevel = GraphOptimizationLevel.all
        ..enableCpuMemArena = true,
    );
    
    // Load tokenizer
    _tokenizer = await _loadTokenizer();
    
    _isInitialized = true;
    debugPrint('✅ Local AI model initialized');
  }

  @override
  Future<AIResponse> generateResponse({
    required String userInput,
    List<ChatMessage> conversationHistory = const [],
    Map<String, dynamic>? context,
    String language = 'en',
  }) async {
    if (!isReady) throw Exception('AI model not initialized');
    
    final stopwatch = Stopwatch()..start();
    
    // Tokenize input
    final tokens = _tokenizer.encode(userInput);
    
    // Prepare input tensor
    final inputTensor = OrtValueTensor.createTensor(Int64List.fromList(tokens));
    
    // Run inference
    final outputs = await _session.run(null, {'input_ids': inputTensor});
    
    // Decode output
    final outputIds = outputs!['output_ids']?.value as List<int>;
    final decodedText = _tokenizer.decode(outputIds);
    
    stopwatch.stop();
    
    return AIResponse(
      content: decodedText,
      verses: [],
      processingTime: stopwatch.elapsed,
      confidence: 0.85,
      metadata: {'source': 'local', 'model': 'phi-2-onnx'},
    );
  }

  @override
  Stream<String> generateResponseStream({...}) async* {
    // Implement token-by-token generation
    // Yield chunks for streaming effect
  }

  @override
  bool get isReady => _isInitialized;
}
```

---

## Phase 3: Intelligent Fallback System

### 3.1 Hybrid Execution (Cloud + Local)

```dart
// lib/providers/hybrid_ai_provider.dart
final hybridAIServiceProvider = Provider<AIService>((ref) {
  final connectivity = ref.watch(connectivityStatusProvider);
  
  // Online: Use Gemini (better quality)
  if (connectivity.value == true) {
    return GeminiAIServiceAdapter(...);
  }
  
  // Offline: Use local model
  return LocalAIService();
});
```

### 3.2 Quality Degradation Strategy

```dart
// lib/services/ai_service_quality_manager.dart
enum AIQualityTier {
  premium,      // Gemini 2.0 (online)
  standard,     // Local phi-2 (offline, first 3 tries)
  fallback,     // Rule-based responses (offline, no inference)
}

class AIServiceQualityManager {
  Future<AIResponse> generateSmartResponse({
    required String userInput,
    required AIQualityTier preferredTier,
  }) async {
    try {
      // Try preferred tier first
      if (preferredTier == AIQualityTier.premium && isOnline) {
        return await _callGemini(userInput);
      }
      
      // Fallback to local if online fails
      if (isLocalModelReady) {
        return await _runLocalModel(userInput);
      }
      
      // Last resort: Rule-based response
      return _createRuleBasedResponse(userInput);
    } catch (e) {
      // Graceful degradation
      return FallbackResponses.getRandomResponse();
    }
  }
}
```

### 3.3 Response Caching

```dart
// lib/services/response_cache_service.dart
class ResponseCacheService {
  final Map<String, AIResponse> _cache = {};
  
  /// Cache responses for common messages
  Future<AIResponse> getCachedOrGenerate({
    required String userInput,
    required Function() generate,
  }) async {
    // Check cache first
    final cached = _cache[_hashInput(userInput)];
    if (cached != null) {
      return cached.copyWith(
        metadata: {...?cached.metadata, 'source': 'cache'},
      );
    }
    
    // Generate and cache
    final response = await generate();
    _cache[_hashInput(userInput)] = response;
    
    // Limit cache size (100MB)
    if (_getTotalSize() > 100 * 1024 * 1024) {
      _evictLRU();
    }
    
    return response;
  }
}
```

---

## Phase 4: Model Training for Pastoral Knowledge

### 4.1 Fine-Tuning on Your Training Data

```python
# scripts/fine_tune_model.py
from transformers import AutoModelForCausalLM, AutoTokenizer
from datasets import load_dataset
import torch

# Load base model
model = AutoModelForCausalLM.from_pretrained("microsoft/phi-2")
tokenizer = AutoTokenizer.from_pretrained("microsoft/phi-2")

# Load your 19,750 examples
dataset = load_dataset(
    "text",
    data_files={"train": "assets/lstm_training_data.txt"}
)

# Format for training
def format_example(example):
    return {
        "text": f"USER: {example['user']}\nASSISTANT: {example['response']}"
    }

dataset = dataset.map(format_example)

# Fine-tune
trainer = Trainer(
    model=model,
    args=TrainingArguments(
        output_dir="./output",
        num_train_epochs=3,
        per_device_train_batch_size=2,
        learning_rate=5e-5,
        warmup_steps=100,
        save_steps=500,
    ),
    train_dataset=dataset["train"],
    data_collator=DataCollatorForLanguageModeling(tokenizer, mlm=False),
)

trainer.train()

# Convert to ONNX
python -m transformers.onnx \
  --model-dir ./output/checkpoint-final \
  --feature causal-lm \
  ./models/phi-2-fine-tuned-onnx
```

### 4.2 Knowledge Injection via Prompt Engineering

```dart
// Even without fine-tuning, inject knowledge via prompts
class LocalAIPromptBuilder {
  static String buildPromptWithKnowledge({
    required String userInput,
    required String theme,
    required List<BibleVerse> verses,
    required List<String> relevantExamples,
  }) {
    return '''You are a compassionate Christian pastoral counselor trained on thousands of real counseling conversations.

Key Counseling Principles:
1. Listen with empathy and understanding
2. Provide biblical wisdom and relevant verses
3. Offer practical spiritual guidance
4. Encourage faith and hope
5. Be non-judgmental and loving

Similar Past Conversations:
${relevantExamples.join('\n---\n')}

Relevant Scripture:
${verses.map((v) => '${v.reference}: "${v.text}"').join('\n')}

User's Message: $userInput

Respond with compassion, biblical grounding, and practical wisdom. Keep it 2-3 paragraphs.
''';
  }
}
```

---

## Phase 5: Progressive Model Loading

### 5.1 Chunked Model Download

```dart
// lib/services/model_loader_service.dart
class ModelLoaderService {
  static const int CHUNK_SIZE = 30 * 1024 * 1024; // 30MB chunks
  static const int TOTAL_CHUNKS = 14; // ~420MB total
  
  Future<void> downloadModelProgressively() async {
    final localStorage = LocalStorage();
    
    for (int i = 0; i < TOTAL_CHUNKS; i++) {
      final url = 'https://cdn.everydaychristian.app/models/phi-2-chunk-$i.bin';
      
      final response = await http.get(Uri.parse(url));
      
      // Save chunk to IndexedDB
      await localStorage.saveModelChunk(i, response.bodyBytes);
      
      // Update progress
      final progress = (i + 1) / TOTAL_CHUNKS;
      onProgress?.call(progress);
      
      debugPrint('Downloaded model chunk ${i+1}/$TOTAL_CHUNKS');
    }
    
    // Reassemble chunks
    final fullModel = await localStorage.reassembleModel();
    await _initializeModel(fullModel);
  }
}
```

### 5.2 Service Worker Caching Strategy

```javascript
// web/service_worker.js
const MODEL_CACHE = 'phi-2-model-v1';
const STATIC_CACHE = 'static-v1';
const DYNAMIC_CACHE = 'dynamic-v1';

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE).then((cache) => {
      return cache.addAll([
        '/',
        '/index.html',
        '/manifest.json',
      ]);
    })
  );
});

// Cache model files separately with long expiry
self.addEventListener('fetch', (event) => {
  if (event.request.url.includes('/models/')) {
    event.respondWith(
      caches.open(MODEL_CACHE).then((cache) => {
        return cache.match(event.request).then((response) => {
          return response || 
            fetch(event.request).then((freshResponse) => {
              cache.put(event.request, freshResponse.clone());
              return freshResponse;
            });
        });
      })
    );
  }
});
```

---

## Phase 6: Performance Optimization

### 6.1 Quantization & Pruning

```python
# scripts/optimize_model.py
from transformers import AutoModelForCausalLM
import torch
from torch.quantization import quantize_dynamic, QConfig, default_dynamic_qconfig

# Load model
model = AutoModelForCausalLM.from_pretrained("./models/phi-2-fine-tuned")

# Dynamic quantization (int8)
quantized_model = quantize_dynamic(
    model,
    qconfig_spec=default_dynamic_qconfig,
    dtype=torch.qint8
)

# Pruning (remove ~30% of weights)
from torch.nn.utils.prune import global_unstructured, WEIGHT_NORM

parameters_to_prune = []
for module in model.modules():
    if isinstance(module, torch.nn.Linear):
        parameters_to_prune.append((module, 'weight'))

global_unstructured(
    parameters_to_prune,
    pruning_method=WEIGHT_NORM,
    amount=0.3,  # Remove 30% of weights
)

# Convert to ONNX with optimizations
model.eval()
dummy_input = torch.randint(0, 32000, (1, 128))

torch.onnx.export(
    model,
    dummy_input,
    "models/phi-2-optimized.onnx",
    opset_version=14,
    do_constant_folding=True,
    input_names=['input_ids'],
    output_names=['logits'],
)
```

### 6.2 Web-Specific Optimizations

```dart
// lib/services/local_ai_performance_optimizer.dart
class LocalAIPerformanceOptimizer {
  /// Limit token generation for web performance
  static const int MAX_TOKENS_WEB = 200; // vs 500 for cloud
  static const int BATCH_SIZE = 1; // No batching in browser
  
  /// Use lower precision on low-memory devices
  Future<void> optimizeForDevice() async {
    final info = await DeviceInfoPlugin().deviceInfo;
    final totalMemory = (info as AndroidDeviceInfo).totalMemory ?? 0;
    
    if (totalMemory < 2 * 1024 * 1024 * 1024) { // <2GB
      // Use int4 quantization
      await _loadModel('models/phi-2-int4.onnx');
    } else {
      // Use int8 quantization
      await _loadModel('models/phi-2-int8.onnx');
    }
  }
  
  /// Streaming generation for faster time-to-first-token
  Stream<String> generateStreaming(String input) async* {
    final tokens = _tokenizer.encode(input);
    
    for (int i = 0; i < tokens.length && i < MAX_TOKENS_WEB; i++) {
      // Generate one token at a time
      final nextToken = await _generateNextToken(tokens);
      tokens.add(nextToken);
      
      yield _tokenizer.decode([nextToken]);
      
      // Yield periodically to avoid blocking
      if (i % 5 == 0) {
        await Future.delayed(Duration.zero);
      }
    }
  }
}
```

---

## Phase 7: Testing & Validation

### 7.1 Quality Metrics

```dart
// test/local_ai_quality_test.dart
void main() {
  group('Local AI Quality Tests', () {
    test('Response quality matches expected theme', () async {
      final service = LocalAIService();
      await service.initialize();
      
      final response = await service.generateResponse(
        userInput: 'I am feeling anxious and overwhelmed',
      );
      
      // Should detect anxiety theme
      final themes = BiblicalPrompts.detectThemes(response.content);
      expect(themes, contains('anxiety'));
      
      // Should include encouraging tone
      final hasEncouragement = response.content
          .toLowerCase()
          .contains(RegExp(r'(peace|calm|trust|god.*with|strength)'));
      expect(hasEncouragement, true);
    });
    
    test('Offline vs Online responses similar quality', () async {
      final userInput = 'I am struggling with doubt';
      
      // Get Gemini response (online)
      final geminiResponse = await geminiService.generateResponse(
        userInput: userInput,
      );
      
      // Get Local response (offline)
      final localResponse = await localService.generateResponse(
        userInput: userInput,
      );
      
      // Both should have similar length
      final lengthDiff = (geminiResponse.content.length - 
                         localResponse.content.length).abs();
      expect(lengthDiff < 100, true);
      
      // Both should detect same theme
      final geminiThemes = BiblicalPrompts.detectThemes(geminiResponse.content);
      final localThemes = BiblicalPrompts.detectThemes(localResponse.content);
      expect(geminiThemes.first, localThemes.first);
    });
    
    test('Inference time within acceptable range', () async {
      final stopwatch = Stopwatch()..start();
      
      await localService.generateResponse(
        userInput: 'Short question?',
      );
      
      stopwatch.stop();
      
      // Should complete within 2 seconds on modern devices
      expect(stopwatch.elapsed.inSeconds < 2, true);
    });
  });
}
```

### 7.2 Integration Tests

```dart
// test/hybrid_ai_fallback_test.dart
void main() {
  group('Hybrid AI Fallback Tests', () {
    test('Falls back to local model when offline', () async {
      // Simulate offline
      mockConnectivity.setConnectivityResult(ConnectivityResult.none);
      
      final response = await hybridService.generateResponse(
        userInput: 'Help me with doubt',
      );
      
      // Should use local model
      expect(
        response.metadata?['source'],
        'local',
      );
    });
    
    test('Prefers Gemini when online', () async {
      // Simulate online
      mockConnectivity.setConnectivityResult(ConnectivityResult.wifi);
      
      final response = await hybridService.generateResponse(
        userInput: 'Help me with doubt',
      );
      
      // Should use Gemini
      expect(
        response.metadata?['source'],
        'gemini',
      );
    });
    
    test('Uses cache for repeated queries', () async {
      const query = 'How can I trust God?';
      
      // First call - hits API
      final response1 = await hybridService.generateResponse(
        userInput: query,
      );
      
      // Second call - hits cache
      final response2 = await hybridService.generateResponse(
        userInput: query,
      );
      
      // Should be identical
      expect(response1.content, response2.content);
    });
  });
}
```

---

## Phase 8: Deployment & Monitoring

### 8.1 PWA Manifest Updates

```json
{
  "name": "Everyday Christian",
  "short_name": "EDC",
  "description": "Offline biblical counseling with AI",
  "display": "standalone",
  "orientation": "portrait",
  "scope": "/",
  "start_url": "/",
  "prefer_related_applications": false,
  
  "screenshots": [
    {
      "src": "icon-192x192.png",
      "sizes": "192x192"
    }
  ],
  
  "categories": ["religion", "health"],
  
  "share_target": {
    "action": "/share",
    "method": "POST",
    "enctype": "multipart/form-data"
  },
  
  "offline_page": "/offline.html"
}
```

### 8.2 Analytics & Monitoring

```dart
// lib/services/ai_analytics_service.dart
class AIAnalyticsService {
  Future<void> trackAIResponse({
    required String source, // 'gemini', 'local', 'cache'
    required int inputLength,
    required int outputLength,
    required Duration latency,
    required double qualityScore,
  }) async {
    final event = {
      'timestamp': DateTime.now().toIso8601String(),
      'source': source,
      'input_length': inputLength,
      'output_length': outputLength,
      'latency_ms': latency.inMilliseconds,
      'quality_score': qualityScore,
    };
    
    // Send to analytics
    await analytics.logEvent(
      name: 'ai_response_generated',
      parameters: event,
    );
    
    // Cache locally for offline analytics
    await localStorage.logAnalytics(event);
  }
}
```

---

## Summary Table: Implementation Effort

| Phase | Task | Effort | Timeline | Dependencies |
|-------|------|--------|----------|--------------|
| 1 | Model Selection | Low | 1 week | Research |
| 2 | ONNX Integration | Medium | 2 weeks | Dependencies, testing |
| 3 | Fallback System | Medium | 2 weeks | Phases 1-2 |
| 4 | Model Training | High | 3-4 weeks | Training data, GPU |
| 5 | Progressive Loading | Medium | 2 weeks | Infrastructure |
| 6 | Performance Opt | Medium | 2 weeks | Python tools |
| 7 | Testing | High | 3 weeks | All phases |
| 8 | Deployment | Low | 1 week | All phases |

**Total Estimated Effort**: 16-18 weeks (4-5 months)

---

## Risk Mitigation

### Model Performance
- **Risk**: Local model quality lower than Gemini
- **Mitigation**: Fine-tune extensively, use caching, hybrid approach

### Storage Size
- **Risk**: Model too large for PWA distribution
- **Mitigation**: Quantization, pruning, chunked loading, optional download

### Inference Speed
- **Risk**: Slow inference time on low-end devices
- **Mitigation**: Smaller models, progressive enhancement, fallbacks

### Browser Compatibility
- **Risk**: ONNX Runtime not supported on older browsers
- **Mitigation**: Feature detection, graceful fallback to Gemini-only

---

## Success Criteria

✅ Local model generates responses without internet
✅ Response quality within 80% of Gemini baseline
✅ Inference time < 3 seconds on average devices
✅ PWA download size remains < 500MB
✅ Works offline on 95%+ of target devices
✅ Seamless fallback to Gemini when online
✅ No user-facing degradation of experience

