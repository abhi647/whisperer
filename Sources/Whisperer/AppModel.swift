import AppKit
import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var status: SessionStatus = .idle
    @Published var activeCue: CueCard?
    @Published var cueQueue: [CueCard] = []
    @Published var transcript: [TranscriptTurn] = []
    @Published var selectedScope: KnowledgeScope = .general
    @Published var customerName = "Unmatched meeting"
    @Published var consentConfirmed = false
    @Published var overlayVisible = false
    @Published var focusMode = false
    @Published var expanded = false
    @Published var showPrivacyWarning = false
    @Published var incomingAudio = AudioChannel(name: "System audio", level: 0, isAvailable: true)
    @Published var microphone = AudioChannel(name: "Mac microphone", level: 0, isAvailable: true)
    @Published var lastError: String?
    @Published var openAIKeyInput = ""
    @Published private(set) var hasOpenAIKey = false

    private let transcriptionService = SpeechTranscriptionService()
    private let keychain = KeychainStore()
    private var microphoneTask: Task<Void, Never>?
    private var partialTranscriptID: UUID?

    init() {
        hasOpenAIKey = ((try? keychain.value(for: .openAIAPIKey)) ?? nil)?.isEmpty == false
    }

    var canStart: Bool { consentConfirmed && status != .listening && status != .preparing }
    var queueCount: Int { cueQueue.count }

    func startSession() {
        guard consentConfirmed else {
            lastError = "Confirm your responsibility for meeting consent before capture starts."
            return
        }
        lastError = nil
        status = .listening
        overlayVisible = true
        evaluateDisplayPrivacy()
        startMicrophoneCapture()
    }

    func stopSession() {
        microphoneTask?.cancel()
        microphoneTask = nil
        transcriptionService.stop()
        incomingAudio.level = 0
        microphone.level = 0
        status = .stopped
    }

    func togglePause() {
        if status == .paused {
            status = .listening
            startMicrophoneCapture()
        } else if status == .listening || status == .ready || status == .preparing {
            microphoneTask?.cancel()
            microphoneTask = nil
            transcriptionService.stop()
            incomingAudio.level = 0
            microphone.level = 0
            status = .paused
        }
    }

    func requestDemoCue() {
        guard status != .paused else { return }
        status = .preparing
        transcript.append(TranscriptTurn(
            speaker: "Customer",
            text: "How would you move SAP data to Snowflake without breaking reporting?",
            language: "English",
            isFinal: true
        ))

        Task {
            try? await Task.sleep(for: .milliseconds(650))
            let cue = CueCard(
                sayNow: "I would start by understanding your current SAP extraction method.\n\nThen I would design incremental updates with validation and recovery.",
                continuation: [
                    "Map the existing data flows and reporting dependencies.",
                    "Agree on freshness requirements and acceptable downtime.",
                    "Validate reconciliation, retries and data quality before cutover."
                ],
                askNext: "Do you need near-real-time reporting, or would scheduled refreshes meet the business need?",
                meaning: "Design the migration around the reporting contract first, then prove that every update can be checked and recovered.",
                pronunciation: "idempotency — eye-dem-POH-tuhn-see",
                evidence: []
            )
            enqueue(cue)
        }
    }

    func enqueue(_ cue: CueCard) {
        if activeCue == nil {
            activeCue = cue
        } else {
            cueQueue.append(cue)
        }
        status = .ready
        overlayVisible = true
    }

    func nextCue() {
        guard !cueQueue.isEmpty else { return }
        activeCue = cueQueue.removeFirst()
        expanded = false
    }

    func markIncorrect() {
        guard let cue = activeCue else { return }
        lastError = "Cue flagged for scoped review: \(cue.sayNow.prefix(48))…"
    }

    func saveOpenAIKey() {
        let key = openAIKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            lastError = "Enter an API key before saving."
            return
        }
        do {
            try keychain.save(key, for: .openAIAPIKey)
            openAIKeyInput = ""
            hasOpenAIKey = true
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func deleteOpenAIKey() {
        do {
            try keychain.delete(.openAIAPIKey)
            openAIKeyInput = ""
            hasOpenAIKey = false
        } catch {
            lastError = error.localizedDescription
        }
    }

    func evaluateDisplayPrivacy() {
        showPrivacyWarning = NSScreen.screens.count < 2
        if showPrivacyWarning { status = .privacyWarning }
    }

    private func startMicrophoneCapture() {
        microphoneTask?.cancel()
        microphoneTask = Task {
            do {
                let updates = try await transcriptionService.start()
                microphone.isAvailable = true
                for try await update in updates {
                    guard !Task.isCancelled else { break }
                    microphone.level = update.audioLevel
                    guard !update.text.isEmpty else { continue }
                    applyTranscript(update)
                }
            } catch {
                microphone.isAvailable = false
                lastError = error.localizedDescription
                status = .unavailable
            }
        }
    }

    private func applyTranscript(_ update: TranscriptionUpdate) {
        if let id = partialTranscriptID,
           let index = transcript.firstIndex(where: { $0.id == id }) {
            transcript[index].text = update.text
            transcript[index].isFinal = update.isFinal
        } else {
            let turn = TranscriptTurn(speaker: "You", text: update.text, language: Locale.current.localizedString(forIdentifier: Locale.current.identifier) ?? "Local", isFinal: update.isFinal)
            transcript.append(turn)
            partialTranscriptID = turn.id
        }

        guard update.isFinal else { return }
        partialTranscriptID = nil
        generateCue(for: update.text)
    }

    private func generateCue(for text: String) {
        guard let apiKey = try? keychain.value(for: .openAIAPIKey), !apiKey.isEmpty else {
            lastError = "Transcript captured. Add an OpenAI API key to generate live cues."
            return
        }
        let provider = OpenAICueProvider(apiKey: apiKey)
        let context = CueContext(customerName: customerName, scope: selectedScope)
        status = .preparing
        Task {
            do {
                enqueue(try await provider.generateCue(for: text, context: context))
                lastError = nil
            } catch {
                lastError = error.localizedDescription
                status = .listening
            }
        }
    }
}
