import Foundation

enum EnvironmentVariable {
    static var XCODE_BUILD_NUMBER_KEY = "XCODE_PRODUCT_BUILD_VERSION"
    static var XCODE_VERSION_KEY = "XCODE_VERSION_ACTUAL"
}

class XcodeFactsFetcher {
    private let environmentContext: [String: String]
    
    init() {
        self.environmentContext = ProcessInfo.processInfo.environment
    }

    func fetch() -> XcodeVersion? {
        guard let buildNumber = environmentContext[EnvironmentVariable.XCODE_BUILD_NUMBER_KEY],
            let version = environmentContext[EnvironmentVariable.XCODE_VERSION_KEY] else {
            return nil
        }
        return XcodeVersion(buildNumber: buildNumber, version: version)
    }
}
