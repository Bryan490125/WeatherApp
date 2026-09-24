import SwiftUI

/// Produces a gradient that responds to the current weather condition,
/// covering the "advanced UI" requirement's weather-responsive theming.
enum WeatherTheme {
    static func gradient(for symbol: String) -> LinearGradient {
        let colors: [Color]
        switch symbol {
        case "sun.max.fill":
            colors = [Color(red: 0.30, green: 0.62, blue: 0.98), Color(red: 0.99, green: 0.78, blue: 0.35)]
        case "cloud.sun.fill":
            colors = [Color(red: 0.42, green: 0.58, blue: 0.78), Color(red: 0.78, green: 0.82, blue: 0.86)]
        case "cloud.fill", "smoke.fill":
            colors = [Color(red: 0.45, green: 0.49, blue: 0.55), Color(red: 0.68, green: 0.71, blue: 0.75)]
        case "cloud.drizzle.fill", "cloud.rain.fill":
            colors = [Color(red: 0.22, green: 0.29, blue: 0.42), Color(red: 0.45, green: 0.52, blue: 0.62)]
        case "cloud.bolt.rain.fill":
            colors = [Color(red: 0.12, green: 0.13, blue: 0.22), Color(red: 0.30, green: 0.28, blue: 0.42)]
        case "snow":
            colors = [Color(red: 0.55, green: 0.66, blue: 0.78), Color(red: 0.90, green: 0.93, blue: 0.97)]
        case "cloud.fog.fill":
            colors = [Color(red: 0.60, green: 0.62, blue: 0.64), Color(red: 0.80, green: 0.81, blue: 0.82)]
        default:
            colors = [Color.blue, Color.cyan]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func formattedTemp(_ value: Double, unit: TemperatureUnit) -> String {
        "\(Int(value.rounded()))°"
    }
}

/// A reusable rounded, shadowed "card" container used across screens
/// for the card-based layout requirement.
struct WeatherCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
    }
}
