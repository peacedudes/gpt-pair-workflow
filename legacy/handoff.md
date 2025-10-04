# HANDOFF.md

Audience
- Next GPT-5 assistant working on VoiceLogin/VoiceKit.
- You are expected to parse the codebase quickly; this doc points to hotspots and next actions.

State of play
- VoiceKit modules (VoiceKitCore/VoiceKitUI) provide TTS and a picker UI with a ViewModel.
- Tests under Tests/VoiceKitUITests exercise filtering, preview, bootstrapping, store behavior.

Recent decisions
- Tests must be deterministic and must not query system voices:
  - Use a FakeTTS that conforms to VoiceListProvider.
  - Initialize VoicePickerViewModel with allowSystemVoices: false in tests.
- To satisfy Swift 6 isolation:
  - If FakeTTS is @MainActor, mark availableVoices() as nonisolated.
  - Library-side protocol VoiceListProvider is annotated with @preconcurrency to relax conformance constraints.
- Patching discipline discovered:
  - Multi-hunk patches must include a newline after each hunk header line.
  - Every fenced block in chat must end with a trailing newline for the user’s tooling.

What compiles vs broken (likely)
- The project builds, but one or more UI tests may still fail to compile if any FakeTTS lacks nonisolated availableVoices() or if a test ViewModel still allows system voices.
- Filtering test: close to green after applying nonisolated fix and forbidding system voices.
- Preview/Bootstrapping tests: may need the same treatment.

Immediate next steps (as patches)
- For each UI test file using a FakeTTS:
  1) Conform to VoiceListProvider.
  2) Add nonisolated func availableVoices() -> [TTSVoiceInfo] { voices }
  3) Initialize VoicePickerViewModel(... allowSystemVoices: false)

Typical patch pattern (multi-hunk example)
- Two-hunk patch: add nonisolated and forbid system voices.

Example (adjust file paths/hunks as needed):
- File: Tests/VoiceKitUITests/VoicePickerPreviewSelectionTests.swift
- Hunk 1: FakeTTS conformance + nonisolated availableVoices()
- Hunk 2: allowSystemVoices: false on ViewModel init

Use this structure (note the blank line after each @@ header):
```diff
diff --git a/Tests/VoiceKitUITests/VoicePickerPreviewSelectionTests.swift b/Tests/VoiceKitUITests/VoicePickerPreviewSelectionTests.swift
index abcdef0..abcdef1 100644
--- a/Tests/VoiceKitUITests/VoicePickerPreviewSelectionTests.swift
+++ b/Tests/VoiceKitUITests/VoicePickerPreviewSelectionTests.swift
@@ -18,7 +18,8 @@
 @MainActor
 final class VoicePickerPreviewSelectionTests: XCTestCase {

-    final class FakeTTS: TTSConfigurable {
+    final class FakeTTS: TTSConfigurable, VoiceListProvider {
         var voices: [TTSVoiceInfo] = []
+        nonisolated func availableVoices() -> [TTSVoiceInfo] { voices }
         // other TTSConfigurable stubs...
     }

@@ -55,7 +56,7 @@
     func testPreviewSelection() {
         let tts = FakeTTS()
         let store = VoiceProfilesStore(filename: "preview-\(UUID().uuidString).json")
-        let vm = VoicePickerViewModel(tts: tts, store: store)
+        let vm = VoicePickerViewModel(tts: tts, store: store, allowSystemVoices: false)
         // rest of test...
     }
```

Library notes
- VoiceListProvider should exist and be public in VoiceKitUI. It should be annotated:
  - @preconcurrency public protocol VoiceListProvider { func availableVoices() -> [TTSVoiceInfo] }
- ViewModel should resolve voices like:
  - if let provider = tts as? VoiceListProvider { voices = provider.availableVoices() }
  - else if allowSystemVoicesEffective { query system voices } else { voices = [] }
- Preview path should be safe (avoid force unwraps).

Consoles and warnings
- Known harmless but noisy logs (audio stack and concurrency). Avoid introducing new warnings. If you can silence them without delaying other goals, do so.
- Xcode suggestion to use async schedule call is currently deferred; do not break latency goals.

How to interact with the user
- Keep it brief.
- One question at a time.
- Always provide patches in fenced code blocks with trailing newline.
- If multi-hunk, ensure the newline after each @@ header. This is non-negotiable.

If something fails
- Ask for a 5–10 line context snippet around the failing spot.
- Regenerate a small, precise patch (prefer 1–2 hunks).
- Avoid whole-file replacements unless explicitly requested.

End goal reminder
- VoiceKit should feel like high art: obvious APIs, robust behavior, elegant internals, and tests that double as documentation.
- We aim for a polished, fast, and concurrency-correct voice experience that impresses sharp reviewers and delights users.
```
