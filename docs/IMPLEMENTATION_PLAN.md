# PRD review and implementation plan

## Product assessment

The product definition is unusually strong on interaction intent, privacy, source integrity, and acceptance behaviour. It correctly separates the latency-sensitive speaking path from optional visual analysis and post-call work.

The principal implementation risk is not the SwiftUI shell. It is the combination of system-audio routing, streaming latency, card stability, source-grounded generation, and provable screen-sharing privacy. The build should follow the PRD's M1–M6 sequence and keep provider integrations behind replaceable protocols.

Before production use, the following open decisions need explicit resolution:

1. Minimum supported macOS version. The premium build now targets macOS 26+ for native Liquid Glass.
2. Distribution and signing identity: local development, private Developer ID distribution, or Mac App Store.
3. Initial speech-to-text and language-model providers, contractual retention, processing region, and production secret relay.
4. Exact consent acknowledgement and organization policy.
5. Allowed local transcript retention and encryption/key-loss behaviour.
6. What “privacy verified” means for each Zoom, Teams, Meet, display, and sharing combination.
7. An anonymized evaluation corpus for English, Hindi, Dutch, code-switching, claims, and latency.

## Implemented prototype slice

- Native SwiftUI application and menu-bar entry.
- Meeting preparation and explicit consent gate.
- Independent system-audio and microphone health presentation.
- Session states: idle, listening, preparing, ready, paused, privacy warning, unavailable, and stopped.
- Floating teleprompter with the PRD palette and typographic hierarchy.
- Stable active card with deliberate queue advancement.
- Say Now, Continue, Ask Next, Focus-friendly presentation, incorrect-cue feedback, and single-display warning.
- Deterministic simulated question path for UI evaluation without sending data externally.
- Unit coverage for the key “never overwrite a card being read” invariant.

## Milestone plan

### M1 — audio loop

- Define `AudioCapture` with independent system and microphone streams.
- Implement ScreenCaptureKit system audio and AVAudioEngine microphone adapters.
- Add permission/revocation states and real device-route health.
- Persist no raw audio by default.
- Validate Teams, Meet, Zoom, a browser call, AirPods, and mid-call route changes on the target M5 Mac.

### M2 — speaking engine

- Define streaming `TranscriptionProvider` and `CueProvider` protocols.
- Benchmark Deepgram and OpenAI with the same multilingual corpus before choosing defaults.
- Add question finality detection, cancellation, latency spans, and provider outage state.
- Add a scoped local knowledge index with source/date/verification metadata.
- Enforce a structured response schema and claim policy before rendering.
- Measure median and P95 from detected question completion to first stable cue.

### M3 — private visual copilot

- Enumerate and explicitly select ScreenCaptureKit sources.
- Use Vision OCR locally and upload only selected, minimized excerpts when visual reasoning is requested.
- Separate observed content from inferred interpretation.
- Detect display topology and move or hide the overlay when safety is unknown.
- Verify privacy from a remote participant's captured view; do not infer safety from local window flags.

### M4 — knowledge and drafts

- Import Markdown, text, PDF, DOCX, and supported JSON exports.
- Encrypt the library, partition every record by scope, and add negative cross-account tests.
- Add editable summaries, commitments, tasks, emails, and CRM drafts with no external mutations.
- Add export, scoped deletion, correction review, provenance, and stale/conflicting claim UI.

### M5/M6 — connectors and pilot

- Add capability-declared connectors only after the live path is independent and resilient.
- Keep every write behind explicit preview and approval.
- Complete accessibility, prompt-injection, provider-failure, privacy, retention, and deletion matrices.
- Sign and notarize only after the real-device acceptance gates pass.

## Definition of “prototype ready”

The current slice is ready for interaction review when it builds and its tests pass in Xcode 26+ on macOS 26+. It is not ready for customer calls. Customer-call readiness requires real-device completion of M1–M4 acceptance scenarios, privacy verification, provider review, and signed distribution.
