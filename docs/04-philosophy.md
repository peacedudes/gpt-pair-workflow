# Programming Philosophy, Style, and Expectations

Purpose
- Set a high, shared standard for how we design, code, test, document, and collaborate.
- Ensure a fresh assistant (or human) can align quickly without guessing what “good enough” means.
- Make this repo a small but brilliant example others can mimic with confidence.

Audience
- New assistants (fresh instances) and collaborators joining the workflow.
- Experienced contributors seeking clarity on expectations and best practices.

Scope
- See also:
  - 01-quick-start.md for the loop and scripts
  - 02-troubleshooting.md for fixes and examples
- Keep mechanics in 01/02; this file captures values, style, and intent.
- Workflow principles (clipboard-first, peek → patch → apply).
- Coding philosophy (clarity, testability, accessibility, subtle animations).
- Style guidelines (names, comments, doc quality).
- Testing philosophy (tests as usage docs).
- Expected assistant behavior (what to do, what to avoid).

How to use this doc
- For mechanics and the loop, start with 01-quick-start.md.
- For common issues and fixes, see 02-troubleshooting.md.
- This doc is values and standards: what “good” means here.
- Keep prose concise; prefer bullets; aim for clarity over volume.

Assistant first reply (template)
- “Please run sharefiles in this repo and paste the snapshot. Then run sharefiles in your project repo and paste that. I’ll request a generous peek (±30–200 lines or full sections) of the exact lines I’ll edit, then return a unified diff with hunks listed in descending line order per file. I’ll keep changes scoped to the peek, avoid surprises, and iterate until green.”

Guiding principles (non-negotiable)
1) Safety and clarity first
   - One action per step. No surprises. If anything is unclear, ask.
   - All changes must be intentional and reviewable. Small, explicit diffs only.
2) Peek before patch
   - Always request a precise, numbered peek (nl -ba + sed) of the exact lines you will edit—right before drafting a diff.
   - Do not guess file contents or rely on memory. Drift happens; peeking prevents failure.
3) Strict descending diffs
   - Patch hunks must apply bottom-to-top in a file. This minimizes offset churn mid-apply.
   - If a patch fails, re-peek the smallest necessary range and rebase precisely.
4) Minimal surface area, maximal signal
   - Make the smallest change that achieves the goal, clearly and cleanly.
   - Avoid “drive-by” edits, renames, or opinionated churn unless asked.
5) Tests as usage docs
   - Unit tests should demonstrate expected use patterns and act as canonical examples.
   - Prioritize clarity, naming, and narrative value over raw test count.
6) Names must be meaningful
   - Types, methods, variables, and tests should read like plain English.
   - Favor explicitness (e.g., engineFactory, voicesProvider) over ambiguity.
7) Accessibility is first-class
   - Every interactive element must be discoverable by VoiceOver with sensible labels/hints.
   - Hide decorative elements from accessibility to reduce noise.
   - Prefer defaults where they do the right thing; add modifiers only where needed.
8) Subtle, purposeful animations
   - Motion should aid comprehension (e.g., row added/removed), not distract.
   - Respect platform defaults and reduce motion settings implicitly.
9) Dependency Injection (DI), seam-friendly design
   - Pass dependencies in (providers, factories) instead of hardcoding them.
   - This improves testability, reuse, and reader understanding.
10) Honest scope boundaries
   - If something is out of scope (e.g., i18n not requested), don’t add it.
   - Ask before expanding scope.

Workflow: clipboard-first cadence
- Reference: 00-overview.md and 01-quick-start.md.
- Loop:
  1) Request minimal peeks for exact lines you’ll touch.
  2) Return a unified diff (single file unless we just peeked all touched files).
  3) Operator applies patch; build/test; paste logs back.
  4) Iterate until green.
- Patches:
  - Unified diff only, fenced block, ends with a newline.
  - Descending order within each file.
  - New files: use --- /dev/null and +++ b/... with a full body hunk.

Coding style (Swift/SwiftUI)
- Concurrency and actors
  - Respect actor isolation. If a dependency is MainActor (e.g., SystemVoicesCache.all()), ensure callers are @MainActor too.
  - Use Task and await responsibly; avoid nesting complex async flows inline.
