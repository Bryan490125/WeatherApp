import Foundation
import SwiftUI
import Combine

/// Preferences stored with UserDefaults (the second, lighter-weight
/// half of our "data persistence" requirement, alongside SwiftData).
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @AppStorage("temperatureUnit") var temperatureUnitRaw: String = TemperatureUnit.celsius.rawValue
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    @AppStorage("weatherAlertsEnabled") var weatherAlertsEnabled: Bool = true
    @AppStorage("dailyForecastNotificationsEnabled") var dailyForecastNotificationsEnabled: Bool = false

    var temperatureUnit: TemperatureUnit {
        get { TemperatureUnit(rawValue: temperatureUnitRaw) ?? .celsius }
        set { temperatureUnitRaw = newValue.rawValue }
    }
}

enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius = "metric"
    case fahrenheit = "imperial"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }

    var label: String {
        switch self {
        case .celsius: return "Celsius (°C)"
        case .fahrenheit: return "Fahrenheit (°F)"
        }
    }
}
