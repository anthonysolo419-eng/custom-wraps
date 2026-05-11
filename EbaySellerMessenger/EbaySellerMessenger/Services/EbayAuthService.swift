import Foundation
import AuthenticationServices

@MainActor
final class EbayAuthService: NSObject, ObservableObject {
    static let shared = EbayAuthService()

    @Published var isAuthenticated = false
    @Published var currentToken: EbayToken?
    @Published var error: String?

    var environment: EbayEnvironment = .production
    private var credentials: EbayCredentials { environment == .production ? .production : .sandbox }
    private var webAuthSession: ASWebAuthenticationSession?

    override init() {
        super.init()
        if let saved = KeychainHelper.shared.loadToken(), !saved.isExpired {
            currentToken = saved
            isAuthenticated = true
        }
    }

    var accessToken: String? { currentToken?.accessToken }

    func startOAuthFlow(anchor: ASPresentationAnchor) async {
        guard !credentials.clientId.isEmpty else {
            error = "eBay Client ID not configured. Please add your credentials in Settings."
            return
        }

        let authURL = buildAuthorizationURL()
        guard let url = URL(string: authURL) else {
            error = "Invalid authorization URL"
            return
        }

        await withCheckedContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "ebaymessenger"
            ) { [weak self] callbackURL, error in
                Task { @MainActor in
                    if let error = error {
                        if (error as? ASWebAuthenticationSessionError)?.code != .canceledLogin {
                            self?.error = error.localizedDescription
                        }
                        continuation.resume()
                        return
                    }
                    guard let callbackURL = callbackURL,
                          let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                            .queryItems?.first(where: { $0.name == "code" })?.value else {
                        self?.error = "No authorization code received"
                        continuation.resume()
                        return
                    }
                    await self?.exchangeCodeForToken(code: code)
                    continuation.resume()
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            webAuthSession = session
            session.start()
        }
    }

    func exchangeCodeForToken(code: String) async {
        let tokenURL = "\(credentials.clientId.isEmpty ? EbayEnvironment.production.apiBaseURL : environment.apiBaseURL)/identity/v1/oauth2/token"

        guard let url = URL(string: tokenURL) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(credentials.base64Credentials)", forHTTPHeaderField: "Authorization")

        let body = [
            "grant_type=authorization_code",
            "code=\(code)",
            "redirect_uri=\(credentials.redirectUri)"
        ].joined(separator: "&")
        request.httpBody = body.data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                error = "Token exchange failed"
                return
            }
            let decoder = JSONDecoder()
            var token = try decoder.decode(EbayToken.self, from: data)
            token.createdAt = Date()
            currentToken = token
            try KeychainHelper.shared.saveToken(token)
            isAuthenticated = true
        } catch {
            self.error = "Authentication error: \(error.localizedDescription)"
        }
    }

    func refreshAccessToken() async throws {
        guard let token = currentToken,
              let refreshToken = token.refreshToken,
              !token.refreshTokenIsExpired else {
            await signOut()
            throw AuthError.refreshTokenExpired
        }

        let tokenURL = "\(environment.apiBaseURL)/identity/v1/oauth2/token"
        guard let url = URL(string: tokenURL) else { throw AuthError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(credentials.base64Credentials)", forHTTPHeaderField: "Authorization")

        let body = "grant_type=refresh_token&refresh_token=\(refreshToken)&scope=\(credentials.scopeString)"
        request.httpBody = body.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        var newToken = try JSONDecoder().decode(EbayToken.self, from: data)
        newToken.createdAt = Date()
        currentToken = newToken
        try KeychainHelper.shared.saveToken(newToken)
    }

    func signOut() async {
        currentToken = nil
        isAuthenticated = false
        KeychainHelper.shared.clearAll()
    }

    private func buildAuthorizationURL() -> String {
        let params = [
            "client_id=\(credentials.clientId)",
            "response_type=code",
            "redirect_uri=\(credentials.redirectUri)",
            "scope=\(credentials.scopeString)",
            "prompt=login"
        ].joined(separator: "&")
        return "\(environment.authBaseURL)/oauth2/authorize?\(params)"
    }
}

extension EbayAuthService: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}

enum AuthError: Error, LocalizedError {
    case refreshTokenExpired
    case invalidURL
    case noToken

    var errorDescription: String? {
        switch self {
        case .refreshTokenExpired: return "Session expired. Please log in again."
        case .invalidURL: return "Invalid API URL"
        case .noToken: return "Not authenticated"
        }
    }
}
