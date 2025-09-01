struct LineObjFromSearch: Codable, Identifiable {
    let id: String
    let type: Int
    let shabadid: String
    let gurmukhi: TextPair
    let larivaar: TextPair
    let translation: Translation
    let transliteration: Transliteration
    let source: Source
    let writer: Writer
    let raag: Raag
    let firstletters: TextPair
    let pageno: Int
    let lineno: Int?


    struct Source: Codable {
        let id: Int
        let akhar: String
        let unicode: String
        let english: String
        let length: Int
        let pageName: TextPair
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
