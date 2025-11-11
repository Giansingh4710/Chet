//
//  helper_funcs.swift
//  Chet
//
//  Created by gian singh on 9/1/25.
//

import Foundation
import SwiftUICore // for Font
import UIKit

func fetchRandomShabad() async -> ShabadAPIResponse? {
    let urlString = "https://api.banidb.com/v2/random"
    guard let url = URL(string: urlString) else {
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
                return nil
            }
            return try JSONDecoder().decode(ShabadAPIResponse.self, from: redirectData)
        } else {
            // Sometimes server may return directly
            return try JSONDecoder().decode(ShabadAPIResponse.self, from: data)
        }
    } catch {
        return nil
    }
}

func fetchHukam(for date: Date = Date()) async throws -> HukamnamaAPIResponse {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month, .day], from: date)
    guard let year = components.year,
          let month = components.month,
          let day = components.day
    else {
        throw URLError(.badURL)
    }

    let urlString = "https://api.banidb.com/v2/hukamnamas/\(year)/\(month)/\(day)"
    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let httpResponse = response as? HTTPURLResponse,
          (200 ... 299).contains(httpResponse.statusCode)
    else {
        throw URLError(.badServerResponse)
    }
    return try JSONDecoder().decode(HukamnamaAPIResponse.self, from: data)
}

func getSbdObjFromHukamObj(hukamObj: HukamnamaAPIResponse) -> ShabadAPIResponse {
    guard !hukamObj.shabads.isEmpty else {
        return hukamObj.shabads[0]
    }

    var combined = hukamObj.shabads[0]
    if hukamObj.shabads.count > 1 {
        var allVerses: [Verse] = []
        for shabad in hukamObj.shabads {
            allVerses.append(contentsOf: shabad.verses)
        }
        combined = ShabadAPIResponse(
            shabadInfo: combined.shabadInfo,
            count: allVerses.count,
            navigation: combined.navigation,
            verses: allVerses
        )
    }

    return combined
}

func searchGurbani(from searchText: String, queryString: String = "searchtype=0") async throws -> GurbaniSearchAPIResponse {
    let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
        print("❌ Empty search text")
        throw URLError(.badURL)
    }

    let query = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
    let urlString = "https://api.banidb.com/v2/search/\(query)?\(queryString)&results=200"

    print("🌐 API URL: \(urlString)")

    guard let url = URL(string: urlString) else {
        print("❌ Invalid URL: \(urlString)")
        throw URLError(.badURL)
    }

    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ No HTTP response")
        throw URLError(.badServerResponse)
    }

    print("📡 HTTP Status: \(httpResponse.statusCode)")

    guard (200 ... 299).contains(httpResponse.statusCode) else {
        print("❌ Bad status code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("❌ Response body: \(responseString)")
        }
        throw URLError(.badServerResponse)
    }

    do {
        let decoded = try JSONDecoder().decode(GurbaniSearchAPIResponse.self, from: data)
        return decoded
    } catch {
        print("❌ JSON Decode Error: \(error)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("❌ Raw response: \(responseString.prefix(500))")
        }
        throw error
    }
}

func searchGurbaniExact(from searchText: String) async throws -> GurbaniSearchAPIResponse {
    let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
        throw URLError(.badURL)
    }

    let query = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
    let urlString = "https://api.banidb.com/v2/search/\(query)?searchtype=4"

    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }

    let (data, response) = try await URLSession.shared.data(from: url)
    guard let httpResponse = response as? HTTPURLResponse,
          (200 ... 299).contains(httpResponse.statusCode)
    else {
        throw URLError(.badServerResponse)
    }

    return try JSONDecoder().decode(GurbaniSearchAPIResponse.self, from: data)
}

func fetchShabadResponse(from shabadId: Int) async throws -> ShabadAPIResponse {
    let urlString = "https://api.banidb.com/v2/shabads/\(shabadId)"
    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }

    let (data, response) = try await URLSession.shared.data(from: url)
    guard let httpResponse = response as? HTTPURLResponse,
          (200 ... 299).contains(httpResponse.statusCode)
    else {
        throw URLError(.badServerResponse)
    }

    return try JSONDecoder().decode(ShabadAPIResponse.self, from: data)
}

