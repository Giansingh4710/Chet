//
//  SharedData.swift
//  Chet
//
//  Created by gian singh on 9/1/25.
//

import Foundation
import SwiftData

// import WidgetKit // for TimelineEntry

struct TextPair: Codable {
    let akhar: String
    let unicode: String
}

struct Translation: Codable {
    let english: English
    let punjabi: Punjabi
    let spanish: String
    struct English: Codable {
        let `default`: String
    }

    struct Punjabi: Codable {
        let `default`: TextPair
    }
}

struct Transliteration: Codable {
    let english: TransliterationText
    let devanagari: TransliterationText

    struct TransliterationText: Codable {
        let text: String
        let larivaar: String
    }
}

struct Source: Codable {
    let id: Int
    let akhar: String
    let unicode: String
    let english: String
    let length: Int
    let pageName: PageName
}

struct PageName: Codable {
    let akhar: String
    let unicode: String
    let english: String
}

struct Writer: Codable {
    let id: Int
    let akhar: String
    let unicode: String
    let english: String
}

struct Raag: Codable {
    let id: Int
    let akhar: String
    let unicode: String
    let english: String
    let startang: Int
    let endang: Int
    let raagwithpage: String
}

struct ShabadInfo: Codable {
    let shabadid: String
    let pageno: Int
    let source: Source
    let writer: Writer
    let raag: Raag
    let navigation: Navigation
    let count: Int

    struct Navigation: Codable {
        let previous: NavigationItem?
        let next: NavigationItem?

        struct NavigationItem: Codable {
            let id: String
        }
    }
}

struct LineOfShabad: Codable {
    let id: String
    let type: Int
    let gurmukhi: TextPair
    let larivaar: TextPair
    let translation: Translation
    let transliteration: Transliteration
    let firstletters: TextPair
    let linenum: Int?
}

struct ShabadLineWrapper: Codable {
    let line: LineOfShabad
}

struct ShabadAPIResponse: Codable {
    let shabadinfo: ShabadInfo
    let shabad: [ShabadLineWrapper]
    let error: Bool
}

struct HukamnamaAPIResponse: Codable {
    let date: DateInfo
    let hukamnamainfo: HukamnamaInfo
    let hukamnama: [ShabadLineWrapper]
    let error: Bool

    struct DateInfo: Codable {
        let gregorian: GregorianDate
        struct GregorianDate: Codable {
            let month: String
            let monthno: Int
            let date: Int
            let year: Int
            let day: String
        }
    }

    struct HukamnamaInfo: Codable {
        let shabadid: [String]
        let pageno: Int
        let source: Source
        let writer: Writer
        let raag: Raag
        let count: Int
    }
}

struct LineObjFromSearch: Codable, Identifiable {
    let id: String
    let shabadid: String
    let type: Int
    let gurmukhi: TextPair
    let larivaar: TextPair
    let translation: Translation
    let transliteration: Transliteration
    let firstletters: TextPair
    let source: Source
    let writer: Writer
    let raag: Raag
    let pageno: Int
    let lineno: Int?
}

struct GurbaniSearchAPIResponse: Codable {
    let inputvalues: InputValues
    let count: Int
    let shabads: [LineObjWrapper]
    let error: Bool

    struct InputValues: Codable {
        let searchvalue: String
        let searchtype: Int
        let source: Int
        let results: Int
        let skip: Int
    }

    struct LineObjWrapper: Codable {
        let shabad: LineObjFromSearch
    }
}

@Model
final class ShabadHistory {
    @Attribute(.unique) var shabadID: String
    @Relationship(deleteRule: .cascade) var sbdRes: ShabadAPIResponse
    var indexOfSelectedLine: Int
    var dateViewed: Date
    var isFavorite = false

    init(sbdRes: ShabadAPIResponse, indexOfSelectedLine: Int, isFavorite: Bool = false) {
        shabadID = sbdRes.shabadinfo.shabadid
        self.indexOfSelectedLine = indexOfSelectedLine
        self.sbdRes = sbdRes
        dateViewed = Date()
        self.isFavorite = isFavorite
    }
}

extension LineOfShabad {
    init(from searchLine: LineObjFromSearch) {
        id = searchLine.id
        type = searchLine.type
        gurmukhi = searchLine.gurmukhi
        larivaar = searchLine.larivaar
        translation = searchLine.translation
        transliteration = searchLine.transliteration
        linenum = searchLine.lineno // maps to lineno
        firstletters = searchLine.firstletters
    }
}

extension ModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([ShabadHistory.self])
        let config = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier("group.xyz.gians.Chet") // 👈 must match App Group ID
        )
        return try! ModelContainer(for: schema, configurations: [config])
    }()
}
