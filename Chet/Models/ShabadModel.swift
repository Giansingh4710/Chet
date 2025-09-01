//
//  ShabadModel.swift
//  Chet
//
//  Created by gian singh on 8/29/25.
//

import Foundation

struct ShabadInfo: Codable {
    let shabadid: String
    let pageno: Int
    let source: Source
    let writer: Writer
    let raag: Raag
    let navigation: Navigation
    let count: Int

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

struct ShabadAPIResponse: Codable {
    let shabadinfo: ShabadInfo
    let shabad: [ShabadLineWrapper]
    let error: Bool

    struct ShabadLineWrapper: Codable {
        let line: LineOfShabad
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
