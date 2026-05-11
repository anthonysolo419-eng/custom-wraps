import SwiftUI

@main
struct EbaySellerMessengerApp: App {
    @StateObject private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.isAuthenticated {
                MainTabView()
                    .environmentObject(authVM)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                LoginView(viewModel: authVM)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: authVM.isAuthenticated)
        .sheet(isPresented: $authVM.showCredentialsSetup) {
            CredentialsSetupView(viewModel: authVM)
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    private func handleDeepLink(_ url: URL) {
        // OAuth callback is handled automatically by ASWebAuthenticationSession
        // This handles any other deep links if needed
        guard url.scheme == "ebaymessenger" else { return }
    }
}
