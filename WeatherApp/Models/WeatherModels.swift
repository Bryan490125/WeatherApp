import Foundation

// MARK: - Models used by the UI

struct OneCallResponse {
    let lat: Double
    let lon: Double
    let timezone: String
    let current: CurrentWeather
    let hourly: [HourlyWeather]
    let daily: [DailyWeather]
}

struct CurrentWeather {
    let dt: Int
    let temp: Double
    let feelsLike: Double
    let humidity: Int
    let uvi: Double
    let visibility: Int
    let windSpeed: Double
    let weather: [WeatherCondition]
}

struct HourlyWeather: Identifiable {
    let dt: Int
    let temp: Double
    let weather: [WeatherCondition]

    var id: Int { dt }
}

struct DailyWeather: Identifiable {
    let dt: Int
    let temp: DailyTemp
    let humidity: Int
    let uvi: Double
    let windSpeed: Double
    let weather: [WeatherCondition]

    var id: Int { dt }
}

struct DailyTemp {
    let day: Double
    let min: Double
    let max: Double
}

struct WeatherCondition: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String

    var sfSymbolName: String {
        switch icon.prefix(2) {
        case "01": return "sun.max.fill"
        case "02": return "cloud.sun.fill"
        case "03": return "cloud.fill"
        case "04": return "smoke.fill"
        case "09": return "cloud.drizzle.fill"
        case "10": return "cloud.rain.fill"
        case "11": return "cloud.bolt.rain.fill"
        case "13": return "snow"
        case "50": return "cloud.fog.fill"
        default: return "questionmark.circle"
        }
    }
}

// MARK: - Free Current Weather API response

struct CurrentWeatherResponse: Codable {
    let coord: Coordinates
    let weather: [WeatherCondition]
    let main: MainWeather
    let visibility: Int?
    let wind: WindData
    let dt: Int
    let timezone: Int
    let name: String
}

struct Coordinates: Codable {
    let lon: Double
    let lat: Double
}

struct MainWeather: Codable {
    let temp: Double
    let feelsLike: Double
    let tempMin: Double
    let tempMax: Double
    let humidity: Int

    enum CodingKeys: String, CodingKey {
        case temp, humidity
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
    }
}

struct WindData: Codable {
    let speed: Double
}

// MARK: - Free 5-Day Forecast API response

struct FiveDayForecastResponse: Codable {
    let list: [ForecastItem]
    let city: ForecastCity
}

struct ForecastItem: Codable {
    let dt: Int
    let main: MainWeather
    let weather: [WeatherCondition]
    let wind: WindData
}

struct ForecastCity: Codable {
    let name: String
    let timezone: Int
}

// MARK: - Geocoding API response

struct GeoResult: Codable, Identifiable {
    let name: String
    let lat: Double
    let lon: Double
    let country: String
    let state: String?

    var id: String {
        "\(name)-\(lat)-\(lon)"
    }

    var displayName: String {
        if let state, !state.isEmpty {
            return "\(name), \(state), \(country)"
        }

        return "\(name), \(country)"
    }
}
