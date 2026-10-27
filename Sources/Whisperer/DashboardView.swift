import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openWindow) private var openWindow
    @State private var selection: DashboardSection = .session
    @State private var transcriptSearch = ""

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            ZStack {
                WhispererTheme.canvas.ignoresSafeArea()
                switch selection {
                case .session: sessionPage
                case .transcript: transcriptPage
                case .settings: settingsPage
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 980, minHeight: 680)
        .onChange(of: model.overlayVisible) { _, isVisible in
            if isVisible { openWindow(id: "overlay") }
        }
    }

    private var sidebar: some View {
        List(DashboardSection.allCases, selection: $selection) { section in
            Label(section.title, systemImage: section.icon).tag(section)
        }
        .navigationTitle("Whisperer")
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 10) {
                Divider()
                HStack(spacing: 9) {
                    LiveDot(isActive: model.isCapturing)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.status.rawValue).font(.caption.weight(.semibold))
                        Text(model.isCapturing ? "Microphone capture active" : "Capture is off")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(14)
        }
    }

    private var sessionPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                pageHeader(eyebrow: "MEETING COPILOT", title: model.customerName.isEmpty ? "New session" : model.customerName, subtitle: "Live transcription and private, stable speaking cues.") {
                    StatusPill(status: model.status)
                }
                if let error = model.lastError {
                    NoticeBanner(message: error, tone: .warning) { model.lastError = nil }
                }
                sessionHero
                HStack(alignment: .top, spacing: 16) {
                    captureCard
                    readinessCard
                }
                latestTranscriptCard
            }
            .padding(30)
            .frame(maxWidth: 1080, alignment: .leading)
        }
    }

    private var sessionHero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 20) {
                ZStack {
                    Circle().fill(WhispererTheme.accent.opacity(0.14))
                    Image(systemName: model.isCapturing ? "waveform" : "mic")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(WhispererTheme.accent)
                        .symbolEffect(.variableColor.iterative, isActive: model.isCapturing)
                }
                .frame(width: 58, height: 58)
                VStack(alignment: .leading, spacing: 5) {
                    Text(model.isCapturing ? "Whisperer is listening" : "Ready when you are").font(.title2.weight(.semibold))
                    Text(model.isCapturing ? "Speak naturally. Final transcript turns create cues automatically." : "Confirm consent, then start a private session.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if model.sessionStartedAt != nil {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(model.formattedDuration(at: context.date))
                            .font(.system(.title3, design: .monospaced, weight: .medium))
                            .contentTransition(.numericText())
                    }
                }
            }
            Divider()
            HStack(spacing: 12) {
                Toggle(isOn: $model.consentConfirmed) {
                    Label("Participant consent confirmed", systemImage: "checkmark.shield").font(.callout.weight(.medium))
                }
                .toggleStyle(.checkbox)
                .disabled(model.isCapturing)
                Spacer()
                Button {
                    model.overlayVisible = true
                    openWindow(id: "overlay")
                } label: { Label("Teleprompter", systemImage: "rectangle.inset.filled") }
                if model.isCapturing || model.status == .paused {
                    Button(model.status == .paused ? "Resume" : "Pause", systemImage: model.status == .paused ? "play.fill" : "pause.fill") { model.togglePause() }
                    Button("Stop", systemImage: "stop.fill", role: .destructive) { model.stopSession() }
                } else {
                    Button("Start session", systemImage: "waveform") {
                        model.startSession()
                        if model.overlayVisible { openWindow(id: "overlay") }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(WhispererTheme.accent)
                    .disabled(!model.canStart)
                    .keyboardShortcut(.return, modifiers: .command)
                }
            }
        }
        .whispererCard(prominence: .hero)
    }

    private var captureCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeading("Capture health", icon: "waveform.path.ecg")
            LevelMeter(channel: model.microphone)
            LevelMeter(channel: model.incomingAudio)
            Text("System audio capture is planned; microphone transcription is live today.").font(.caption).foregroundStyle(.tertiary)
        }
        .whispererCard().frame(maxWidth: .infinity, alignment: .leading)
    }

    private var readinessCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading("Production readiness", icon: "checkmark.seal")
            ReadinessRow(title: "Microphone transcription", ready: model.microphone.isAvailable)
            ReadinessRow(title: "Claude cue generation", ready: model.hasAnthropicKey, actionTitle: model.hasAnthropicKey ? nil : "Configure") { selection = .settings }
            ReadinessRow(title: "Privacy reminder", ready: !model.showPrivacyWarning)
        }
        .whispererCard().frame(maxWidth: .infinity, alignment: .leading)
    }

    private var latestTranscriptCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeading("Latest transcript", icon: "text.bubble")
                Spacer()
                Button("View all") { selection = .transcript }.buttonStyle(.plain).foregroundStyle(WhispererTheme.accent)
            }
            if model.transcript.isEmpty {
                ContentUnavailableView("No conversation yet", systemImage: "quote.bubble", description: Text("Transcript turns appear here as you speak."))
                    .frame(maxWidth: .infinity, minHeight: 130)
            } else {
                ForEach(model.transcript.suffix(3)) { TranscriptRow(turn: $0) }
            }
        }
        .whispererCard()
    }

    private var transcriptPage: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                pageHeader(eyebrow: "SESSION RECORD", title: "Transcript", subtitle: "Search, copy, or export the current conversation.") { EmptyView() }
                Button("Copy", systemImage: "doc.on.doc") { model.copyTranscript() }.disabled(model.transcript.isEmpty)
                Button("Export…", systemImage: "square.and.arrow.up") { model.exportTranscript() }.disabled(model.transcript.isEmpty)
                Menu {
                    Button("Clear session", systemImage: "trash", role: .destructive) { model.clearSession() }
                } label: { Image(systemName: "ellipsis.circle") }
                .menuStyle(.borderlessButton)
            }
            .padding(30)
            Divider().opacity(0.6)
            if model.transcript.isEmpty {
                ContentUnavailableView("No transcript", systemImage: "text.bubble", description: Text("Start a session and speak to create the transcript."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredTranscript) { turn in
                            TranscriptRow(turn: turn).padding(.vertical, 13)
                            Divider().opacity(0.45)
                        }
                    }
                    .padding(.horizontal, 30).padding(.bottom, 30)
                }
                .searchable(text: $transcriptSearch, prompt: "Search transcript")
            }
        }
    }

    private var settingsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                pageHeader(eyebrow: "PREFERENCES", title: "Settings", subtitle: "Credentials stay in your Keychain. Capture always requires explicit consent.") { EmptyView() }
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeading("AI cue generation", icon: "sparkles")
                    Text("Use your Anthropic API key to generate structured Say Now, Continue, and Ask Next cues with Claude Haiku.").foregroundStyle(.secondary)
                    HStack {
                        SecureField(model.hasAnthropicKey ? "Anthropic key saved" : "Anthropic API key", text: $model.anthropicKeyInput).textFieldStyle(.roundedBorder)
                        Button("Save key") { model.saveAnthropicKey() }.buttonStyle(.borderedProminent)
                            .disabled(model.anthropicKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if model.hasAnthropicKey { Button("Remove", role: .destructive) { model.deleteAnthropicKey() } }
                    }
                    Label(model.hasAnthropicKey ? "Anthropic key securely stored" : "Claude is not configured", systemImage: model.hasAnthropicKey ? "checkmark.circle.fill" : "info.circle")
                        .font(.caption.weight(.medium)).foregroundStyle(model.hasAnthropicKey ? WhispererTheme.accent : .secondary)
                }
                .whispererCard()
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeading("Meeting defaults", icon: "slider.horizontal.3")
                    Picker("Knowledge scope", selection: $model.selectedScope) { ForEach(KnowledgeScope.allCases) { Text($0.rawValue).tag($0) } }
                    TextField("Customer or meeting name", text: $model.customerName).textFieldStyle(.roundedBorder)
                }
                .whispererCard()
                NoticeBanner(message: "Whisperer does not attempt to hide itself from screen sharing. Verify what is being shared before every meeting.", tone: .privacy)
            }
            .padding(30).frame(maxWidth: 980, alignment: .leading)
        }
    }

    private var filteredTranscript: [TranscriptTurn] {
        guard !transcriptSearch.isEmpty else { return model.transcript }
        return model.transcript.filter { $0.text.localizedCaseInsensitiveContains(transcriptSearch) || $0.speaker.localizedCaseInsensitiveContains(transcriptSearch) }
    }

    private func pageHeader<Accessory: View>(eyebrow: String, title: String, subtitle: String, @ViewBuilder accessory: () -> Accessory) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text(eyebrow).font(.system(size: 10, weight: .bold)).tracking(1.3).foregroundStyle(WhispererTheme.accent)
                Text(title).font(.system(size: 32, weight: .bold, design: .rounded)).tracking(-0.7)
                Text(subtitle).font(.callout).foregroundStyle(.secondary)
            }
            Spacer()
            accessory().padding(.top, 8)
        }
    }
}

private enum DashboardSection: String, CaseIterable, Identifiable {
    case session, transcript, settings
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var icon: String {
        switch self { case .session: "waveform"; case .transcript: "text.bubble"; case .settings: "gearshape" }
    }
}

private struct TranscriptRow: View {
    let turn: TranscriptTurn
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle().fill(turn.isFinal ? WhispererTheme.accent.opacity(0.18) : Color.secondary.opacity(0.12))
                .overlay(Text(turn.speaker.prefix(1)).font(.caption.bold()).foregroundStyle(turn.isFinal ? WhispererTheme.accent : .secondary))
                .frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(turn.speaker).font(.caption.weight(.semibold))
                    Text(turn.timestamp, style: .time).font(.caption2).foregroundStyle(.tertiary)
                    if !turn.isFinal { Text("LIVE").font(.system(size: 9, weight: .bold)).foregroundStyle(WhispererTheme.warning) }
                }
                Text(turn.text).font(.body).textSelection(.enabled)
            }
        }
    }
}
