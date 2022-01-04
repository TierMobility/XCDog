import Foundation

class DataDogInteractor {
    private let url = URL(string: "https://http-intake.logs.datadoghq.eu/api/v2/logs")
    var session = URLSession.shared
    
    func send(metrics: BuildMetrics, hostName: String, apiKey: String, applicationKey: String) async throws -> Bool {
        guard let requestUrl = url else { return false }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(DataDogLog(hostname: hostName, message: metrics))
        request.addValue(apiKey, forHTTPHeaderField: "DD-API-KEY")
        request.addValue(applicationKey, forHTTPHeaderField: "DD-APPLICATION-KEY")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let data = await session.dataTaskAsync(with: request) else { return false }
        
        if let dataString = String(data: data, encoding: .utf8) {
            print("Response data: \(dataString)")
            return true
        }

        return false
    }
}

extension URLSession {
    func dataTaskAsync(with request: URLRequest) async -> Data? {
        await withCheckedContinuation { continuation in
            let task = dataTask(with: request) {(data, response, error) in
                continuation.resume(returning: data)
            }
            task.resume()
        }
    }
}
