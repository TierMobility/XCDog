import Foundation

class LogManager {
    private static let maximumCurrentLogAge: TimeInterval = 2

    private let fileAccessor: FileManagerAccessor = FileManagerAccessor(.default)
    private let dateProvider: () -> Date = Date.init
    private let sleepFunction: (UInt32) -> (UInt32) = sleep
    
    func retrieveXcodeLog(in buildDirectory: String, timeout: Int) throws -> URL{
        // Find all logs in Xcode's build and archive directories.
        let xcodeLogs = findXCActivityLogsInDirectoriesSorted(buildDirectory)
        let mostRecentLog = xcodeLogs.first
        let mostRecentLogDate = mostRecentLog?.modificationDate
        if let mostRecentLog = mostRecentLog,
            let recentLogDate = mostRecentLogDate, dateProvider().timeIntervalSince(recentLogDate) < LogManager.maximumCurrentLogAge {
            return mostRecentLog.url
        }

        // In some cases, Xcode will take a while to write the log (size of the log, CPU usage, etc.).
        // This is a best-effort logic to try and wait up until the amount of seconds specified before timing out.
        var timePassed = 0
        while timePassed < timeout {
            _ = sleepFunction(1)
            timePassed += 1
            if let latestLogURL = try? checkIfNewerLogAppeared(in: buildDirectory, afterDate: mostRecentLogDate) {
                print("Latest log found.")
                return latestLogURL
            }
        }
        throw LogManagerError.noLogFound
    }
    
    private func checkIfNewerLogAppeared(in buildDirectory: String, afterDate: Date?) throws -> URL? {
        // Sort the logs by modification date in order to find the most recent one.
        let sortedLogs = findXCActivityLogsInDirectoriesSorted(buildDirectory)
        // Get the most recent log, if it doesn't exist there's no log in the Xcode folder.
        guard let mostRecentLog = sortedLogs.first else { return nil }
        // If there's no after date to compare to, it means this is the first log, so just return it.
        guard let afterDate = afterDate else { return mostRecentLog.url }
        // If the log we have found is newer that the one we're comparing to, return it.
        if mostRecentLog.modificationDate?.compare(afterDate) == .orderedDescending {
            return mostRecentLog.url
        }
        return nil
    }
    
    private func findXCActivityLogsInDirectoriesSorted(_ buildDirectory: String) -> [FileEntry] {
        let xcodeLogsDirectoryURL = URL.makeBuildLogsDirectory(for: buildDirectory)
        let xcodeArchiveLogsDirectoryURL = URL.makeBuildLogsDirectoryWhenArchiving(for: buildDirectory)

        let buildLogs = (try? findXCActivityLogsInDirectory(xcodeLogsDirectoryURL)) ?? []
        let archiveLogs = (try? findXCActivityLogsInDirectory(xcodeArchiveLogsDirectoryURL)) ?? []
        return (buildLogs + archiveLogs).sorted(by: { (lhs, rhs) -> Bool in
            let lhDate = lhs.modificationDate ?? Date.distantPast
            let rhDate = rhs.modificationDate ?? Date.distantPast
            return lhDate.compare(rhDate) == .orderedDescending
        })
    }

    private func findXCActivityLogsInDirectory(_ url: URL) throws -> [FileEntry] {
        return try fileAccessor.entriesOfDirectory(
            at: url,
            options: .skipsHiddenFiles
        )
        .filter { $0.url.pathExtension == String.xcactivitylog }
    }
}

extension URL {
    
    var modificationDate: Date? {
        return try? resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    static func makeBuildLogsDirectory(for buildDirectory: String) -> URL {
        // When building for debug, BUILD_DIR looks like the following so we have to navigate the Build logs folder:
        // This: /Users/username/Library/Developer/Xcode/DerivedData/Spotify-dndppkxfrrjwnwheckoansdgklfh/Build/Products
        // Becomes: /Users/username/Library/Developer/Xcode/DerivedData/Spotify-dndppkxfrrjwnwheckoansdgklfh/Logs/Build
        return URL(fileURLWithPath: buildDirectory)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Logs")
            .appendingPathComponent("Build")
    }

    static func makeBuildLogsDirectoryWhenArchiving(for buildDirectory: String) -> URL {
        // When archiving, BUILD_DIR looks like the following so we have to navigate the Build logs folder:
        // This: /Users/username/repo-path/build/DerivedData/Build/Intermediates.noindex/ArchiveIntermediates/Spotify/BuildProductsPath
        // Becomes: /Users/username/repo-path/build/DerivedData/Logs/Build
        return URL(fileURLWithPath: buildDirectory)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Logs")
            .appendingPathComponent("Build")
    }
}

extension String {
    static let xcactivitylog = "xcactivitylog"
}

enum LogManagerError: Error {
    case noLogFound
}
