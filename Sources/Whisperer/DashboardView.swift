import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationSplitView {
            List {
                Label("Meeting", systemImage: "waveform")
                Label("Knowledge", systemImage: "books.vertical")
                Label("Drafts", systemImage: "doc.text")
                Label("Privacy", systemImage: "hand.raised")
            }
            .navigationTitle("Whisperer")
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    if let error = model.lastError {
                        Label(error, systemImage: "exclamationmark.circle")
                            .foregroundStyle(WhispererTheme.warning)
                    }
                    meetingContext
                    credentials
                    captureHealth
                    transcript
                }
                .padding(28)
                .frame(maxWidth: 850, alignment: .leading)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 900, minHeight: 620)
    }

    private var credentials: some View {
        GroupBox("AI cue generation") {
            VStack(alignment: .leading, spacing: 10) {
                Text("The API key is stored in your macOS Keychain and is never written to project files.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    SecureField(model.hasOpenAIKey ? "OpenAI key saved" : "OpenAI API key", text: $model.openAIKeyInput)
                    Button("Save key") { model.saveOpenAIKey() }
                        .disabled(model.openAIKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if model.hasOpenAIKey {
                        Button("Remove", role: .destructive) { model.deleteOpenAIKey() }
                    }
                }
            }
            .padding(8)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Meeting copilot").font(.largeTitle.bold())
                Text("Private speaking cues with explicit capture control.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            StatusPill(status: model.status)
                .padding(.top, 8)
        }
    }

    private var meetingContext: some View {
        GroupBox("Prepare") {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Knowledge scope", selection: $model.selectedScope) {
                    ForEach(KnowledgeScope.allCases) { Text($0.rawValue).tag($0) }
                }
                TextField("Customer or meeting name", text: $model.customerName)
                Toggle("I am responsible for participant consent and authorization", isOn: $model.consentConfirmed)
                HStack {
                    Button("Start session") { model.startSession() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!model.canStart)
                    Button(model.status == .paused ? "Resume" : "Pause") { model.togglePause() }
                        .disabled(model.status == .idle || model.status == .stopped)
                    Button("Stop") { model.stopSession() }
                        .disabled(model.status == .idle || model.status == .stopped)
                    Spacer()
                    Button("Show teleprompter") { model.overlayVisible = true }
                    Button("Simulate customer question") { model.requestDemoCue() }
                        .disabled(model.status == .idle || model.status == .paused)
                }
            }
            .padding(8)
        }
    }

    private var captureHealth: some View {
        GroupBox("Capture health") {
            HStack(spacing: 32) {
                LevelMeter(channel: model.incomingAudio)
                LevelMeter(channel: model.microphone)
            }
            .padding(8)
        }
    }

    private var transcript: some View {
        GroupBox("Live transcript") {
            VStack(alignment: .leading, spacing: 12) {
                if model.transcript.isEmpty {
                    ContentUnavailableView("No transcript yet", systemImage: "text.bubble", description: Text("Final and partial turns will appear here during a session."))
                        .frame(maxWidth: .infinity, minHeight: 130)
                } else {
                    ForEach(model.transcript) { turn in
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(turn.speaker) · \(turn.language)")
                                .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            Text(turn.text)
                        }
                    }
                }
            }
            .padding(8)
        }
    }
}
