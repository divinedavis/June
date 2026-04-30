import SwiftUI

@main
struct JuneApp: App {
    @StateObject private var auth = AuthManager()
    @StateObject private var location = LocationManager()
    @StateObject private var cloud = CloudKitStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .environmentObject(location)
                .environmentObject(cloud)
                .preferredColorScheme(.dark)
                .tint(JuneTheme.accent)
        }
    }
}
