import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Display") {
                    Picker("Temperature Unit", selection: Binding(
                        get: { settings.temperatureUnit },
                        set: { settings.temperatureUnit = $0 }
                    )) {
                        ForEach(TemperatureUnit.allCases) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                    Toggle("Dark Mode", isOn: $settings.isDarkMode)
                }

                Section("Notifications") {
                    Toggle("Weather Alerts", isOn: $settings.weatherAlertsEnabled)
                    Toggle("Daily Forecast", isOn: $settings.dailyForecastNotificationsEnabled)
                }

                Section("About") {
                    LabeledContent("Data Source", value: "OpenWeatherMap")
                    LabeledContent("Version", value: "1.0")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