- Dependency injection
  - Provide small seams for engines/providers: e.g., engineFactory: () -> RealVoiceIO, voicesProvider: SystemVoicesProvider.
  - Default-construct in init for production; allow tests to inject fakes.
- View structure
  - Extract small subviews for clarity (ActionRowView, GlobalAdjustmentsView, etc.).
  - Keep state local and explicit via @State and bindings.
  - Use contentShape and simple gestures judiciously.
- Accessibility
  - Add accessibilityLabel/accessibilityHint sparingly where defaults are insufficient.
  - accessibilityHidden(true) for purely decorative elements (e.g., chevrons).
  - Consider accessibilityLiveRegion(.polite) for frequently updated status text.
- Animations
  - Favor subtle .easeInOut for structural changes (List insert/remove).
  - Avoid complex custom transitions unless they materially improve comprehension.
- Naming and comments
  - Doc comments where readers land most (public inits, important private flows).
  - Inline comments should explain the “why”, not restate the “what”.
  - Keep file headers and section markers consistent and scannable.

Documentation style
- Be concise but complete. Prefer short paragraphs and bullet lists.
- Use “What/Why/How/Notes” pattern for changes or non-trivial code paths.
- When in doubt, add a brief doc comment—preferably with a one-line summary and a couple of short bullets.
- Code fences in docs (for this workflow):
  - In **repo markdown that might be pasted back into chat or nested inside other fences**, use `~~~` code fences
    (for example, `~~~swift`, `~~~bash`) instead of three backticks.
  - Avoid writing literal three-backtick fences inside these docs; nested triple-backticks are fragile and often
    get mangled by the chat UI and clipboard, which then breaks patches.
  - In **chat** and in generated patches, the assistant still uses conventional three-backtick fences so you can
    copy/paste and apply diffs. The `~~~` rule is specifically for files in the repo that are meant to be copied
    back into chat or nested inside other fenced blocks.


Tests: philosophy and practice
- Tests are example-driven documentation
  - Showcase the intended usage of seams and APIs.
  - Prefer fakes for external dependencies (e.g., FakeVoicesProvider).
  - Keep tests fast and deterministic.
- What to test
  - Pure helpers and math (e.g., ChorusMath).
  - View model logic or view seams (via ViewInspector for SwiftUI).
  - Accessibility contract: key elements have identifiers and sensible labels/hints.
  - Sorting/selection/seeding that defines UX behavior.
- What not to test
  - Fragile layout details or pixel-perfect UI unless explicitly requested.
  - Private implementation details that don’t change observable behavior.
- Tools
  - Prefer ViewInspector for SwiftUI unit tests (test-only dependency).
  - Avoid heavy UI automation unless necessary (sample app + XCUITests is optional, not default).

Commit messages
- Keep subject under 80 characters.
- Use clear, high-signal verbs: “UI: …”, “Core: …”, “Tests: …”.
- Group related changes; avoid “mixed bag” commits.

Assistant etiquette (how to work with the operator)
- Before patching:
  - Ask for specific peeks, grouped into one block, covering only what you’ll change.
  - Confirm scope and intention in one or two sentences.
- When patching:
  - Descending order hunks.
  - Single file per patch unless we just peeked multiple files explicitly.
  - No speculative edits or refactors.
- After patching:
  - If apply fails, request a tiny re-peek and rebase. Don’t guess.
  - If build/test fails, propose minimal steps to fix, with rationale.
- Tone:
  - Be precise, brief, and take responsibility for mistakes (rebasing, omissions).
  - Offer options but recommend one path (“best guess”) when the operator is undecided.

Accessibility standards (app-store quality baseline)
- Every actionable element:
  - Is reachable via VoiceOver
  - Has a clear role and label; add a hint when purpose isn’t obvious
  - Decorative elements are hidden from a11y
- Lists:
  - Rows should read coherently as a single actionable unit (if appropriate)
  - Swipe actions should have clear labels
- Dynamic content:
  - Consider polite live regions for status updates (e.g., elapsed time)
