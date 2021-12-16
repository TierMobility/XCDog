struct DataDogLog: Codable {
    let hostname: String
    let message: BuildMetrics

    var ddsource = "build-time-tracker"
    var service = "consumer-app-ios-build"
}
