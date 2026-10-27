import AppKit
import SwiftUI

@main
struct WhispererApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Whisperer", id: "dashboard") {
            DashboardView()
                .environmentObject(model)
        }
        .defaultSize(width: 980, height: 680)

        Window("Private teleprompter", id: "overlay") {
            OverlayWindowRoot()
                .environmentObject(model)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.topTrailing)
        .defaultSize(width: 500, height: 240)

        MenuBarExtra {
            MenuBarContent(model: model)
        } label: {
            Image(systemName: model.status == .listening ? "waveform.circle.fill" : "waveform.circle")
        }
    }

}

private struct OverlayWindowRoot: View {
    @EnvironmentObject private var model: AppModel
    @State private var window: NSWindow?

    var body: some View {
        OverlayView()
            .background(WindowReader { discoveredWindow in
                window = discoveredWindow
                configure(discoveredWindow)
                if !model.overlayVisible { discoveredWindow.orderOut(nil) }
            })
            .onChange(of: model.overlayVisible) { _, isVisible in
                if isVisible {
                    window?.orderFrontRegardless()
                } else {
                    window?.orderOut(nil)
                }
            }
    }

    private func configure(_ window: NSWindow) {
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.isMovableByWindowBackground = true
        window.hidesOnDeactivate = false
        window.backgroundColor = .clear
    }
}

private struct WindowReader: NSViewRepresentable {
    let onResolve: (NSWindow) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onResolve: onResolve)
    }

    func makeNSView(context: Context) -> NSView {
        let view = WindowReadingView()
        view.onWindowChange = { [weak coordinator = context.coordinator] window in
            coordinator?.resolve(window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onResolve = onResolve
    }

    final class Coordinator {
        var onResolve: (NSWindow) -> Void
        weak var resolvedWindow: NSWindow?

        init(onResolve: @escaping (NSWindow) -> Void) {
            self.onResolve = onResolve
        }

        func resolve(_ window: NSWindow) {
            guard resolvedWindow !== window else { return }
            resolvedWindow = window
            onResolve(window)
        }
    }
}

private final class WindowReadingView: NSView {
    var onWindowChange: ((NSWindow) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window { onWindowChange?(window) }
    }
}

private struct MenuBarContent: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open Whisperer") { openWindow(id: "dashboard") }
        Button("Show teleprompter") {
            model.overlayVisible = true
            openWindow(id: "overlay")
        }
        Divider()
        Button(model.status == .paused ? "Resume capture" : "Pause capture") { model.togglePause() }
            .disabled(model.status == .idle || model.status == .stopped)
        Button("Next cue") { model.nextCue() }.disabled(model.queueCount == 0)
        Button("Hide teleprompter") {
            model.overlayVisible = false
        }
        Divider()
        Button("Quit Whisperer") { NSApp.terminate(nil) }
    }
}
