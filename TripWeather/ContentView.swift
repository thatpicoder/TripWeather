//
//  ContentView.swift
//  TripWeather
//
//  Created by dylan on 5/24/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var weatherService = WeatherService()

    @State private var city = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(
        byAdding: .day,
        value: 3,
        to: Date()
    ) ?? Date()

    @State private var useCelsius = false
    @State private var showShareSheet = false

    var countdownText: String {
        let days = Calendar.current.dateComponents(
            [.day],
            from: Date(),
            to: startDate
        ).day ?? 0

        if days <= 0 {
            return "your trip starts today 👀"
        } else if days == 1 {
            return "your trip starts tomorrow"
        } else {
            return "your trip starts in \(days) days"
        }
    }

    var shareText: String {
        let unit = useCelsius ? "°C" : "°F"

        var text = """
        TripWeather forecast for \(weatherService.resolvedCity)

        \(countdownText)

        """

        for day in weatherService.forecast {
            text += """
            \(formattedDate(day.date)) \
            \(weatherService.weatherEmoji(for: day.weatherCode)) \
            \(Int(day.high))\(unit)/\(Int(day.low))\(unit)

            """
        }

        return text
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("TripWeather")
                        .font(.largeTitle)
                        .bold()

                    VStack(spacing: 16) {
                        TextField("destination city", text: $city)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        DatePicker(
                            "start date",
                            selection: $startDate,
                            in: Date()...,
                            displayedComponents: .date
                        )

                        DatePicker(
                            "end date",
                            selection: $endDate,
                            in: startDate...,
                            displayedComponents: .date
                        )

                        Toggle(isOn: $useCelsius) {
                            Text(useCelsius ? "celsius" : "fahrenheit")
                        }

                        Button(action: {
                            weatherService.fetchForecast(
                                city: city,
                                startDate: startDate,
                                endDate: endDate,
                                useCelsius: useCelsius
                            )
                        }) {
                            Text("check trip weather")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                    }
                    .padding()

                    if weatherService.isLoading {
                        ProgressView()
                            .padding()
                    }

                    if let error = weatherService.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }

                    if !weatherService.forecast.isEmpty {
                        VStack(spacing: 20) {
                            Text(weatherService.resolvedCity)
                                .font(.title)
                                .bold()

                            Text(countdownText)
                                .foregroundColor(.secondary)

                            Button(action: {
                                showShareSheet = true
                            }) {
                                Label("share trip forecast", systemImage: "square.and.arrow.up")
                            }

                            VStack(spacing: 12) {
                                ForEach(weatherService.forecast) { day in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(formattedDate(day.date))
                                                .bold()

                                            Text(
                                                weatherService.weatherDescription(
                                                    for: day.weatherCode
                                                )
                                            )
                                            .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        Text(
                                            "\(weatherService.weatherEmoji(for: day.weatherCode)) \(Int(day.high))° / \(Int(day.low))°"
                                        )
                                        .font(.headline)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(.secondarySystemBackground))
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [shareText])
        }
    }

    func formattedDate(_ string: String) -> String {
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"

        let output = DateFormatter()
        output.dateFormat = "MMM d"

        guard let date = input.date(from: string) else {
            return string
        }

        return output.string(from: date)
    }
}
