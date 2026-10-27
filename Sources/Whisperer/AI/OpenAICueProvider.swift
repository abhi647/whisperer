import Foundation

protocol CueProvider: Sendable {
    func generateCue(for transcript: String, context: CueContext) async throws -> CueCard
}

struct CueContext: Sendable {
    let customerName: String
    let scope: KnowledgeScope
}

enum CueProviderError: LocalizedError {
    case invalidResponse
    case requestFailed(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The cue service returned an unreadable response."
        case .requestFailed(let status, let message):
            "Cue generation failed (HTTP \(status)): \(message)"
        }
    }
}

struct OpenAICueProvider: CueProvider {
    private let apiKey: String
    private let session: URLSession

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func generateCue(for transcript: String, context: CueContext) async throws -> CueCard {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(ResponseRequest(
            model: "gpt-5-mini",
            input: """
            You are a discreet meeting copilot. Create a short, truthful speaking cue for the user's latest transcript.
            Never invent customer or company facts. Use neutral discovery language when evidence is absent.
            Meeting: \(context.customerName)
            Knowledge scope: \(context.scope.rawValue)
            Transcript: \(transcript)
            """
        ))

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw CueProviderError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(APIErrorEnvelope.self, from: data).error.message) ?? "Unknown service error"
            throw CueProviderError.requestFailed(http.statusCode, message)
        }

        let envelope = try JSONDecoder().decode(ResponseEnvelope.self, from: data)
        guard let json = envelope.output
            .flatMap(\.content)
            .compactMap(\.text)
            .first,
              let payload = json.data(using: .utf8) else {
            throw CueProviderError.invalidResponse
        }
        let cue = try JSONDecoder().decode(CuePayload.self, from: payload)
        return CueCard(
            sayNow: cue.sayNow,
            continuation: cue.continuation,
            askNext: cue.askNext,
            meaning: cue.meaning,
            pronunciation: cue.pronunciation,
            evidence: []
        )
    }
}

private struct ResponseRequest: Encodable {
    let model: String
    let input: String
    let text = TextConfiguration()
}

private struct TextConfiguration: Encodable {
    let format = StructuredFormat()
}

private struct StructuredFormat: Encodable {
    let type = "json_schema"
    let name = "speaking_cue"
    let strict = true
    let schema = CueSchema()
}

private struct CueSchema: Encodable {
    let type = "object"
    let properties: [String: SchemaProperty] = [
        "sayNow": .string,
        "continuation": .stringArray,
        "askNext": .string,
        "meaning": .string,
        "pronunciation": .string
    ]
    let required = ["sayNow", "continuation", "askNext", "meaning", "pronunciation"]
    let additionalProperties = false
}

private struct SchemaProperty: Encodable {
    let type: String
    let items: ItemType?

    static let string = SchemaProperty(type: "string", items: nil)
    static let stringArray = SchemaProperty(type: "array", items: ItemType(type: "string"))
}

private struct ItemType: Encodable { let type: String }

private struct ResponseEnvelope: Decodable {
    let output: [Output]
    struct Output: Decodable { let content: [Content] }
    struct Content: Decodable { let text: String? }
}

private struct CuePayload: Decodable {
    let sayNow: String
    let continuation: [String]
    let askNext: String
    let meaning: String
    let pronunciation: String
}

private struct APIErrorEnvelope: Decodable {
    let error: APIError
    struct APIError: Decodable { let message: String }
}
