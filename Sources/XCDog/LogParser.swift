import Foundation
import XCLogParser

struct LogParser {
    static func parseFromURL(
        _ url: URL,
        machineName: String,
        isCI: Bool
    ) throws -> BuildMetrics {
        let activityLog = try ActivityParser().parseActivityLogInURL(url, redacted: false, withoutBuildSpecificInformation: false)
        let buildSteps = try ParserBuildSteps(machineName: machineName,
                                              omitWarningsDetails: false,
                                              omitNotesDetails: false,
                                              truncLargeIssues: false
        )
            .parse(activityLog: activityLog)
            .flatten()
        
        let buildInfo = buildSteps[0]
        let buildIdentifier = buildInfo.identifier
        
        let targetBuildSteps = buildSteps.filter { $0.type == .target }
        let targets = targetBuildSteps.map { step in
            return Target(buildStep: step)
        }
        let steps = buildSteps.filter { $0.type == .detail && $0.detailStepType != .swiftAggregatedCompilation }

        let detailsBuild = steps.filter { $0.detailStepType != .swiftCompilation }.map {
            return Step(buildStep: $0,
                        buildIdentifier: buildIdentifier,
                        targetIdentifier: $0.parentIdentifier
            )
        }
        let stepsBuild = detailsBuild + parseSwiftSteps(buildSteps: buildSteps, targets: targetBuildSteps, steps: steps, buildIdentifier: buildIdentifier)
        
        let buildCategorisation = parseBuildCategory(
            with: targets,
            steps: stepsBuild.filter { $0.type != "other" && $0.type != "scriptExecution" && $0.type != "copySwiftLibs" }
        )

        
        let systemInfo = try HardwareFactsFetcherImplementation().fetch()
        let xcodeVersion = XcodeFactsFetcher().fetch()
        
        return BuildMetrics(
            buildCategory: buildCategorisation.buildCategory,
            isCI: isCI,
            totalElapsedBuildTimeMs: Int(buildInfo.duration * 1000),
            systemInfo: systemInfo,
            xcodeVersion: xcodeVersion
        )
    }
    
    private static func parseBuildCategory(with targets: [Target], steps: [Step]) -> BuildCategorisation {
        var targetsCompiledCount = [String: Int]()
        // Initialize map with all targets identifiers.
        for target in targets {
            targetsCompiledCount[target.id ?? ""] = 0
        }
        // Compute how many steps were not fetched from cache for each target.
        for step in steps {
            if !step.fetchedFromCache {
                targetsCompiledCount[step.targetIdentifier, default: 0] += 1
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
            case steps.filter { $0.targetIdentifier == target }.count: targetsCategory[target] = .clean
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
    
    private static func parseSwiftSteps(
        buildSteps: [BuildStep],
        targets: [BuildStep],
        steps: [BuildStep],
        buildIdentifier: String
    ) -> [Step] {
        let swiftAggregatedSteps = buildSteps.filter { $0.type == .detail
            && $0.detailStepType == .swiftAggregatedCompilation }

        let swiftAggregatedStepsIds = swiftAggregatedSteps.reduce([String: String]()) {
            dictionary, step -> [String: String] in
            return dictionary.merging(zip([step.identifier], [step.parentIdentifier])) { (_, new) in new }
        }

        let targetsIds = targets.reduce([String: String]()) {
            dictionary, target -> [String: String] in
            return dictionary.merging(zip([target.identifier], [target.identifier])) { (_, new) in new }
        }

        return steps
            .filter { $0.detailStepType == .swiftCompilation }
            .compactMap { step -> Step? in
                var targetId = step.parentIdentifier
                // A swift step can have either a target as a parent or a swiftAggregatedCompilation
                if targetsIds[step.parentIdentifier] == nil {
                    // If the parent is a swiftAggregatedCompilation we use the target id from that parent step
                    guard let swiftTargetId = swiftAggregatedStepsIds[step.parentIdentifier] else {
                        return nil
                    }
                    targetId = swiftTargetId
                }
                return Step(buildStep: step, buildIdentifier: buildIdentifier, targetIdentifier: targetId)

        }
    }
}
