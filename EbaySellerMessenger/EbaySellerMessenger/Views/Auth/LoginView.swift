import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var anchor: ASPresentationAnchor?

    var body: some View {
        ZStack {
            backgroundGradient
            VStack(spacing: 0) {
                Spacer()
                logoSection
                Spacer()
                contentCard
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $viewModel.showCredentialsSetup) {
            CredentialsSetupView(viewModel: viewModel)
        }
        .overlay(anchorCapture)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.13, green: 0.35, blue: 0.80),
                Color(red: 0.22, green: 0.49, blue: 0.96),
                Color(red: 0.08, green: 0.60, blue: 0.40)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var logoSection: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(0.15))
                    .frame(width: 88, height: 88)
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }
            VStack(spacing: 6) {
                Text("eBay Seller")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                Text("Messenger")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))
                Text("Professional messaging for eBay sellers")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var contentCard: some View {
        VStack(spacing: 20) {
            featureList

            Divider()
                .background(.gray.opacity(0.3))

            VStack(spacing: 12) {
                loginButton
                setupButton
            }

            if let error = viewModel.error {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Text("Requires eBay Developer Account & API credentials")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 10) {
            FeatureRow(icon: "message.fill", color: .blue, text: "Threaded conversations per order")
            FeatureRow(icon: "checkmark.circle.fill", color: .green, text: "Select & message multiple buyers")
            FeatureRow(icon: "tag.fill", color: .orange, text: "Insert coupons & deals instantly")
            FeatureRow(icon: "bell.fill", color: .purple, text: "Real-time new message alerts")
        }
    }

    private var loginButton: some View {
        Button {
            guard let anchor = anchor else { return }
            Task { await viewModel.login(anchor: anchor) }
        } label: {
            Group {
                if viewModel.isLoading {
                    HStack(spacing: 10) {
                        ProgressView()
                            .tint(.white)
                        Text("Connecting...")
                    }
                } else {
                    Label(
                        viewModel.credentialsConfigured ? "Sign in with eBay" : "Sign in (Setup credentials first)",
                        systemImage: "arrow.right.circle.fill"
                    )
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.ebayBlue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(viewModel.isLoading)
    }

    private var setupButton: some View {
        Button {
            viewModel.showCredentialsSetup = true
        } label: {
            Label(
                viewModel.credentialsConfigured ? "Update API Credentials" : "Setup API Credentials",
                systemImage: "key.fill"
            )
            .font(.subheadline)
            .foregroundStyle(.ebayBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.ebayBlue, lineWidth: 1.5)
            )
        }
    }

    // Invisible overlay to capture the UIWindow for ASWebAuthenticationSession
    private var anchorCapture: some View {
        GeometryReader { _ in
            Color.clear
                .onAppear {
                    anchor = UIApplication.shared.connectedScenes
                        .compactMap { $0 as? UIWindowScene }
                        .first?.windows.first { $0.isKeyWindow }
                }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
        }
    }
}