- Minimizing verbosity:
  - Use defaults where they suffice; add labels/hints only where needed
  - Keep visual minimalism; add accessibility semantics invisibly when possible

Animations (tasteful and accessible)
- Use subtle transitions for structural changes (insert/remove).
- Avoid gratuitous motion. Lean on default system timings and curves.
- Don’t block interaction with animation sequences.

When to ask questions
- Ambiguity: naming decisions, scope expansions, or behavior tradeoffs.
- Risk: changes that may affect multiple areas or break existing contracts.
- Process: when lag or confusion creeps in, propose a checkpoint/commit.

Anti-patterns to avoid
- Patching without a fresh peek.
- Multi-file diffs without peeking all changed files in one request.
- Guessing line numbers or text content.
- Large, sweeping changes (renames, refactors) unless explicitly requested.
- Over-animating or over-instrumenting accessibility.
- Test code that obscures behavior with cleverness over clarity.

Practical checklists

1) Before a change
- [ ] What is the smallest change that achieves the goal?
- [ ] Which lines will I touch? Request a peek for those ranges.
- [ ] Will I need new seams for testability (DI)? Keep them small and explicit.
- [ ] Will this require new identifiers for a11y tests?

2) While editing
- [ ] Descending order hunks
- [ ] No formatting churn
- [ ] No scope creep (ask if expansion is useful)
- [ ] Add doc comments where readers land most

3) After applying
- [ ] Build/test logs reviewed
- [ ] If failed, request tiny re-peek, rebase precisely
- [ ] Propose a short (<80 chars) commit message when green

Design patterns we favor
- DI with small factories/providers (clarity > abstraction for its own sake)
- Composition over inheritance in SwiftUI (small views, bindings)
- Actor isolation awareness with explicit @MainActor where needed
- Pure helper types for math/formatting with direct unit tests
- Clearly labeled accessibility seams; unobtrusive visual footprint

Example: a11y and DI seam done right (pseudo)
Note: Examples are illustrative and stack-agnostic. Adapt patterns to your language/tooling.

```swift
struct ChorusLabView: View {
    let voicesProvider: any SystemVoicesProvider
    let engineFactory: () -> RealVoiceIO
    // ...
    var body: some View {
        List {
            // ...
        }
        .accessibilityIdentifier("vk.voicesList")
    }
}
```
Key notes:
- Inject both the provider and factory; default them in init for production.
- Keep identifiers invisible to users; they’re for tests and clarity.
- Add doc comments to the init describing the seams.

Example: tests as usage docs (pseudo)
```swift
final class AccessibilitySmokeTests: XCTestCase {
    @MainActor
    func testKeyControls() throws {
        let view = ChorusLabView(
            voicesProvider: FakeProvider([]),
            engineFactory: { RealVoiceIO() }
        )
        let sut = try view.inspect()
        XCTAssertNoThrow(try sut.find(viewWithAccessibilityIdentifier: "vk.add"))
        XCTAssertNoThrow(try sut.find(viewWithAccessibilityIdentifier: "vk.playStop"))
        // ...
    }
}
```
Key notes:
- Tests name what they prove; assertions read like documentation.
- Fakes and identifiers make this deterministic and readable.

What success looks like
- A fresh assistant can read these docs and immediately produce:
  - Precise peek requests
  - Clean, descending diffs that apply
  - Small, obvious improvements with clear rationale
  - Tests that serve as documentation and improve confidence
- The repo feels coherent: coding style, accessibility, and tests reflect care and consistency.

Open invitations (what we welcome)
- Suggestions to improve ergonomics or readability that don’t increase risk.
- Better doc comments or examples that make usage clearer.
- Pragmatic, measurable a11y improvements that don’t alter visuals.

Out of scope by default
- i18n work unless explicitly requested.
- Heavy refactors, renames across the tree without a dedicated step.
- UI automation or sample app targets unless needed.

Final note
- If you’re unsure, propose two options and recommend one. Keep the operator’s effort low: one peek, one patch, one test run. Small wins add up; brilliance emerges from consistent, careful steps.
