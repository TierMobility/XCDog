import Foundation

struct BuildMetrics: Codable {
    var buildCategory: BuildCategoryType
    var isCI: Bool
    var totalElapsedBuildTimeMs: Int
    var systemInfo: SystemInfo
    var xcodeVersion: XcodeVersion?
}

struct SystemInfo: Codable {
    var cpuCount: Int
    var cpuModel: String
    var cpuSpeedGhz: Float
    var hostArchitecture: String
    var hostModel: String
    var hostOs: String
    var hostOsFamily: String
    var hostOsVersion: String
    var isVirtual: Bool
    var memoryFreeMb: Double
    var memoryTotalMb: Double
    var swapFreeMb: Double
    var swapTotalMb: Double
    var timezone: String
    var uptimeSeconds: Int
}

enum BuildCategoryType: String, Codable {
    case noop
    case incremental
    case clean
}

struct BuildCategorisation {
    let buildCategory: BuildCategoryType
    let buildCompiledCount: Int
    let targetsCategory: [String: BuildCategoryType]
    let targetsCompiledCount: [String: Int]
}

struct XcodeVersion: Codable {
    var buildNumber: String
    var version: String
}
