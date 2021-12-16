import Foundation
import XCLogParser

struct Target {
    public var id: String?
    var buildIdentifier: String
    var name: String
    var startTimestamp: Date
    var endTimestamp: Date
    var startTimestampMicroseconds: Double
    var endTimestampMicroseconds: Double
    var duration: Double
    var warningCount: Int32
    var errorCount: Int32
    var fetchedFromCache: Bool
    var category: String?
    var compiledCount: Int32?
    var compilationEndTimestamp: Date
    var compilationEndTimestampMicroseconds: Double
    var compilationDuration: Double
    var day: Date?
    
    init(buildStep: BuildStep) {
        self.id = buildStep.identifier
        self.buildIdentifier = buildStep.parentIdentifier
        self.name = buildStep.title.replacingOccurrences(of: "Build target ", with: "")
        self.startTimestamp = Date(timeIntervalSince1970: buildStep.startTimestamp)
        self.endTimestamp = Date(timeIntervalSince1970: buildStep.endTimestamp)
        self.startTimestampMicroseconds = buildStep.startTimestamp
        self.endTimestampMicroseconds = buildStep.endTimestamp
        self.duration = buildStep.duration
        self.warningCount = Int32(buildStep.warningCount)
        self.errorCount = Int32(buildStep.errorCount)
        self.fetchedFromCache = buildStep.fetchedFromCache
        self.compilationEndTimestamp = Date(timeIntervalSince1970: buildStep.compilationEndTimestamp)
        self.compilationEndTimestampMicroseconds = buildStep.compilationEndTimestamp
        self.compilationDuration = buildStep.compilationDuration
    }
}
