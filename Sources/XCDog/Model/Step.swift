import Foundation
import XCLogParser

struct Step {
    var id: String
    var buildIdentifier: String
    var targetIdentifier: String
    var title: String
    var signature: String
    var type: String
    var architecture: String
    var documentURL: String
    var startTimestamp: Date
    var endTimestamp: Date
    var startTimestampMicroseconds: Double
    var endTimestampMicroseconds: Double
    var duration: Double
    var warningCount: Int32
    var errorCount: Int32
    var fetchedFromCache: Bool
    var day: Date?

    init(buildStep: BuildStep, buildIdentifier: String, targetIdentifier: String) {
        self.id = buildStep.identifier
        self.buildIdentifier = buildIdentifier
        self.targetIdentifier = targetIdentifier
        self.title = buildStep.title
        self.signature = buildStep.signature
        self.type = buildStep.detailStepType.rawValue
        self.architecture = buildStep.architecture
        self.documentURL = buildStep.documentURL
        self.startTimestamp = Date(timeIntervalSince1970: buildStep.startTimestamp)
        self.endTimestamp = Date(timeIntervalSince1970: buildStep.endTimestamp)
        self.startTimestampMicroseconds = buildStep.startTimestamp
        self.endTimestampMicroseconds = buildStep.endTimestamp
        self.duration = buildStep.duration
        self.warningCount = Int32(buildStep.warningCount)
        self.errorCount = Int32(buildStep.errorCount)
        self.fetchedFromCache = buildStep.fetchedFromCache
    }
}
