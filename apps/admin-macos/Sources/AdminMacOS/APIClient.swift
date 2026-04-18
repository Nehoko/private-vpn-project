import Foundation

actor APIClient {
    func bootstrap(settings: ConnectionSettings) async throws -> BootstrapResponse {
        try await send(path: "/bootstrap", method: "GET", body: Optional<Data>.none, settings: settings)
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

        return try JSONDecoder().decode(T.self, from: data)
    }
}
