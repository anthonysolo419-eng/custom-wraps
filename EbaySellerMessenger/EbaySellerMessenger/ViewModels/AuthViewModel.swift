import Foundation
import SwiftUI
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var clientId: String = ""
    @Published var clientSecret: String = ""
    @Published var selectedEnvironment: EbayEnvironment = .production
    @Published var showCredentialsSetup = false

    private let authService = EbayAuthService.shared

    init() {
        isAuthenticated = authService.isAuthenticated
        if let creds = KeychainHelper.shared.loadCredentials() {
            clientId = creds.clientId
            clientSecret = creds.clientSecret
        }

        NotificationCenter.default.addObserver(
            forName: .init("EbayAuthStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isAuthenticated = EbayAuthService.shared.isAuthenticated
            }
        }
    }

    func saveCredentials() {
        guard !clientId.isEmpty, !clientSecret.isEmpty else {
            error = "Client ID and Client Secret are required"
            return
        }
        try? KeychainHelper.shared.saveCredentials((clientId: clientId, clientSecret: clientSecret))
        authService.environment = selectedEnvironment
        showCredentialsSetup = false
    }

    func login(anchor: ASPresentationAnchor) async {
        guard !clientId.isEmpty else {
            showCredentialsSetup = true
            return
        }
        isLoading = true
        error = nil
        authService.environment = selectedEnvironment
        await authService.startOAuthFlow(anchor: anchor)
        isLoading = false
        isAuthenticated = authService.isAuthenticated
        if let authError = authService.error {
            error = authError
        }
    }

    func signOut() async {
        await authService.signOut()
        isAuthenticated = false
    }

    var credentialsConfigured: Bool { !clientId.isEmpty && !clientSecret.isEmpty }
}