func fetchWordDefinition(word: String) async throws -> [WordDefinition] {
    let encodedWord = word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? word
    let urlString = "https://api.banidb.com/v2/kosh/word/\(encodedWord)"

    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }

    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
    }

    guard (200 ... 299).contains(httpResponse.statusCode) else {
        throw URLError(.badServerResponse)
    }

    let decoded = try JSONDecoder().decode([WordDefinition].self, from: data)
    return decoded
}

func getFirstLetters(from text: String) -> String {
    let matras: Set<Character> = [
        "i", "o", "u", "w", "y", "H", "I", "M", "N", "O", "R", "U", "W", "Y", "`", "~", "@", "†", "ü", "®", "µ", "æ", "ƒ", "œ", "Í", "Ï", "Ò", "Ú", "§", "¤", "ç", "Î", "ï", "î",
    ]
    let subs: [Character: Character] = [
        "E": "a",
    ]

    let words = text.components(separatedBy: .whitespacesAndNewlines)
        .filter { !$0.isEmpty }
    var initials = ""

    for word in words {
        if word.contains("]") {
            break
        }

        if let first = word.first(where: { !matras.contains($0) }) {
            if let sub = subs[first] {
                initials.append(sub)
            } else {
                initials.append(first)
            }
        }
    }

    return initials
}

func getWidgetHeadingFromSbdInfo(_ info: ShabadInfo) -> String {
    var metaData = ""
    if let writerId = info.writer.writerId {
        switch writerId {
        case 1:
            metaData = "(ਪ:੧)"
        case 2:
            metaData = "(ਪ:੨)"
        case 3:
            metaData = "(ਪ:੩)"
        case 4:
            metaData = "(ਪ:੪)"
        case 5:
            metaData = "(ਪ:੫)"
        case 6:
            metaData = "(ਪ:੯)"
        case 7:
            metaData = "(ਪ:੧੦)"
        default:
            metaData = "(" + (info.writer.english ?? "Unknown") + ")"
        }
    } else {
        metaData = "(" + (info.writer.english ?? "Unknown") + ")"
    }
    return metaData
}

func getRandShabads(interval: Int) async -> [RandSbdForWidget] {
    var newList: [RandSbdForWidget] = []
    for offset in 0 ..< (24 / interval) {
        let entryDate = Calendar.current.date(byAdding: .hour, value: offset * interval, to: Date())!
        if let response = await fetchRandomShabad() { // your API call
            newList.append(RandSbdForWidget(sbd: response, date: entryDate, index: 0))
        }
    }
    if let encoded = try? JSONEncoder().encode(newList) { // Save to shared defaults for widget + app
        await MainActor.run {
            UserDefaults.appGroup.set(encoded, forKey: "randShabadList")
        }
    }
    return newList
}

func loadJSON<T: Decodable>(from fileName: String, as _: T.Type = T.self) -> T? {
    guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
        return nil
    }

    do {
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(T.self, from: data)
        return decoded
    } catch {
        return nil
    }
}

func resolveFont(size: Double, fontType: String) -> Font {
    if fontType == "Unicode" {
        return .system(size: size)
    } else {
        return .custom(fontType, size: size) // ⚠️ Important: the tag must match the *PostScript name* of the font, not necessarily the filename (use Font Book to check)
    }
}

func resolveFont(size: CGFloat, fontType: String) -> UIFont {
    // Swift will automatically pick the right one based on context — Font when used in SwiftUI, UIFont when used in UIKit.
    if fontType == "Unicode" {
        return .systemFont(ofSize: size)
    } else {
        return UIFont(name: fontType, size: size) ?? .systemFont(ofSize: size)
    }
}

func getCustomSrcName(_ source: Source) -> String {
    guard let sourceId = source.sourceId else {
        return source.english ?? "Unknown"
    }

    switch sourceId {
    case "G": return "SGGS" // Sri Guru Granth Sahib Ji
    case "D": return source.english ?? "Dasam Bani"
    case "B": return source.english ?? "Bhai Gurdas Ji Vaaran"
    case "A": return source.english ?? "Amrit Keertan"
    case "S": return source.english ?? "Bhai Gurdas Singh Ji Vaaran"
    case "N": return source.english ?? "Bhai Nand Lal Ji Vaaran"
    case "R": return source.english ?? "Rehatnamas & Panthic Sources"
    default: return sourceId
    }
}
