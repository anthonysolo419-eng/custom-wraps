import SwiftUI

struct CredentialsSetupView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSecret = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    credentialsForm
                    environmentPicker
                    howToGetCredentials
                }
                .padding()
            }
            .navigationTitle("API Credentials")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveCredentials()
                        if viewModel.error == nil { dismiss() }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "key.fill")
                .font(.system(size: 44))
                .foregroundStyle(.ebayBlue)
            Text("Connect Your eBay Account")
                .font(.title2)
                .fontWeight(.bold)
            Text("Enter your eBay Developer API credentials to get started. These are stored securely in your device's Keychain.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }

    private var credentialsForm: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Client ID (App ID)", systemImage: "person.badge.key.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("e.g. YourName-AppName-PRD-abc123...", text: $viewModel.clientId)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            VStack(alignment: .leading, spacing: 6) {
                Label("Client Secret (Cert ID)", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    if showSecret {
                        TextField("Client Secret", text: $viewModel.clientSecret)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("Client Secret", text: $viewModel.clientSecret)
                    }
                    Button {
                        showSecret.toggle()
                    } label: {
                        Image(systemName: showSecret ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                }
                .textFieldStyle(.roundedBorder)
            }

            if let error = viewModel.error {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var environmentPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Environment")
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker("Environment", selection: $viewModel.selectedEnvironment) {
                ForEach(EbayEnvironment.allCases, id: \.self) { env in
                    Text(env.rawValue).tag(env)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var howToGetCredentials: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("How to get credentials", systemImage: "info.circle.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.ebayBlue)

            VStack(alignment: .leading, spacing: 8) {
                StepRow(number: "1", text: "Go to developer.ebay.com")
                StepRow(number: "2", text: "Sign in with your eBay seller account")
                StepRow(number: "3", text: "Create a new application")
                StepRow(number: "4", text: "Enable Sell APIs and Messaging APIs")
                StepRow(number: "5", text: "Add 'ebaymessenger://oauth/callback' as a redirect URI")
                StepRow(number: "6", text: "Copy your Client ID and Client Secret here")
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct StepRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Color.ebayBlue)
                .clipShape(Circle())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}
