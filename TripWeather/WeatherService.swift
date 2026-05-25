//
//  WeatherService.swift
//  TripWeather
//
//  Created by dylan on 5/24/26.
//

import Foundation

class WeatherService: ObservableObject {
    @Published var forecast: [ForecastDay] = []
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var resolvedCity = ""

    func fetchForecast(
        city: String,
        startDate: Date,
        endDate: Date,
        useCelsius: Bool
    ) {
        isLoading = true
        errorMessage = nil
        forecast = []

        geocode(city: city) { result in
            switch result {
            case .success(let location):
                DispatchQueue.main.async {
                    self.resolvedCity = location.name
                }

                self.fetchWeather(
                    latitude: location.latitude,
                    longitude: location.longitude,
                    startDate: startDate,
                    endDate: endDate,
                    useCelsius: useCelsius
                )

            case .failure:
                DispatchQueue.main.async {
                    self.errorMessage = "couldn't find that city"
                    self.isLoading = false
                }
            }
        }
    }

    private func geocode(
        city: String,
        completion: @escaping (Result<LocationResult, Error>) -> Void
    ) {
        let encoded = city.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? ""

        let urlString =
            "https://geocoding-api.open-meteo.com/v1/search?name=\(encoded)&count=1"

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else { return }

            do {
                let decoded = try JSONDecoder().decode(
                    GeocodingResponse.self,
                    from: data
                )

                if let result = decoded.results?.first {
                    completion(.success(result))
                } else {
                    completion(
                        .failure(
                            NSError(
                                domain: "city",
                                code: 404
                            )
                        )
                    )
                }
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }

    private func fetchWeather(
        latitude: Double,
        longitude: Double,
        startDate: Date,
        endDate: Date,
        useCelsius: Bool
    ) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)

        let unit = useCelsius ? "celsius" : "fahrenheit"

        let urlString =
            "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&daily=weathercode,temperature_2m_max,temperature_2m_min&temperature_unit=\(unit)&timezone=auto&start_date=\(start)&end_date=\(end)"

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }

            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }

            guard let data = data else { return }

            do {
                let decoded = try JSONDecoder().decode(
                    WeatherResponse.self,
                    from: data
                )

                let days = zip(
                    zip(decoded.daily.time, decoded.daily.temperature_2m_max),
                    zip(decoded.daily.temperature_2m_min, decoded.daily.weathercode)
                ).map {
                    ForecastDay(
                        date: $0.0.0,
                        high: $0.0.1,
                        low: $0.1.0,
                        weatherCode: $0.1.1
                    )
                }

                DispatchQueue.main.async {
                    self.forecast = days
                }

            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "weather fetch failed"
                }
            }
        }
        .resume()
    }

    func weatherDescription(for code: Int) -> String {
        switch code {
        case 0:
            return "clear"
        case 1...3:
            return "partly cloudy"
        case 45, 48:
            return "foggy"
        case 51...67:
            return "drizzle"
        case 71...77:
            return "snow"
        case 80...82:
            return "rain"
        case 95...99:
            return "storm"
        default:
            return "unknown"
        }
    }

    func weatherEmoji(for code: Int) -> String {
        switch code {
        case 0:
            return "☀️"
        case 1...3:
            return "🌤️"
        case 45, 48:
            return "🌫️"
        case 51...67:
            return "🌦️"
        case 71...77:
            return "❄️"
        case 80...82:
            return "🌧️"
        case 95...99:
            return "⛈️"
        default:
            return "❓"
        }
    }
}
