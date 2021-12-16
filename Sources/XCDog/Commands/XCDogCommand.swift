import ArgumentParser
import Foundation
import XCLogParser

struct XCDogCommand: ParsableCommand {
    @Argument(help: "DataDog API key")
    var apiKey: String
    
    @Argument(help: "DataDog application key")
    var applicationKey: String
    
    @Argument(help: "Project name")
    var projectName: String
    
    @Option(help: "Path to .xcworkspace")
    var xcworkspacePath: String = ""
    
    @Option(help: "Path to .xcodeproj")
    var xcodeprojPath: String = ""
    
    @Option(help: "Path to DerivedData")
    var derivedDataPath: String = ""
    
    @Option(help: "Path to LogManifest")
    var logManifestPath: String = ""
    
    @Flag(help: "Is running on CI")
    var isCI: Bool = false
    
    mutating func run() throws {
        let start = DispatchTime.now()
        let options = LogOptions(
            projectName: projectName,
            xcworkspacePath: xcworkspacePath,
            xcodeprojPath: xcodeprojPath,
            derivedDataPath: derivedDataPath,
            logManifestPath: logManifestPath
        )
        let hostName = Host.current().localizedName ?? ""
        let url = try LogFinder().findLatestLogWithLogOptions(options)
        let metrics = try LogParser.parseFromURL(url, machineName: hostName, isCI: isCI)
        let apiKey = self.apiKey
        let applicationKey = self.applicationKey
        let dataDogInteractor = DataDogInteractor()
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            try await dataDogInteractor.send(metrics: metrics, hostName: hostName, apiKey: apiKey, applicationKey: applicationKey)
            semaphore.signal()
        }
        semaphore.wait()
        let end = DispatchTime.now()
        
        let timeInterval = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000
        print("Took \(timeInterval)s")
    }
}
