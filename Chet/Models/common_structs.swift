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
