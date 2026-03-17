import SwiftUI

@main
struct JuneApp: App {
    @State private var auth = AuthManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        Group {
            if auth.isLoading {
                SplashView()
            } else if auth.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
        .animation(.easeInOut(duration: 0.2), value: auth.isLoading)
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.juneBackground.ignoresSafeArea()
            VStack(spacing: 16) {
                FalconLogo(size: 72)
                Text("June")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Color.juneTextPrimary)
            }
        }
    }
}
