import AVFoundation
import CoreGraphics
import Foundation

enum CaptureAuthorization: Sendable, Equatable {
    case notDetermined
    case denied
    case authorized
}

struct CapturePermissions: Sendable {
    func microphoneStatus() -> CaptureAuthorization {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: .authorized
        case .denied, .restricted: .denied
        case .notDetermined: .notDetermined
        @unknown default: .denied
        }
    }

    func requestMicrophone() async -> CaptureAuthorization {
        guard microphoneStatus() == .notDetermined else { return microphoneStatus() }
        return await AVCaptureDevice.requestAccess(for: .audio) ? .authorized : .denied
    }

    func screenRecordingStatus() -> CaptureAuthorization {
        CGPreflightScreenCaptureAccess() ? .authorized : .notDetermined
    }

    func requestScreenRecording() -> CaptureAuthorization {
        CGRequestScreenCaptureAccess() ? .authorized : .denied
    }
}
