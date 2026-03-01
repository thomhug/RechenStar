import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .home
    @State private var showParentSheet = false

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
            } else {
                mainInterface
            }
        }
        .task {
            loadExistingUser()
            ensureUserDataInitialized()
        }
        .onChange(of: appState.currentUser?.id) {
            ensureUserDataInitialized()
        }
        .fullScreenCover(isPresented: $showParentSheet) {
            ParentFlowView(onDismiss: { showParentSheet = false })
        }
    }

    private func loadExistingUser() {
        guard appState.currentUser == nil else { return }
        let descriptor = FetchDescriptor<User>()
        guard let users = try? modelContext.fetch(descriptor) else { return }
        // If exactly one user, auto-select. Otherwise show selection.
        if users.count == 1 {
            appState.currentUser = users.first
        }
        // If multiple or zero users, UserSelectionView will show
    }

    private func ensureUserDataInitialized() {
        guard let user = appState.currentUser else { return }
        var needsSave = false
        if user.achievements.count < AchievementType.allCases.count {
            EngagementService.initializeAchievements(for: user, context: modelContext)
            needsSave = true
        }
        if user.preferences == nil {
            let prefs = UserPreferences()
            prefs.user = user
            modelContext.insert(prefs)
            needsSave = true
        }
        if needsSave {
            try? modelContext.save()
        }
    }

    private var mainInterface: some View {
        VStack(spacing: 0) {
            HeaderView(selectedTab: $selectedTab, onParentTap: {
                showParentSheet = true
            }, onSwitchProfile: {
                appState.currentUser = nil
            })
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
    var onParentTap: () -> Void
    var onSwitchProfile: () -> Void

    var body: some View {
        HStack {
            if let user = appState.currentUser {
                Button {
                    onSwitchProfile()
                } label: {
                    HStack(spacing: 8) {
                        UserAvatarView(user: user)
                            .frame(width: 40, height: 40)
                        Text(user.name)
                            .font(AppFonts.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                }
                .accessibilityLabel("Profil wechseln, aktuell \(user.name)")
            }

            Spacer()

            Text(selectedTab.rawValue)
                .font(AppFonts.title)
                .foregroundColor(.appTextPrimary)

            Spacer()

            Button {
                onParentTap()
            } label: {
                Image(systemName: "person.2.fill")
                    .font(.title2)
                    .foregroundColor(.appTextSecondary)
                    .opacity(0.3)
            }
            .frame(width: 40, height: 40)
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
        .accessibilityIdentifier("tab-\(tab.rawValue)")
        .animation(.spring(duration: 0.3, bounce: 0.3), value: isSelected)
    }
}

// MARK: - User Selection
struct UserSelectionView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var users: [User] = []
    @State private var showNewProfile = false
    @State private var newName = ""
    @State private var userToDelete: User?

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Text("RechenStar")
                .font(AppFonts.display)
                .foregroundColor(.appSkyBlue)

            if users.isEmpty {
                Text("Willkommen! Erstelle dein Profil:")
                    .font(AppFonts.headline)
                    .foregroundColor(.appTextPrimary)
            } else {
                Text("Wer spielt?")
                    .font(AppFonts.headline)
                    .foregroundColor(.appTextPrimary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 16)], spacing: 16) {
                    ForEach(users, id: \.id) { user in
                        Button {
                            appState.currentUser = user
                        } label: {
                            VStack(spacing: 8) {
                                UserAvatarView(user: user)
                                    .frame(width: 70, height: 70)
                                Text(user.name)
                                    .font(AppFonts.body)
                                    .foregroundColor(.appTextPrimary)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.appCardBackground)
                                    .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                            )
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                userToDelete = user
                            } label: {
                                Label("Profil löschen", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            Button {
                showNewProfile = true
                newName = ""
            } label: {
                Label("Neues Profil", systemImage: "plus.circle.fill")
                    .font(AppFonts.buttonLarge)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.appSkyBlue)
                    )
            }

            Spacer()
        }
        .padding(20)
        .onAppear { loadUsers() }
        .alert("Neues Profil", isPresented: $showNewProfile) {
            TextField("Name eingeben", text: $newName)
            Button("Erstellen") { createNewUser(name: newName) }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Wie heisst du?")
        }
        .alert("Profil löschen?", isPresented: Binding(
            get: { userToDelete != nil },
            set: { if !$0 { userToDelete = nil } }
        )) {
            Button("Löschen", role: .destructive) {
                if let user = userToDelete {
                    deleteUser(user)
                }
            }
            Button("Abbrechen", role: .cancel) {
                userToDelete = nil
            }
        } message: {
            if let user = userToDelete {
                Text("Alle Daten von \(user.name) werden unwiderruflich gelöscht.")
            }
        }
    }

    private func loadUsers() {
        let descriptor = FetchDescriptor<User>(sortBy: [SortDescriptor(\.createdAt)])
        users = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func deleteUser(_ user: User) {
        modelContext.delete(user)
        try? modelContext.save()
        userToDelete = nil
        loadUsers()
    }

    private func createNewUser(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newUser = User(name: trimmed)
        modelContext.insert(newUser)
        let prefs = UserPreferences()
        prefs.user = newUser
        modelContext.insert(prefs)
        EngagementService.initializeAchievements(for: newUser, context: modelContext)
        try? modelContext.save()
        appState.currentUser = newUser
    }
}

struct UserAvatarView: View {
    let user: User

    var body: some View {
        let level = Level.current(for: user.totalExercises)
        Image(level.imageName)
            .resizable()
            .scaledToFit()
            .accessibilityLabel("\(level.title) — \(user.name)")
    }
}

// MARK: - Parent Flow
struct ParentFlowView: View {
    let onDismiss: () -> Void
    @Environment(AppState.self) private var appState

    var body: some View {
        if let user = appState.currentUser {
            ParentDashboardView(user: user, onDismiss: onDismiss)
        }
    }
}


// MARK: - Preview
#Preview {
    ContentView()
        .environment(AppState())
        .environment(ThemeManager())
}
