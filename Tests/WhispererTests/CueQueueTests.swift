import XCTest
@testable import Whisperer

@MainActor
final class CueQueueTests: XCTestCase {
    func testNewCueQueuesWithoutReplacingActiveCue() {
        let model = AppModel()
        let first = CueCard(sayNow: "First", continuation: [], askNext: "First question?")
        let second = CueCard(sayNow: "Second", continuation: [], askNext: "Second question?")

        model.enqueue(first)
        model.enqueue(second)

        XCTAssertEqual(model.activeCue, first)
        XCTAssertEqual(model.cueQueue, [second])
    }

    func testNextCueRequiresDeliberateAdvance() {
        let model = AppModel()
        let first = CueCard(sayNow: "First", continuation: [], askNext: "First question?")
        let second = CueCard(sayNow: "Second", continuation: [], askNext: "Second question?")
        model.enqueue(first)
        model.enqueue(second)

        model.nextCue()

        XCTAssertEqual(model.activeCue, second)
        XCTAssertTrue(model.cueQueue.isEmpty)
    }
}
