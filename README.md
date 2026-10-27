# Whisperer

Native macOS prototype for the Discreet Meeting Copilot product definition.

## Current slice

This repository implements a native M1/M2 development slice:

- menu-bar lifecycle and a native meeting dashboard;
- floating, always-on-top teleprompter with compact/focus-friendly content;
- explicit consent, start, pause, stop, hide, and privacy-warning states;
- live microphone capture, Apple Speech transcription, and separate incoming-audio health presentation;
- optional structured Claude cue generation with the Anthropic API key stored in macOS Keychain;
- stable cue cards: new suggestions queue instead of replacing text being read;
- `Say Now`, progressive `Continue`, and `Ask Next` regions;
- dedicated Session, Transcript, and Settings workspaces;
- searchable transcripts with native copy and plain-text export;
- live session duration, capture readiness, and explicit provider/privacy states;
- a simulated customer question for product and accessibility testing.

The microphone path uses real, permission-gated audio capture and live transcription. When a user explicitly stores an Anthropic API key in the app, final transcript turns can generate structured cues with Claude Haiku. The app still does **not** capture meeting/system audio, ground answers in imported knowledge, or claim to hide itself from screen sharing.

## Requirements

- Apple Silicon or Intel Mac
- macOS 26 or newer
- Xcode 26 or newer (Swift 6.2+)

## Run

Install XcodeGen once with `brew install xcodegen`, then generate the signed app project:

```sh
xcodegen generate
open Whisperer.xcodeproj
```

Choose your development team under **Signing & Capabilities**, select the `Whisperer` scheme, and run. The Swift Package remains available for lightweight development:

```sh
swift run Whisperer
```

Run unit tests with:

```sh
swift test
```

Transcription can run without an API key. AI cues are opt-in and require a user-supplied Anthropic API key, stored in Keychain.

### Development console notes

When this Swift Package is run directly from Xcode, macOS may log App Intents
`com.apple.linkd.autoShortcut` connection warnings and a missing main bundle
identifier warning. These do not indicate an application failure. A stable bundle
identifier, entitlements, signing, and App Intents registration belong to the
proper Xcode application target created before microphone and screen-capture work.

## Next engineering milestone

Add replaceable `AudioCapture`, `TranscriptionProvider`, and `CueProvider` protocols. Implement authorized ScreenCaptureKit system-audio capture and AVAudioEngine microphone capture as independent channels, then benchmark streaming transcription before selecting a provider. Do not add real customer capture until consent UX, provider retention terms, and privacy testing are complete.
