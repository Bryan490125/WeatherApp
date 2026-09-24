import SwiftUI
import SwiftData

@main
struct WeatherApp: App {
    @StateObject private var settings = SettingsStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .preferredColorScheme(settings.isDarkMode ? .dark : .light)
        }
        .modelContainer(for: FavoriteLocation.self)
    }
}
