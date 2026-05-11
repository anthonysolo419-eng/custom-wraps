import SwiftUI

struct MainTabView: View {
    @StateObject private var ordersVM = OrdersViewModel()
    @StateObject private var conversationVM = ConversationViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ConversationsListView(conversationVM: conversationVM, ordersVM: ordersVM)
                .tabItem {
                    Label("Messages", systemImage: selectedTab == 0 ? "bubble.left.fill" : "bubble.left")
                }
                .badge(conversationVM.totalUnreadCount > 0 ? conversationVM.totalUnreadCount : 0)
                .tag(0)

            OrdersListView(ordersVM: ordersVM, conversationVM: conversationVM)
                .tabItem {
                    Label("Orders", systemImage: selectedTab == 1 ? "shippingbox.fill" : "shippingbox")
                }
                .badge(ordersVM.totalUnread > 0 ? ordersVM.totalUnread : 0)
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: selectedTab == 2 ? "gearshape.fill" : "gearshape")
                }
                .tag(2)
        }
        .tint(.ebayBlue)
        .task {
            await loadInitialData()
        }
    }

    private func loadInitialData() async {
        await ordersVM.loadOrders()
        await conversationVM.loadConversations(for: ordersVM.orders)
        await NotificationService.shared.requestPermission()
    }
}

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showSignOutAlert = false
    @State private var notificationsEnabled = true
    @AppStorage("autoRefreshInterval") private var autoRefreshInterval = 30

    var body: some View {
        NavigationStack {
            List {
                accountSection
                notificationsSection
                refreshSection
                aboutSection
                signOutSection
            }
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task { await authVM.signOut() }
                }
            } message: {
                Text("Are you sure you want to sign out? You'll need to re-authenticate with eBay.")
            }
        }
    }

    private var accountSection: some View {
        Section("Account") {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.ebayBlue.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.fill")
                        .foregroundStyle(.ebayBlue)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("eBay Seller Account")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Connected")
                        .font(.caption)
                        .foregroundStyle(.ebayGreen)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.ebayGreen)
            }

            Button("Update API Credentials") {
                authVM.showCredentialsSetup = true
            }
            .foregroundStyle(.ebayBlue)
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("New Message Alerts", isOn: $notificationsEnabled)
                .tint(.ebayBlue)
        }
    }

    private var refreshSection: some View {
        Section("Auto-Refresh") {
            Picker("Refresh Every", selection: $autoRefreshInterval) {
                Text("15 seconds").tag(15)
                Text("30 seconds").tag(30)
                Text("1 minute").tag(60)
                Text("5 minutes").tag(300)
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("eBay API")
                Spacer()
                Text("REST v1 + Messaging v1")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }

    private var signOutSection: some View {
        Section {
            Button("Sign Out") {
                showSignOutAlert = true
            }
            .foregroundStyle(.red)
        }
    }
}
