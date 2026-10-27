import AVFoundation
import Foundation
import Speech

struct TranscriptionUpdate: Sendable {
    let text: String
    let isFinal: Bool
    let audioLevel: Double
}

enum TranscriptionError: LocalizedError {
    case speechPermissionDenied
    case microphonePermissionDenied
    case recognizerUnavailable
    case microphoneUnavailable

    var errorDescription: String? {
        switch self {
        case .speechPermissionDenied:
            "Speech recognition access is denied. Enable it in System Settings → Privacy & Security → Speech Recognition."
        case .microphonePermissionDenied:
            "Microphone access is denied. Enable it in System Settings → Privacy & Security → Microphone."
        case .recognizerUnavailable:
            "Speech recognition is temporarily unavailable."
        case .microphoneUnavailable:
            "The selected microphone is unavailable."
        }
    }
}

@MainActor
final class SpeechTranscriptionService {
    private let engine = AVAudioEngine()
    private let permissions = CapturePermissions()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var continuation: AsyncThrowingStream<TranscriptionUpdate, Error>.Continuation?

    func start(locale: Locale = .current) async throws -> AsyncThrowingStream<TranscriptionUpdate, Error> {
        stop()

        guard await permissions.requestMicrophone() == .authorized else {
            throw TranscriptionError.microphonePermissionDenied
        }
        guard await Self.requestSpeechAuthorization() == .authorized else {
            throw TranscriptionError.speechPermissionDenied
        }
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw TranscriptionError.recognizerUnavailable
        }

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw TranscriptionError.microphoneUnavailable
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        recognitionRequest = request

        let (stream, streamContinuation) = AsyncThrowingStream<TranscriptionUpdate, Error>.makeStream(
            bufferingPolicy: .bufferingNewest(24)
        )
        continuation = streamContinuation

        recognitionTask = recognizer.recognitionTask(with: request) { @Sendable [weak self] result, error in
            let text = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let text, !text.isEmpty {
                    self.continuation?.yield(TranscriptionUpdate(text: text, isFinal: isFinal, audioLevel: 0))
                }
                if let error {
                    self.continuation?.finish(throwing: error)
                    self.stop()
                }
            }
        }

        input.installTap(onBus: 0, bufferSize: 1_024, format: format) { @Sendable buffer, _ in
            request.append(buffer)
            let level = buffer.normalizedLevel
            streamContinuation.yield(TranscriptionUpdate(text: "", isFinal: false, audioLevel: level))
        }
        engine.prepare()
        try engine.start()
        return stream
    }

    func stop() {
        if engine.isRunning {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        continuation?.finish()
        recognitionRequest = nil
        recognitionTask = nil
        continuation = nil
    }

    nonisolated private static func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        let current = SFSpeechRecognizer.authorizationStatus()
        guard current == .notDetermined else { return current }
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
    }
}

private extension AVAudioPCMBuffer {
    var normalizedLevel: Double {
        guard let channels = floatChannelData, frameLength > 0 else { return 0 }
        let samples = channels[0]
        var sum: Float = 0
        for index in 0..<Int(frameLength) {
            sum += samples[index] * samples[index]
        }
        let rms = sqrt(sum / Float(frameLength))
        let decibels = 20 * log10(max(rms, 0.000_01))
        return min(1, max(0, Double((decibels + 60) / 60)))
    }
}
