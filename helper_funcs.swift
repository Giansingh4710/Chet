//
//  helper_funcs.swift
//  Chet
//
//  Created by gian singh on 9/1/25.
//

import Foundation

func fetchRandomShabad() async -> ShabadAPIResponse? {
    let urlString = "https://data.gurbaninow.com/v2/shabad/random"
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        return nil
    }

    do {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // follow redirects manually
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check if it's a redirect
        if let httpResponse = response as? HTTPURLResponse,
           (300 ... 399).contains(httpResponse.statusCode),
           let location = httpResponse.value(forHTTPHeaderField: "Location"),
           let redirectURL = URL(string: "https://data.gurbaninow.com\(location)")
        {
            let (redirectData, redirectResponse) = try await URLSession.shared.data(from: redirectURL)
            guard let finalHttpResponse = redirectResponse as? HTTPURLResponse,
                  (200 ... 299).contains(finalHttpResponse.statusCode)
            else {
                print("Bad final response")
                return nil
            }
            return try JSONDecoder().decode(ShabadAPIResponse.self, from: redirectData)
        } else {
            // Sometimes server may return directly
            return try JSONDecoder().decode(ShabadAPIResponse.self, from: data)
        }
    } catch {
        print("Error fetching random shabad: \(error.localizedDescription)")
        return nil
    }
}

func fetchHukam() async -> HukamnamaAPIResponse? {
    let urlString = "https://data.gurbaninow.com/v2/hukamnama/today"
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        return nil
    }

    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200 ... 299).contains(httpResponse.statusCode)
        else {
            throw URLError(.badServerResponse)
        }
        print(data)
        let decoded = try JSONDecoder().decode(HukamnamaAPIResponse.self, from: data)
        return decoded
    } catch let DecodingError.keyNotFound(key, context) {
        print("❌ Missing key:", key.stringValue, "in", context.codingPath)
    } catch let DecodingError.typeMismatch(type, context) {
        print("❌ Type mismatch for type:", type, "in", context.codingPath)
        print("Context debugDescription:", context.debugDescription)
    } catch let DecodingError.valueNotFound(value, context) {
        print("❌ Missing value:", value, "in", context.codingPath)
    } catch let DecodingError.dataCorrupted(context) {
        print("❌ Data corrupted:", context.debugDescription)
    } catch {
        print("❌ Other error:", error)
        print("Error fetching random shabad: \(error.localizedDescription)")
    }
    return nil
}
