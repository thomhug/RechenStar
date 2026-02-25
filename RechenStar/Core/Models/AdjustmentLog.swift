import Foundation
import SwiftData

@Model
final class AdjustmentLog {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var summary: String = ""
    var user: User?

    init(summary: String) {
        self.summary = summary
    }
}
