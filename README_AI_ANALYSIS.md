# AI Chat Architecture Analysis - Quick Reference

## Key Findings at a Glance

### Current State
- **AI Model**: Google Gemini 2.0 Flash (Cloud-based)
- **Status**: 100% internet-dependent, no offline capabilities
- **Security**: Sophisticated (jailbreak detection, content filtering, crisis detection)
- **Quality**: Excellent (Gemini is state-of-the-art)
- **Cost**: ~$0.10-0.50 per user per day

### Architecture
```
User Input → Security Check → Gemini API → Content Filter → User
                ↓
          Database (SQLite)
```

### Performance
- Response time: 3-7 seconds (API latency)
- Streaming enabled (typing animation)
- 20-message conversation history
- 1000 token max output

---

## Critical Files

### Core AI Implementation
| File | Lines | Purpose |
|------|-------|---------|
| `/lib/services/gemini_ai_service.dart` | 575 | Direct API integration |
| `/lib/services/ai_service.dart` | 329 | Abstract interface & config |
| `/lib/providers/ai_provider.dart` | 579 | Riverpod state mgmt + security |
| `/lib/screens/chat_screen.dart` | 1000+ | Chat UI & streaming |
| `/lib/services/conversation_service.dart` | 484 | Persistence layer |

### Security & Filtering
| File | Purpose |
|------|---------|
| `input_security_service.dart` | Jailbreak detection, rate limiting |
| `content_filter_service.dart` | Harmful theology blocking |
| `intent_detection_service.dart` | Guidance vs discussion classification |
| `crisis_detection_service.dart` | Suicide/abuse keyword detection |
| `suspension_service.dart` | User ban system |

### Web-Specific
| File | Purpose |
|------|---------|
| `database_helper_web.dart` | SQL.js wrapper (web database) |
| `database_helper.dart` | Platform-agnostic DB interface |
| `sql_js_helper.dart` | JavaScript SQLite binding |

---

## Web Deployment Status

### ✅ Ready for Web
- No iOS-specific dependencies
- Responsive design (flutter_scalify)
- Web database (sql.js)
- PWA manifest configured
- Service worker support

### ⚠️ Constraints
- **Storage**: 50MB IndexedDB limit (Bible 43MB leaves 7MB for chat)
- **Assets**: 100MB+ total (needs CDN + gzip)
- **Internet**: Required for all AI features

### ❌ Missing
- No offline AI capability
- No local transformer models
- No ONNX Runtime integration

---

## Local AI Feasibility

### Why Convert to Local?
| Reason | Impact |
|--------|--------|
| **Offline capability** | No internet = no counseling |
| **Privacy** | Google sees all user queries |
| **Cost** | $0.10-0.50/day → $0 per query |
| **Speed** | 3-7 sec → <1 sec (local) |
| **Latency** | Variable network → consistent |

### Challenges
| Challenge | Severity | Solution |
|-----------|----------|----------|
| Model size (1.1GB) | **HIGH** | Quantize to 300MB, split chunks |
| Inference speed | **HIGH** | Use ONNX, optimize for WASM |
| Quality degradation | **MEDIUM** | Fine-tune on 19,750 examples |
| Browser compatibility | **MEDIUM** | Feature detection, fallback |
| User device memory | **MEDIUM** | Progressive loading, fallback |

---

## Recommended Approach

### Hybrid Strategy (Best Balance)

```
User Online?
├─ YES  → Use Gemini (best quality, no setup cost)
└─ NO   → Use Local Model (offline capable, lower quality)

Always try:
├─ Gemini (if online) - Premium
├─ Local Model (if cached) - Good quality, fast
└─ Rule-based fallback - Basic support
```

### Implementation Timeline
- **Phase 1-2**: ONNX setup (2-3 weeks)
- **Phase 3-4**: Model fine-tuning (3-4 weeks)
- **Phase 5-6**: Performance optimization (2-3 weeks)
- **Phase 7-8**: Testing & deployment (4 weeks)
- **Total**: ~16 weeks (4 months)

---

## Key Decisions to Make

### 1. Local AI Priority
- [ ] **Essential**: Must work offline (build Phase 1-4)
- [ ] **Nice to have**: Offline support secondary (build Phase 1-2 only)
- [ ] **Not needed**: Stay with Gemini only

