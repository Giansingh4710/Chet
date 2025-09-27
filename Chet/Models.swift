//
//  SharedData.swift
//  Chet
//
//  Created by gian singh on 9/1/25.
//

import Foundation
import SwiftData
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

    init(sbdRes: ShabadAPIResponse, indexOfSelectedLine: Int) {
        shabadID = sbdRes.shabadinfo.shabadid
        self.indexOfSelectedLine = indexOfSelectedLine
        self.sbdRes = sbdRes
        dateViewed = Date()
    }
}

@Model
final class SavedShabad: Identifiable, Hashable {
    @Attribute(.unique) var id = UUID() // You'll need an ID for SavedShabad to conform to Identifiable and Hashable easily
    @Relationship(deleteRule: .nullify, inverse: \Folder.savedShabads) var folder: Folder?
    @Relationship(deleteRule: .nullify) var sbdRes: ShabadAPIResponse
    var indexOfSelectedLine: Int

    var sortIndex: Int
    var addedAt: Date

    init(folder: Folder, sbdRes: ShabadAPIResponse, indexOfSelectedLine: Int = 0, addedAt: Date = Date(), sortIndex: Int = 0) {
        id = UUID()
        self.folder = folder
        self.sbdRes = sbdRes
        self.indexOfSelectedLine = indexOfSelectedLine
        self.sortIndex = sortIndex
        self.addedAt = addedAt
    }

    static func == (lhs: SavedShabad, rhs: SavedShabad) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@Model
final class Folder: Identifiable, Hashable {
    @Attribute(.unique) var id: UUID
    var name: String
    var isSystemFolder: Bool = false // for "Widgets"

    @Relationship(deleteRule: .nullify)
    var parentFolder: Folder?

    @Relationship(deleteRule: .cascade, inverse: \Folder.parentFolder)
    var subfolders: [Folder]

    @Relationship(deleteRule: .cascade)
    var savedShabads: [SavedShabad] = []

    // Custom ordering
    var sortIndex: Int = 0

    // Computed property for OutlineGroup
    var subfoldersOrNil: [Folder]? {
        subfolders.isEmpty ? nil : subfolders.sorted { $0.name < $1.name }
    }

    init(name: String, parentFolder: Folder? = nil, subfolders: [Folder] = [], isSystemFolder: Bool = false, sortIndex: Int = 0) {
        id = UUID()
        self.name = name
        self.parentFolder = parentFolder
        self.subfolders = subfolders
        self.isSystemFolder = isSystemFolder
        self.sortIndex = sortIndex
    }

    static func == (lhs: Folder, rhs: Folder) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
        let schema = Schema([ShabadHistory.self, Folder.self, SavedShabad.self])
        let config = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier("group.xyz.gians.Chet") // 👈 must match App Group ID
        )
        let container = try! ModelContainer(for: schema, configurations: [config])

        // Prepopulate defaults
        Task {
            let context = ModelContext(container)
            let existing = try? context.fetch(FetchDescriptor<Folder>())

            if existing?.isEmpty ?? true {
                let defaults = [
                    Folder(name: default_fav_widget_folder_name, isSystemFolder: true),
                    Folder(name: "Keertan"),
                    // Folder(name: "Favorites", isSystemFolder: true),
                ]
                defaults.forEach { context.insert($0) }
                try? context.save()
            }
        }

        return container
    }()
}

extension UserDefaults { // for RandomShabadWidget data to be shown in app
    static let appGroup = UserDefaults(suiteName: "group.xyz.gians.Chet")!
}

struct RandSbdForWidget: Codable, TimelineEntry {
    let sbd: ShabadAPIResponse
    let date: Date
    let index: Int
}

let default_fav_widget_folder_name = "Favorites"
