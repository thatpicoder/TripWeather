//
//  Models.swift
//  TripWeather
//
//  Created by dylan on 5/24/26.
//

import Foundation

struct GeocodingResponse: Codable {
    let results: [LocationResult]?
}

struct LocationResult: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
}

struct WeatherResponse: Codable {
    let daily: DailyWeather
}

struct DailyWeather: Codable {
    let time: [String]
    let weathercode: [Int]
    let temperature_2m_max: [Double]
    let temperature_2m_min: [Double]
}

struct ForecastDay: Identifiable {
    let id = UUID()
    let date: String
    let high: Double
    let low: Double
    let weatherCode: Int
}
