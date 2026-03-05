import SwiftUI

extension Notification.Name {
    static let stravaConnected = Notification.Name("stravaConnected")
}

@main
struct PacePilotApp: App {
    @StateObject private var router = AppRouter.shared
    @StateObject private var auth = AuthManager.shared
    @StateObject private var apiClient = APIClient.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .environmentObject(auth)
                .environmentObject(apiClient)
                .task { await auth.validateSession() }
                .onOpenURL { url in
                    if url.host == "strava-connected" {
                        NotificationCenter.default.post(name: .stravaConnected, object: nil)
                    }
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        switch router.route {
        case .splash:       SplashView()
        case .onboarding:   OnboardingView()
        case .main:         MainTabView()
        }
    }
}

struct SplashView: View {
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 32) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                Text("PacePilot")
                    .font(.largeTitle.bold())
                    .foregroundColor(.accentColor)
                Button(action: { auth.signInWithApple() }) {
                    HStack(spacing: 14) {
                        Image(systemName: "apple.logo")
                            .font(.title2.weight(.semibold))
                        Text("Sign in with Apple")
                            .font(.headline)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 40)
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            PlanView()
                .tabItem { Label("Plan", systemImage: "calendar") }
            CommunityView()
                .tabItem { Label("Community", systemImage: "person.3.fill") }
            RaceDiscoveryView()
                .tabItem { Label("Races", systemImage: "flag.checkered") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .accentColor(.accentColor)
    }
}
