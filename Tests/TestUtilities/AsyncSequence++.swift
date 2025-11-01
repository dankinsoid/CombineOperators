import Foundation

public extension AsyncSequence {

    func collect() async throws -> [Element] {
        var result: [Element] = []
        for try await element in self {
            result.append(element)
        }
        return result
    }
}
