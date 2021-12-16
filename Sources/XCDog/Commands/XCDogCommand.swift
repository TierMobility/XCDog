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
    
    @Option(name: [.customLong("buildDir"), .customShort("b")], help: "The value of the Xcode $BUILD_DIR environment variable.")
    public var buildDir: String?
    
    @Option(help: "Timeout")
    var timeout: Int = 30
    
    @Flag(help: "Is running on CI")
    var isCI: Bool = false
    
    mutating func run() throws {
        let start = DispatchTime.now()
        
        let processInfo = ProcessInfo()
        let buildDirectory: String
        if let buildDirectoryValue = buildDir {
            buildDirectory = buildDirectoryValue
        } else if let buildDirectoryValue = processInfo.buildDir {
            buildDirectory = buildDirectoryValue
        } else {
            throw ValidationError(
            """
            A valid --buildDir is required.
            If a $BUILD_DIR environment variable is defined, you can omit --buildDir.
            """)
        }
        
        let hostName = Host.current().localizedName ?? ""
        let url = try LogManager().retrieveXcodeLog(in: buildDirectory, timeout: timeout)
        let metrics = try LogParser.parseFromURL(url, machineName: hostName, isCI: isCI)
        let apiKey = self.apiKey
        let applicationKey = self.applicationKey
        let dataDogInteractor = DataDogInteractor()
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            try await dataDogInteractor.send(metrics: metrics, hostName: "", apiKey: apiKey, applicationKey: applicationKey)
            semaphore.signal()
        }
        semaphore.wait()
        let end = DispatchTime.now()
        
        let timeInterval = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000

        print("Took \(timeInterval)s")
    }
}

extension ProcessInfo {
    var buildDir: String? {
        return ProcessInfo.processInfo.environment["BUILD_DIR"]
    }
}
