import AVFoundation
import Darwin
import Foundation

struct AudioFrame: @unchecked Sendable {
    let buffer: AVAudioPCMBuffer
    let capturedAt: ContinuousClock.Instant
}

enum AudioCaptureError: LocalizedError {
    case permissionDenied
    case unavailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied: "Microphone access is denied. Enable it in System Settings → Privacy & Security → Microphone."
        case .unavailable: "The selected microphone is unavailable."
        }
    }
}

@MainActor
final class MicrophoneCaptureService {
    private let engine = AVAudioEngine()
    private let permissions = CapturePermissions()
    private var continuation: AsyncStream<AudioFrame>.Continuation?

    private(set) var isRunning = false

    func start() async throws -> AsyncStream<AudioFrame> {
        guard await permissions.requestMicrophone() == .authorized else {
            throw AudioCaptureError.permissionDenied
        }

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw AudioCaptureError.unavailable
        }

        let (stream, frameContinuation) = AsyncStream<AudioFrame>.makeStream(
            bufferingPolicy: .bufferingNewest(12)
        )
        continuation = frameContinuation
        input.installTap(onBus: 0, bufferSize: 1_024, format: format) { buffer, _ in
            guard let copy = buffer.deepCopy() else { return }
            frameContinuation.yield(AudioFrame(buffer: copy, capturedAt: .now))
        }
        engine.prepare()
        try engine.start()
        isRunning = true
        return stream
    }

    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        continuation?.finish()
        continuation = nil
        isRunning = false
    }
}

private extension AVAudioPCMBuffer {
    func deepCopy() -> AVAudioPCMBuffer? {
        guard let copy = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameLength) else { return nil }
        copy.frameLength = frameLength
        let source = UnsafeMutableAudioBufferListPointer(mutableAudioBufferList)
        let destination = UnsafeMutableAudioBufferListPointer(copy.mutableAudioBufferList)
        for index in 0..<min(source.count, destination.count) {
            guard let sourceData = source[index].mData, let destinationData = destination[index].mData else { continue }
            memcpy(destinationData, sourceData, Int(source[index].mDataByteSize))
            destination[index].mDataByteSize = source[index].mDataByteSize
        }
        return copy
    }
}
