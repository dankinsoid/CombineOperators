import Foundation
import Testing
import CombineOperators

final class Expectation<Value> {
    
    let limit: Int?
    @Locked private(set) var isFinished = false
    @Locked private(set) var currentValues: [Value] = []
    private let stream: AsyncStream<Value>
    private let continuation: AsyncStream<Value>.Continuation
    private var timeoutTask: Task<Void, Error>?

    var values: [Value] {
        get async {
            await stream.reduce(into: []) { $0.append($1) }
        }
    }

    init(
        limit: Int?,
        timeLimit: TimeInterval? = 1,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        self.limit = limit
        (stream, continuation) = AsyncStream<Value>.makeStream()
        if let timeLimit {
            timeoutTask = Task { [weak self] in
                try await Task.sleep(nanoseconds: UInt64(timeLimit * 1_000_000_000))
                Issue.record("Expectation timed out after \(timeLimit) seconds", sourceLocation: sourceLocation)
                self?.finish()
            }
        }
    }

    func fulfill(_ value: Value, sourceLocation: SourceLocation = #_sourceLocation) {
        guard !isFinished else {
            Issue.record("Expectation already fulfilled", sourceLocation: sourceLocation)
            return
        }
        currentValues.append(value)
        continuation.yield(value)
        if let limit, currentValues.count >= limit {
            finish()
        }
    }
    
    func finish(sourceLocation: SourceLocation = #_sourceLocation) {
        guard !isFinished else {
            Issue.record("Expectation already finished", sourceLocation: sourceLocation)
            return
        }
        timeoutTask?.cancel()
        isFinished = true
        continuation.finish()
    }
}
