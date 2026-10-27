# Whisperer

Native macOS prototype for the Discreet Meeting Copilot product definition.

## Current slice

This repository implements a credential-free M1/M2 interaction prototype:

- menu-bar lifecycle and a native meeting dashboard;
- floating, always-on-top teleprompter with compact/focus-friendly content;
- explicit consent, start, pause, stop, hide, and privacy-warning states;
- separate incoming-audio and microphone health presentation;
- stable cue cards: new suggestions queue instead of replacing text being read;
- `Say Now`, progressive `Continue`, and `Ask Next` regions;
- a simulated customer question for product and accessibility testing.

Audio meters and cue generation are intentionally simulated. The app does **not** claim to capture, transcribe, contact a model, or hide itself from screen sharing yet.

## Requirements

- Apple Silicon or Intel Mac
- macOS 14 or newer
- Xcode 15 or newer (Swift 5.9+)

## Run

Open `Package.swift` in Xcode, select the `Whisperer` executable scheme, and run. Or from Terminal on a Mac:

```sh
swift run Whisperer
```

Run unit tests with:

```sh
swift test
```

The prototype requires no API keys and makes no network requests.

### Development console notes

When this Swift Package is run directly from Xcode, macOS may log App Intents
`com.apple.linkd.autoShortcut` connection warnings and a missing main bundle
identifier warning. These do not indicate an application failure. A stable bundle
identifier, entitlements, signing, and App Intents registration belong to the
proper Xcode application target created before microphone and screen-capture work.

## Next engineering milestone

Add replaceable `AudioCapture`, `TranscriptionProvider`, and `CueProvider` protocols. Implement authorized ScreenCaptureKit system-audio capture and AVAudioEngine microphone capture as independent channels, then benchmark streaming transcription before selecting a provider. Do not add real customer capture until consent UX, provider retention terms, and privacy testing are complete.
