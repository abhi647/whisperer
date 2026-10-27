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

    private var simulationTask: Task<Void, Never>?

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
        beginLevelSimulation()
    }

    func stopSession() {
        simulationTask?.cancel()
        simulationTask = nil
        incomingAudio.level = 0
        microphone.level = 0
        status = .stopped
    }

    func togglePause() {
        if status == .paused {
            status = .listening
            beginLevelSimulation()
        } else if status == .listening || status == .ready || status == .preparing {
            simulationTask?.cancel()
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

    func evaluateDisplayPrivacy() {
        showPrivacyWarning = NSScreen.screens.count < 2
        if showPrivacyWarning { status = .privacyWarning }
    }

    private func beginLevelSimulation() {
        simulationTask?.cancel()
        simulationTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(220))
                guard !Task.isCancelled else { return }
                incomingAudio.level = Double.random(in: 0.18...0.82)
                microphone.level = Double.random(in: 0.08...0.58)
            }
        }
    }
}
