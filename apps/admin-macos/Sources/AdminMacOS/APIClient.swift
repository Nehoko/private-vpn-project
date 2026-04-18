import Foundation

actor APIClient {
    func bootstrap(settings: ConnectionSettings) async throws -> BootstrapResponse {
        try await send(path: "/bootstrap", method: "GET", body: Optional<Data>.none, settings: settings)
    }

    func registerDevice(apnsToken: String, settings: ConnectionSettings) async throws {
        let payload = DeviceRegistration(
            deviceId: Host.current().localizedName ?? UUID().uuidString,
            platform: "macos",
            apnsToken: apnsToken,
            userLabel: Host.current().localizedName
        )
        let body = try JSONEncoder().encode(payload)
        let _: EmptyResponse = try await send(
            path: "/devices/register",
            method: "POST",
            body: body,
            settings: settings
        )
    }

    private func send<T: Decodable>(
        path: String,
        method: String,
        body: Data?,
        settings: ConnectionSettings
    ) async throws -> T {
        guard let baseURL = URL(string: settings.sanitizedBaseURL) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        request.setValue("Bearer \(settings.sanitizedToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}

private struct EmptyResponse: Decodable {}
