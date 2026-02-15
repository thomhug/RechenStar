import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .home
    @State private var showParentGate = false

    enum Tab: String, CaseIterable {
        case home = "Spielen"
        case progress = "Fortschritt"
        case achievements = "Erfolge"
        case settings = "Einstellungen"

        var icon: String {
            switch self {
            case .home: "play.circle.fill"
            case .progress: "chart.line.uptrend.xyaxis"
            case .achievements: "trophy.fill"
            case .settings: "gearshape.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            Color.appBackgroundGradient
                .ignoresSafeArea()

            if appState.currentUser == nil {
                UserSelectionView()
            } else if appState.isParentMode && !showParentGate {
                ParentGateView(isPresented: $showParentGate)
            } else {
                mainInterface
            }
        }
        .task {
            loadExistingUser()
            ensureAchievementsInitialized()
        }
    }

    private func loadExistingUser() {
        guard appState.currentUser == nil else { return }
        let descriptor = FetchDescriptor<User>()
        guard let users = try? modelContext.fetch(descriptor),
              let user = users.first else { return }
        appState.currentUser = user
    }

    private func ensureAchievementsInitialized() {
        guard let user = appState.currentUser else { return }
        guard user.achievements.count < AchievementType.allCases.count else { return }
        EngagementService.initializeAchievements(for: user, context: modelContext)
        try? modelContext.save()
    }

    private var mainInterface: some View {
        VStack(spacing: 0) {
            HeaderView(selectedTab: $selectedTab)
                .padding(.top, 10)

            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)

                LearningProgressView()
                    .tag(Tab.progress)

                AchievementsView()
                    .tag(Tab.achievements)

                SettingsView()
                    .tag(Tab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            CustomTabBar(selectedTab: $selectedTab)
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    @Binding var selectedTab: ContentView.Tab
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack {
            if let user = appState.currentUser {
                UserAvatarView(user: user)
                    .frame(width: 60, height: 60)
            }

            Spacer()

            Text(selectedTab.rawValue)
                .font(AppFonts.title)
                .foregroundColor(.appTextPrimary)

            Spacer()

            Button {
                appState.isParentMode.toggle()
            } label: {
                Image(systemName: "person.2.fill")
                    .font(.title2)
                    .foregroundColor(.appTextSecondary)
                    .opacity(0.3)
            }
            .frame(width: 60, height: 60)
            .accessibilityLabel("Elternbereich")
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: ContentView.Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ContentView.Tab.allCases, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.appCardBackground)
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let tab: ContentView.Tab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .appSkyBlue : .appTextSecondary)
                    .scaleEffect(isSelected ? 1.2 : 1.0)

                Text(tab.rawValue)
                    .font(AppFonts.footnote)
                    .foregroundColor(isSelected ? .appSkyBlue : .appTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .accessibilityLabel(tab.rawValue)
        }
        .animation(.spring(duration: 0.3, bounce: 0.3), value: isSelected)
    }
}

// MARK: - Placeholder Views
struct UserSelectionView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 40) {
            Text("Willkommen bei RechenStar!")
                .font(AppFonts.title)
                .multilineTextAlignment(.center)

            Text("Wie heisst du?")
                .font(AppFonts.headline)

            Button(action: createNewUser) {
                Text("Los geht's!")
                    .font(AppFonts.buttonLarge)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.appSkyBlue)
                    )
            }
        }
        .padding(40)
    }

    private func createNewUser() {
        let newUser = User()
        newUser.name = "Noah"
        modelContext.insert(newUser)
        EngagementService.initializeAchievements(for: newUser, context: modelContext)
        try? modelContext.save()
        appState.currentUser = newUser
    }
}

struct UserAvatarView: View {
    let user: User

    var body: some View {
        Circle()
            .fill(Color.appSkyBlue)
            .overlay(
                Text(user.name.prefix(1))
                    .font(AppFonts.headline)
                    .foregroundColor(.white)
            )
            .accessibilityLabel("Avatar von \(user.name)")
    }
}

struct ParentGateView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 30) {
            Text("Elternbereich")
                .font(AppFonts.title)

            Text("Bitte löse diese Aufgabe:")
                .font(AppFonts.bodyLarge)

            Text("15 + 27 = ?")
                .font(AppFonts.numberLarge)
                .foregroundColor(.appSkyBlue)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.appCardBackground)
                .shadow(color: .black.opacity(0.15), radius: 20)
        )
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environment(AppState())
        .environment(ThemeManager())
}
