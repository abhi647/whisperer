import Foundation

enum SessionStatus: String, CaseIterable, Codable {
    case idle = "Idle"
    case listening = "Listening"
    case preparing = "Preparing"
    case ready = "Ready"
    case paused = "Paused"
    case privacyWarning = "Privacy warning"
    case unavailable = "Unavailable"
    case stopped = "Stopped"
}

enum KnowledgeScope: String, CaseIterable, Identifiable, Codable {
    case general = "General"
    case company = "Seven Billion Analytics"
    case customer = "Customer account"

    var id: String { rawValue }
}

struct Evidence: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var sourceDate: Date
    var scope: KnowledgeScope
    var verified: Bool

    init(id: UUID = UUID(), title: String, sourceDate: Date, scope: KnowledgeScope, verified: Bool) {
        self.id = id
        self.title = title
        self.sourceDate = sourceDate
        self.scope = scope
        self.verified = verified
    }
}

struct CueCard: Identifiable, Equatable, Codable {
    let id: UUID
    var sayNow: String
    var continuation: [String]
    var askNext: String
    var meaning: String?
    var pronunciation: String?
    var evidence: [Evidence]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        sayNow: String,
        continuation: [String],
        askNext: String,
        meaning: String? = nil,
        pronunciation: String? = nil,
        evidence: [Evidence] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.sayNow = sayNow
        self.continuation = continuation
        self.askNext = askNext
        self.meaning = meaning
        self.pronunciation = pronunciation
        self.evidence = evidence
        self.createdAt = createdAt
    }
}

struct TranscriptTurn: Identifiable, Equatable {
    let id = UUID()
    var speaker: String
    var text: String
    var language: String
    var isFinal: Bool
    var timestamp: Date = .now
}

struct AudioChannel: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var level: Double
    var isAvailable: Bool
}