### 2. Model Choice
- [ ] **microsoft/phi-2** (1.4GB → 350MB) - Recommended
- [ ] **tinyLLAMA** (1.1GB → 275MB) - Faster
- [ ] **DistilGPT-2** (350MB → 85MB) - Smallest
- [ ] **Custom**: Train your own

### 3. Training Data
- [ ] **Use existing**: 19,750 pastoral examples (need to find)
- [ ] **Collect new**: Gather from support interactions
- [ ] **Fine-tune**: Full training on pastoral domain
- [ ] **Prompt only**: No fine-tuning, use prompt engineering

### 4. Quality vs Size Tradeoff
- [ ] **Premium**: 600MB model, 80% Gemini quality
- [ ] **Balanced**: 350MB model, 70% quality
- [ ] **Lightweight**: 150MB model, 50% quality

---

## Cost Analysis

### Current (Gemini Only)
```
Users: 10,000/month
Avg queries: 5/user
Total queries: 50,000/month
Cost/query: $0.0001
Total cost: $5/month (conservative)

Scale to 100,000 users: $50/month
```

### Hybrid (Gemini + Local)
```
Offline users (20%): Local model (free)
Online users (80%): Gemini ($5/month)

Same 10k users: $4/month saved
Same 100k users: $40/month saved
Annual savings: $480/year (small app)
Annual savings: $4,800/year (100k users)
```

### Local Only
```
Compute cost: $0
Development cost: ~$15,000-20,000
Infrastructure: CDN for model chunks

Break-even: ~40 months (if 100k users)
Better for: Privacy-first, offline-first vision
```

---

## Next Steps

### Immediate (This Week)
1. Read `AI_CHAT_ARCHITECTURE_ANALYSIS.md` (detailed technical analysis)
2. Review `LOCAL_AI_IMPLEMENTATION_ROADMAP.md` (implementation plan)
3. Decide: **Priority** on offline AI support

### Short Term (Next 2-4 Weeks)
- [ ] If pursuing local AI:
  - [ ] Select model (recommendation: phi-2)
  - [ ] Plan infrastructure (CDN, caching)
  - [ ] Set up development environment
  - [ ] Begin Phase 1: Model selection & preparation

### Long Term (Ongoing)
- [ ] Monitor Gemini API costs
- [ ] Collect user feedback on offline need
- [ ] Evaluate new open models
- [ ] Plan for model updates/improvements

---

## Key Contacts & Resources

### Documentation in This Project
- `AI_CHAT_ARCHITECTURE_ANALYSIS.md` - Full technical deep dive
- `LOCAL_AI_IMPLEMENTATION_ROADMAP.md` - Step-by-step implementation guide

### External Resources
- [ONNX Runtime Web](https://onnxruntime.ai/)
- [Hugging Face Models](https://huggingface.co/models)
- [Microsoft Phi-2](https://huggingface.co/microsoft/phi-2)
- [TinyLLAMA](https://github.com/jzhang38/TinyLlama)

### Tools Needed
- Python 3.8+ (model conversion)
- PyTorch (model training)
- ONNX tools (optimization)
- Dart/Flutter (integration)

---

## Questions Answered

**Q: Will offline AI work on all devices?**
A: Mostly. Modern browsers (2020+) support ONNX Runtime. Older devices may fall back to Gemini if online.

**Q: How much slower is local AI?**
A: 200-500ms per chunk (vs Gemini's 100-500ms), but no API latency (~2-4s saved).

**Q: Can I use my training data?**
A: Yes! The 19,750 examples can fine-tune the model (if you find the file).

**Q: Do I need GPU?**
A: No, but GPU makes it 10x faster. Optional for web (CPU-only in browser).

**Q: What if users' device runs out of memory?**
A: Graceful fallback to cached responses or Gemini (if online).

**Q: Can I deploy incrementally?**
A: Yes! Keep Gemini, add local model gradually. Users see no difference.

---

## Success Metrics

After implementation, measure:
- ✅ Offline chat works: 95%+ success rate
- ✅ Response quality: 75%+ parity with Gemini
- ✅ Performance: <2 sec inference time
- ✅ User satisfaction: No quality complaints
- ✅ Adoption: >50% of users try offline mode

---

## Summary

The Everyday Christian PWA has a **sophisticated, well-designed AI chat system** that's currently 100% cloud-dependent. Converting to **hybrid cloud+local** is feasible in **4-5 months** with good engineering. The biggest decision is whether **offline capability is worth the investment**.

Start with Phase 1-2 as proof-of-concept (~6-8 weeks) to validate approach before committing to full implementation.

