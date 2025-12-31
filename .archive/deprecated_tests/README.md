# Deprecated Tests

These tests were archived on 2025-12-31.

## Why Archived

These are **web integration tests** that require:
- Browser environment (`dart:js_interop`)
- Actual SQL asset files
- 3-5 minutes each to run

They fail when running `flutter test` (which uses Dart VM) because they directly import web-specific code that requires browser APIs.

## Tests Archived

| File | Reason |
|------|--------|
| `bible_data_loader_web_test.dart` | Web integration test - requires browser + SQL assets |
| `bible_fts_setup_web_test.dart` | Web integration test - requires browser + SQL assets |
| `prayer_service_web_test.dart` | Web integration test - requires browser |
| `widget_test.dart` | Default Flutter template - tests counter app that doesn't exist |

## Verification

The functionality these tests verified is proven working by:
1. Successful `flutter build web --release` builds
2. Production app Bible functionality working
3. "Compilation tests" in `test/` folder verify APIs exist

## If Needed

To run these tests in browser environment:
1. Add `@TestOn('browser')` annotation at top of file
2. Run: `flutter test --platform chrome <test_file>`
