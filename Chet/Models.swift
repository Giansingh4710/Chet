//
//  SharedData.swift
//  Chet
//
//  Created by gian singh on 9/1/25.
//

import Foundation
import SwiftData
import WidgetKit // for TimelineEntry

struct ShabadInfo: Codable {
    let shabadId: Int
    let shabadName: Int
    let pageNo: Int
    let source: Source
    let raag: Raag
    let writer: Writer
}

struct Source: Codable {
    let sourceId: String
    let gurmukhi: String
    let unicode: String
    let english: String
    let pageNo: Int
}

struct Raag: Codable {
    let raagId: Int
    let gurmukhi: String?
    let unicode: String?
    let english: String?
    let raagWithPage: String?
}

struct Writer: Codable {
    let writerId: Int
    let gurmukhi: String
    let unicode: String?
    let english: String
}

struct Navigation: Codable {
    let previous: Int?
    let next: Int?
}

struct Verse: Codable {
    let verseId: Int
    let shabadId: Int
    let verse: VerseText
    let larivaar: VerseText
    let translation: Translation
    let transliteration: Transliteration
    let pageNo: Int
    let lineNo: Int
    let updated: String
    let visraam: Visraam?
}

struct VerseText: Codable {
    let gurmukhi: String
    let unicode: String
}

struct Translation: Codable {
    let en: EnglishTranslation
    let pu: PunjabiTranslation
    let es: SpanishTranslation
    let hi: HindiTranslation
    struct EnglishTranslation: Codable {
        let bdb: String?
        let ms: String?
        let ssk: String?
    }

    struct PunjabiTranslation: Codable {
        let ss: TranslationText?
        let ft: TranslationText?
        let bdb: TranslationText?
        let ms: TranslationText?
    }

    struct SpanishTranslation: Codable {
        let sn: String?
    }

    struct HindiTranslation: Codable {
        let ss: String?
        let sts: String?
    }
}

struct TranslationText: Codable {
    let gurmukhi: String?
    let unicode: String?
}

struct Transliteration: Codable {
    let english: String
    let hindi: String
    let en: String
    let hi: String
    let ipa: String
    let ur: String
}

struct Visraam: Codable {
    let sttm: [VisraamPoint]
    let igurbani: [VisraamPoint]
    let sttm2: [VisraamPoint]

    struct VisraamPoint: Codable {
        let p: Int
        let t: String

        enum CodingKeys: String, CodingKey {
            case p, t
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // Try to decode p as Int
            if let intValue = try? container.decode(Int.self, forKey: .p) {
                p = intValue
            }
            // Otherwise try to decode as String and convert
            else if let stringValue = try? container.decode(String.self, forKey: .p),
                    let intValue = Int(stringValue)
            {
                p = intValue
            }
            // If neither works, throw error
            else {
                throw DecodingError.typeMismatch(
                    Int.self,
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Expected Int or String convertible to Int for key 'p'"
                    )
                )
            }

            t = try container.decode(String.self, forKey: .t)
        }
    }
}

struct HukamnamaDate: Codable {
    let gregorian: GregorianDate
    struct GregorianDate: Codable {
        let month: Int
        let date: Int
        let year: Int
    }
}

struct GurbaniSearchAPIResponse: Codable {
    let resultsInfo: ResultsInfo
    let verses: [SearchVerse]
    struct ResultsInfo: Codable {
        let totalResults: Int
        let pageResults: Int
        let pages: PageInfo
    }

    struct PageInfo: Codable {
        let page: Int
        let resultsPerPage: Int
        let totalPages: Int
    }
}

struct HukamnamaAPIResponse: Codable {
    let isLatest: Bool?
    let date: HukamnamaDate
    let shabadIds: [Int]
    let shabads: [ShabadAPIResponse]
}

struct ShabadAPIResponse: Codable {
    let shabadInfo: ShabadInfo
    let count: Int
    let navigation: Navigation
    let verses: [Verse]
}

struct SearchVerse: Codable, Identifiable {
    let verseId: Int
    let shabadId: Int
    let verse: VerseText
    let larivaar: VerseText
    let translation: Translation
    let transliteration: Transliteration
    let pageNo: Int
    let lineNo: Int
    let updated: String
    let visraam: Visraam?
    let writer: Writer
    let source: Source
    let raag: Raag

    var id: Int { verseId }
}

@Model
final class ShabadHistory {
    @Attribute(.unique) var shabadID: Int
    @Relationship(deleteRule: .cascade) var sbdRes: ShabadAPIResponse
    var indexOfSelectedLine: Int
    var dateViewed: Date

    init(sbdRes: ShabadAPIResponse, indexOfSelectedLine: Int) {
        shabadID = sbdRes.shabadInfo.shabadId
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
