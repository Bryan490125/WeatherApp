import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: SettingsStore
    @Query(sort: \FavoriteLocation.sortOrder) private var favorites: [FavoriteLocation]

    @State private var weather: OneCallResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSettings = false
    @State private var showingSearch = false

    private var activeLocation: FavoriteLocation? {
        favorites.first(where: { $0.isLastViewed }) ?? favorites.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WeatherTheme.gradient(for: weather?.current.weather.first?.sfSymbolName ?? "sun.max.fill")
                    .ignoresSafeArea()

                if let location = activeLocation {
                    ScrollView {
                        VStack(spacing: 20) {
                            headerCard(for: location)

                            if let weather {
                                hourlyStrip(weather.hourly)

                                NavigationLink {
                                    ForecastView(location: location, weather: weather)
                                } label: {
                                    WeatherCard {
                                        HStack {
                                            Text("7-Day Forecast")
                                                .font(.headline)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            } else if isLoading {
                                ProgressView().tint(.white).padding(.top, 40)
                            } else if let errorMessage {
                                Text(errorMessage)
                                    .foregroundStyle(.white)
                                    .padding()
                            }
                        }
                        .padding(.top, 8)
                    }
                    .refreshable { await loadWeather(for: location) }
                } else {
                    emptyState
                }
            }
            .navigationTitle(activeLocation?.name ?? "Weather")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.white)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sheet(isPresented: $showingSearch) { SearchView() }
            .task(id: activeLocation?.id) {
                if let location = activeLocation {
                    await loadWeather(for: location)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 60))
                .foregroundStyle(.white)
            Text("No locations yet")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Button("Add a Location") { showingSearch = true }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.blue)
        }
    }

    private func headerCard(for location: FavoriteLocation) -> some View {
        VStack(spacing: 6) {
            Text(location.name)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            if let weather {
                Image(systemName: weather.current.weather.first?.sfSymbolName ?? "sun.max.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse)

                Text(WeatherTheme.formattedTemp(weather.current.temp, unit: settings.temperatureUnit))
                    .font(.system(size: 64, weight: .thin))
                    .foregroundStyle(.white)

                Text(weather.current.weather.first?.description.capitalized ?? "")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))

                if let today = weather.daily.first {
                    Text("H:\(Int(today.temp.max))°  L:\(Int(today.temp.min))°")
                        .foregroundStyle(.white.opacity(0.85))
                }
            } else if isLoading {
                ProgressView().tint(.white).padding(.vertical, 40)
            }
        }
        .padding(.top, 12)
    }

    private func hourlyStrip(_ hourly: [HourlyWeather]) -> some View {
        WeatherCard {
            Text("Hourly").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(hourly.prefix(12)) { hour in
                        VStack(spacing: 6) {
                            Text(hourLabel(hour.dt))
                                .font(.caption)
                            Image(systemName: hour.weather.first?.sfSymbolName ?? "sun.max.fill")
                            Text("\(Int(hour.temp.rounded()))°")
                                .font(.subheadline.bold())
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal)
    }

    private func hourLabel(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: date)
    }

    private func loadWeather(for location: FavoriteLocation) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let result = try await WeatherService.shared.fetchWeather(
                lat: location.latitude,
                lon: location.longitude,
                units: settings.temperatureUnit
            )
            weather = result
            location.cachedTemp = result.current.temp
            location.cachedConditionSFSymbol = result.current.weather.first?.sfSymbolName
            location.cachedConditionText = result.current.weather.first?.description
            location.cachedAt = .now
            try? modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
