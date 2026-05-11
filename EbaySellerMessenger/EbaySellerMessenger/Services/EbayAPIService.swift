import Foundation

final class EbayAPIService {
    static let shared = EbayAPIService()
    private init() {}

    private let auth = EbayAuthService.shared
    private var baseURL: String { auth.environment.apiBaseURL }

    private lazy var decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = Date.fromEbayString(string) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(string)")
        }
        return d
    }()

    func request<T: Decodable>(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        body: Encodable? = nil,
        responseType: T.Type
    ) async throws -> T {
        if let token = auth.currentToken, token.isExpired {
            try await auth.refreshAccessToken()
        }

        guard let accessToken = auth.accessToken else { throw AuthError.noToken }

        var components = URLComponents(string: "\(baseURL)\(path)")
        if !queryItems.isEmpty { components?.queryItems = queryItems }

        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try await auth.refreshAccessToken()
                return try await self.request(path: path, method: method, queryItems: queryItems, body: body, responseType: responseType)
            }
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(httpResponse.statusCode, errorBody)
        }

        return try decoder.decode(T.self, from: data)
    }

    func requestVoid(
        path: String,
        method: HTTPMethod = .post,
        queryItems: [URLQueryItem] = [],
        body: Encodable? = nil
    ) async throws {
        if let token = auth.currentToken, token.isExpired {
            try await auth.refreshAccessToken()
        }

        guard let accessToken = auth.accessToken else { throw AuthError.noToken }

        var components = URLComponents(string: "\(baseURL)\(path)")
        if !queryItems.isEmpty { components?.queryItems = queryItems }

        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int, String)
    case decodingError(String)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .httpError(let code, let msg): return "Error \(code): \(msg)"
        case .decodingError(let msg): return "Data parsing error: \(msg)"
        case .noData: return "No data received"
        }
    }
}
