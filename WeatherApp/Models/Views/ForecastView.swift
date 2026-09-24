import SwiftUI

struct ForecastView: View {
    @EnvironmentObject private var settings: SettingsStore
    let location: FavoriteLocation
    let weather: OneCallResponse

    var body: some View {
        ZStack {
            WeatherTheme.gradient(for: weather.current.weather.first?.sfSymbolName ?? "sun.max.fill")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    detailsGrid
                    hourlySection
                    dailySection
                }
                .padding()
            }
        }
        .navigationTitle("\(location.name) Forecast")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var detailsGrid: some View {
        WeatherCard {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                detailItem(icon: "humidity.fill", label: "Humidity", value: "\(weather.current.humidity)%")
                detailItem(icon: "sun.max.trianglebadge.exclamationmark.fill", label: "UV Index", value: String(format: "%.1f", weather.current.uvi))
                detailItem(icon: "eye.fill", label: "Visibility", value: "\(weather.current.visibility / 1000) km")
                detailItem(icon: "wind", label: "Wind", value: "\(Int(weather.current.windSpeed)) m/s")
            }
        }
    }

    private func detailItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var hourlySection: some View {
        WeatherCard {
            Text("Hourly").font(.headline)
            ForEach(weather.hourly.prefix(12)) { hour in
                HStack {
                    Text(hourLabel(hour.dt)).frame(width: 60, alignment: .leading)
                    Image(systemName: hour.weather.first?.sfSymbolName ?? "sun.max.fill")
                    Spacer()
                    Text("\(Int(hour.temp.rounded()))°").font(.subheadline.bold())
                }
                if hour.id != weather.hourly.prefix(12).last?.id {
                    Divider()
                }
            }
        }
    }

    private var dailySection: some View {
        WeatherCard {
            Text("7-Day Forecast").font(.headline)
            ForEach(weather.daily.prefix(7)) { day in
                HStack {
                    Text(dayLabel(day.dt)).frame(width: 60, alignment: .leading)
                    Image(systemName: day.weather.first?.sfSymbolName ?? "sun.max.fill")
                    Spacer()
                    Text("\(Int(day.temp.min))° / \(Int(day.temp.max))°")
                        .font(.subheadline.bold())
                }
                if day.id != weather.daily.prefix(7).last?.id {
                    Divider()
                }
            }
        }
    }

    private func hourLabel(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: date)
    }

    private func dayLabel(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}
