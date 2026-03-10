import SwiftUI

extension Notification.Name {
    static let stravaConnected = Notification.Name("stravaConnected")
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationService.shared.handleDeviceToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithDeviceToken error: Error
    ) {
        NotificationService.shared.handleTokenError(error)
    }
}

@main
struct PacePilotApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
                .task {
                    await NotificationService.shared.requestAuthorization()
                }
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

            GIFImageView(name: "artistic-runner")
                .ignoresSafeArea()
                .opacity(0.35)
                .accessibilityHidden(true)

            VStack {
                Spacer()
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                Text("PacePilot AI")
                    .font(.largeTitle.bold())
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 24)
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
                .padding(.bottom, 60)
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            PlanView()
                .tabItem { Label("Plan", systemImage: "calendar") }
                .tag(1)
            CommunityView()
                .tabItem { Label("Community", systemImage: "person.3.fill") }
                .tag(2)
            RunDiscoveryView()
                .tabItem { Label("Runs", systemImage: "figure.run") }
                .tag(3)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(4)
        }
        .accentColor(.accentColor)
    }
}

#if DEBUG
#Preview("Main Tabs") {
    MainTabView()
        .preferredColorScheme(.dark)
}

#Preview("Splash") {
    SplashView()
        .environmentObject(AuthManager.shared)
        .preferredColorScheme(.dark)
}
#endif
