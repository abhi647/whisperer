import SwiftUI

struct OverlayView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                StatusPill(status: model.status)
                Spacer()
                if model.queueCount > 0 {
                    Label("\(model.queueCount) next", systemImage: "rectangle.stack")
                        .font(.caption)
                        .foregroundStyle(WhispererTheme.secondary)
                }
                Button {
                    model.togglePause()
                } label: {
                    Image(systemName: model.status == .paused ? "play.fill" : "pause.fill")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(model.status == .paused ? "Resume capture" : "Pause capture")
                Button {
                    model.overlayVisible = false
                } label: {
                    Image(systemName: "eye.slash")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Hide teleprompter")
            }

            if model.showPrivacyWarning {
                Label("Privacy is not verified on a single display. Hide the overlay before full-display sharing.", systemImage: "exclamationmark.shield")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WhispererTheme.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let cue = model.activeCue {
                Text("SAY NOW")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(WhispererTheme.accent)

                Text(cue.sayNow)
                    .font(.system(size: model.focusMode ? 30 : 27, weight: .semibold))
                    .foregroundStyle(WhispererTheme.primary)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)

                if !model.focusMode {
                    if model.expanded {
                        Divider().overlay(WhispererTheme.stroke)
                        Text("CONTINUE")
                            .font(.system(size: 11, weight: .bold)).tracking(1)
                            .foregroundStyle(WhispererTheme.secondary)
                        ForEach(cue.continuation, id: \.self) { beat in
                            Label(beat, systemImage: "minus")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(WhispererTheme.primary)
                        }

                        Text("ASK NEXT")
                            .font(.system(size: 11, weight: .bold)).tracking(1)
                            .foregroundStyle(WhispererTheme.accent)
                            .padding(.top, 4)
                        Text(cue.askNext)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(WhispererTheme.primary)
                    }

                    HStack {
                        Button(model.expanded ? "Less" : "Continue") {
                            model.expanded.toggle()
                        }
                        if model.queueCount > 0 {
                            Button("Next") { model.nextCue() }
                        }
                        Spacer()
                        Button("Incorrect") { model.markIncorrect() }
                            .foregroundStyle(WhispererTheme.warning)
                    }
                    .buttonStyle(.borderless)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(model.status == .paused ? "Capture paused" : "Listening for a question")
                        .font(.title2.weight(.semibold))
                    Text("Your next speaking cue will stay fixed here until you advance it.")
                        .foregroundStyle(WhispererTheme.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
            }
        }
        .padding(20)
        .frame(minWidth: 420, idealWidth: 500, maxWidth: 540, alignment: .topLeading)
        .background(WhispererTheme.background.opacity(0.98))
        .foregroundStyle(WhispererTheme.primary)
    }
}
