import Foundation
import Combine

enum APIError: Error, LocalizedError {
    case invalidURL
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .httpError(let code, _): return "HTTP \(code)"
        case .decodingError(let e): return e.localizedDescription
        case .unauthorized: return "Unauthorized"
        }
    }
}

@MainActor
final class APIClient: ObservableObject {
    static let shared = APIClient()

    private let session: URLSession
    private let baseURL: String
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: str) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: str) { return date }
            // Fallback: timezone-naive ISO 8601 (Motor/MongoDB returns naive datetimes)
            formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
            if let date = formatter.date(from: str) { return date }
            formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime, .withFractionalSeconds]
            if let date = formatter.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(str)")
        }
        return d
    }()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    init(session: URLSession = .shared, baseURL: String = Constants.API.baseURL) {
        self.session = session
        self.baseURL = baseURL
    }

    func get<T: Decodable>(_ path: String) async throws -> T {
        try await request(method: "GET", path: path, body: nil as String?)
    }

    func post<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
        try await request(method: "POST", path: path, body: body)
    }

    func patch<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
        try await request(method: "PATCH", path: path, body: body)
    }

    func put<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
        try await request(method: "PUT", path: path, body: body)
    }

    func delete(_ path: String) async throws {
        let _: EmptyResponse = try await request(method: "DELETE", path: path, body: nil as String?)
    }

    func delete<T: Decodable>(_ path: String) async throws -> T {
        try await request(method: "DELETE", path: path, body: nil as String?)
    }

    private func request<Body: Encodable, T: Decodable>(
        method: String, path: String, body: Body?
    ) async throws -> T {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = KeychainHelper.load(forKey: Constants.Keychain.accessToken) {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidURL }

        switch http.statusCode {
        case 200...299:
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 401:
            throw APIError.unauthorized
        default:
            throw APIError.httpError(statusCode: http.statusCode, data: data)
        }
    }
}

private struct EmptyResponse: Codable {}
