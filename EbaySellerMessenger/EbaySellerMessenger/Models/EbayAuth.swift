import Foundation

struct EbayToken: Codable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String
    let refreshToken: String?
    let refreshTokenExpiresIn: Int?
    var createdAt: Date = Date()

    var isExpired: Bool {
        Date() >= createdAt.addingTimeInterval(TimeInterval(expiresIn - 60))
    }

    var refreshTokenIsExpired: Bool {
        guard let refreshExpiry = refreshTokenExpiresIn else { return true }
        return Date() >= createdAt.addingTimeInterval(TimeInterval(refreshExpiry - 60))
    }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case refreshToken = "refresh_token"
        case refreshTokenExpiresIn = "refresh_token_expires_in"
        case createdAt
    }
}

struct EbayCredentials {
    let clientId: String
    let clientSecret: String
    let redirectUri: String
    let scopes: [String]

    var base64Credentials: String {
        let raw = "\(clientId):\(clientSecret)"
        return Data(raw.utf8).base64EncodedString()
    }

    var scopeString: String {
        scopes.joined(separator: "%20")
    }

    static let production = EbayCredentials(
        clientId: "",
        clientSecret: "",
        redirectUri: "ebaymessenger://oauth/callback",
        scopes: [
            "https://api.ebay.com/oauth/api_scope",
            "https://api.ebay.com/oauth/api_scope/sell.fulfillment.readonly",
            "https://api.ebay.com/oauth/api_scope/sell.fulfillment",
            "https://api.ebay.com/oauth/api_scope/sell.message",
            "https://api.ebay.com/oauth/api_scope/sell.message.readonly"
        ]
    )

    static let sandbox = EbayCredentials(
        clientId: "",
        clientSecret: "",
        redirectUri: "ebaymessenger://oauth/callback",
        scopes: [
            "https://api.ebay.com/oauth/api_scope",
            "https://api.ebay.com/oauth/api_scope/sell.fulfillment.readonly",
            "https://api.ebay.com/oauth/api_scope/sell.message",
            "https://api.ebay.com/oauth/api_scope/sell.message.readonly"
        ]
    )
}

enum EbayEnvironment: String, CaseIterable {
    case production = "Production"
    case sandbox = "Sandbox"

    var authBaseURL: String {
        switch self {
        case .production: return "https://auth.ebay.com"
        case .sandbox: return "https://auth.sandbox.ebay.com"
        }
    }

    var apiBaseURL: String {
        switch self {
        case .production: return "https://api.ebay.com"
        case .sandbox: return "https://api.sandbox.ebay.com"
        }
    }
}
