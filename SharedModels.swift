//
//  SharedData.swift
//  Chet
//
//  Created by gian singh on 9/1/25.
//

import Foundation
import WidgetKit // for TimelineEntry

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

    struct PageName: Codable {
        let akhar: String
        let unicode: String
        let english: String
    }
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
    let linenum: Int?
    let firstletters: TextPair
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
