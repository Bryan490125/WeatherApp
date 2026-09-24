import Foundation

enum WeatherServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingFailed
    case noResults

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Couldn't build a valid request URL."
        case .invalidResponse:
            return "The server returned an unexpected response."
        case .httpError(let code):
            return "Request failed with status code \(code)."
        case .decodingFailed:
            return "Couldn't parse the weather data."
        case .noResults:
            return "No matching cities found."
        }
    }
}

actor WeatherService {
    static let shared = WeatherService()

    private let session: URLSession = .shared
    private let baseURL = "https://api.openweathermap.org"

    func fetchWeather(
        lat: Double,
        lon: Double,
        units: TemperatureUnit
    ) async throws -> OneCallResponse {

        let current: CurrentWeatherResponse = try await request(
            path: "/data/2.5/weather",
            queryItems: [
                URLQueryItem(name: "lat", value: "\(lat)"),
                URLQueryItem(name: "lon", value: "\(lon)"),
                URLQueryItem(name: "units", value: units.rawValue),
                URLQueryItem(name: "appid", value: Secrets.openWeatherAPIKey)
            ]
        )

        let forecast: FiveDayForecastResponse = try await request(
            path: "/data/2.5/forecast",
            queryItems: [
                URLQueryItem(name: "lat", value: "\(lat)"),
                URLQueryItem(name: "lon", value: "\(lon)"),
                URLQueryItem(name: "units", value: units.rawValue),
                URLQueryItem(name: "appid", value: Secrets.openWeatherAPIKey)
            ]
        )

        let currentWeather = CurrentWeather(
            dt: current.dt,
            temp: current.main.temp,
            feelsLike: current.main.feelsLike,
            humidity: current.main.humidity,
            uvi: 0,
            visibility: current.visibility ?? 0,
            windSpeed: current.wind.speed,
            weather: current.weather
        )

        let hourly = forecast.list.map { item in
            HourlyWeather(
                dt: item.dt,
                temp: item.main.temp,
                weather: item.weather
            )
        }

        let daily = makeDailyForecast(
            from: forecast.list,
            timezoneOffset: forecast.city.timezone
        )

        return OneCallResponse(
            lat: current.coord.lat,
            lon: current.coord.lon,
            timezone: forecast.city.name,
            current: currentWeather,
            hourly: hourly,
            daily: daily
        )
    }

    func searchCity(named query: String) async throws -> [GeoResult] {
        let results: [GeoResult] = try await request(
            path: "/geo/1.0/direct",
            queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: "5"),
                URLQueryItem(name: "appid", value: Secrets.openWeatherAPIKey)
            ]
        )

        guard !results.isEmpty else {
            throw WeatherServiceError.noResults
        }

        return results
    }

    private func request<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem]
    ) async throws -> T {
        var components = URLComponents(string: baseURL + path)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw WeatherServiceError.httpError(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Decoding error:", error)
            throw WeatherServiceError.decodingFailed
        }
    }

    private func makeDailyForecast(
        from items: [ForecastItem],
        timezoneOffset: Int
    ) -> [DailyWeather] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone =
            TimeZone(secondsFromGMT: timezoneOffset) ?? .gmt

        let grouped = Dictionary(grouping: items) { item in
            let date = Date(
                timeIntervalSince1970: TimeInterval(item.dt)
            )
            return calendar.startOfDay(for: date)
        }

        return grouped.keys.sorted().compactMap { day in
            guard let dayItems = grouped[day],
                  !dayItems.isEmpty else {
                return nil
            }

            let representative = dayItems.min { first, second in
                let firstDate = Date(
                    timeIntervalSince1970: TimeInterval(first.dt)
                )
                let secondDate = Date(
                    timeIntervalSince1970: TimeInterval(second.dt)
                )

                let firstHour = calendar.component(.hour, from: firstDate)
                let secondHour = calendar.component(.hour, from: secondDate)

                return abs(firstHour - 12) < abs(secondHour - 12)
            } ?? dayItems[0]

            let minimum = dayItems
                .map(\.main.tempMin)
                .min() ?? representative.main.tempMin

            let maximum = dayItems
                .map(\.main.tempMax)
                .max() ?? representative.main.tempMax

            return DailyWeather(
                dt: Int(day.timeIntervalSince1970),
                temp: DailyTemp(
                    day: representative.main.temp,
                    min: minimum,
                    max: maximum
                ),
                humidity: representative.main.humidity,
                uvi: 0,
                windSpeed: representative.wind.speed,
                weather: representative.weather
            )
        }
    }
}
