import Foundation
import XCLogParser

struct LogParser {
    static func parseFromURL(
        _ url: URL,
        machineName: String,
        isCI: Bool
    ) throws -> BuildMetrics {
        let activityLog = try ActivityParser().parseActivityLogInURL(url, redacted: true, withoutBuildSpecificInformation: true)
        let buildSteps = try ParserBuildSteps(machineName: machineName,
                                              omitWarningsDetails: false,
                                              omitNotesDetails: false,
                                              truncLargeIssues: false
        )
            .parse(activityLog: activityLog)
            .flatten()
        
        let build = buildSteps[0]
        
        let targets = buildSteps
        let steps = buildSteps.filter { $0.type == .detail && $0.detailStepType != .swiftAggregatedCompilation }
        
        let categorisation = parseBuildCategory(with: targets, steps: steps)
        let systemInfo = try HardwareFactsFetcherImplementation().fetch()
        let xcodeVersion = XcodeFactsFetcher().fetch()
        
        return BuildMetrics(
            buildCategory: categorisation.buildCategory,
            isCI: isCI,
            totalElapsedBuildTimeMs: Int(build.duration * 1000),
            systemInfo: systemInfo,
            xcodeVersion: xcodeVersion
        )
    }
    
    private static func parseBuildCategory(with targets: [BuildStep], steps: [BuildStep]) -> BuildCategorisation {
        var targetsCompiledCount = [String: Int]()
        
        // Initialize map with all targets identifiers.
        for target in targets {
            targetsCompiledCount[target.identifier] = 0
        }
        // Compute how many steps were not fetched from cache for each target.
        for step in steps {
            if !step.fetchedFromCache {
                targetsCompiledCount[step.parentIdentifier, default: 0] += 1
            }
        }

        // Compute how many steps in total were not fetched from cache.
        let buildCompiledCount = Array<Int>(targetsCompiledCount.values).reduce(0, +)
        // Classify each target based on how many steps were not fetched from cache and how many are actually present.
        var targetsCategory = [String: BuildCategoryType]()
        for (target, filesCompiledCount) in targetsCompiledCount {
            // If the number of steps not fetched from cache in 0, it was a noop build.
            // If the number of steps not fetched from cache is equal to the number of all steps in the target, it was a clean build.
            // If anything in between, it was an incremental build.
            // There's an edge case where some external run script phases don't have any files compiled and are classified
            // as noop, but we're fine with that since further down we classify a clean build if at least 50% of the targets
            // were built cleanly.
            switch filesCompiledCount {
            case 0: targetsCategory[target] = .noop
            case steps.filter { $0.parentIdentifier == target }.count: targetsCategory[target] = .clean
            default: targetsCategory[target] = .incremental
            }
        }

        // If all targets are noop, we categorise the build as noop.
        let isNoopBuild = Array<BuildCategoryType>(targetsCategory.values).allSatisfy { $0 == .noop }
        // If at least 50% of the targets are clean, we categorise the build as clean.
        let isCleanBuild = Array<BuildCategoryType>(targetsCategory.values).filter { $0 == .clean }.count > targets.count / 2
        let buildCategory: BuildCategoryType
        if isCleanBuild {
            buildCategory = .clean
        } else if isNoopBuild {
            buildCategory = .noop
        } else {
            buildCategory = .incremental
        }
        return BuildCategorisation(
            buildCategory: buildCategory,
            buildCompiledCount: buildCompiledCount,
            targetsCategory: targetsCategory,
            targetsCompiledCount: targetsCompiledCount
        )
    }
}
