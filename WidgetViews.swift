//
//  WidgetViews.swift
//  Chet
//
//  Created by gian singh on 9/1/25.
//

import Foundation
import SwiftUI
import WidgetKit

struct LockScreenInLineView: View {
    let entry: RandSbdForWidget
    let fontType: String
    let selectedVisraamSource: String
    let larivaarOn: Bool
    let larivaarAssist: Bool
    let colorScheme: ColorScheme

    var body: some View {
        if let verse = entry.sbd.verses.first {
            getGurbaniLine(verse, fontType: fontType, selectedVisraamSource: selectedVisraamSource, larivaarOn: larivaarOn, larivaarAssist: larivaarAssist, colorScheme: colorScheme)
                .font(.caption2)
                .lineLimit(1)
        } else {
            Text("Vaheguru").font(.caption2)
        }
    }
}

struct LockScreenRectangularView: View {
    let entry: RandSbdForWidget
    let fontType: String
    let selectedVisraamSource: String
    let larivaarOn: Bool
    let larivaarAssist: Bool
    let selectedEnglishSource: String
    let selectedTransliterationSource: String
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let verse = entry.sbd.verses.first {
                getGurbaniLine(verse, fontType: fontType, selectedVisraamSource: selectedVisraamSource, larivaarOn: larivaarOn, larivaarAssist: larivaarAssist, colorScheme: colorScheme)
                    .font(.headline)
                    .lineLimit(2)

                if let transliteration = verse.transliteration.value(for: selectedTransliterationSource) {
                    Text(transliteration)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let translation = verse.translation.getTranslation(for: "english", source: selectedEnglishSource) {
                    Text(translation)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct HomeScreenView: View {
    let entry: RandSbdForWidget
    let heading: String?
    let fontType: String
    let selectedVisraamSource: String
    let larivaarOn: Bool
    let larivaarAssist: Bool
    let selectedEnglishSource: String
    let selectedPunjabiSource: String
    let selectedHindiSource: String
    let selectedSpanishSource: String
    let selectedTransliterationSource: String
    let lines: Int
    let colorScheme: ColorScheme


    var body: some View {
        let verses = getVerses()

        ZStack(alignment: .topTrailing) { // 👈 this line fixes the position
            VStack(alignment: .leading) {
                HStack {
                    if let heading = heading {
                        Text(heading)
                            .font(.caption)
                            .bold()
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                ForEach(verses, id: \.verseId) { verse in
                    VStack(alignment: .leading, spacing: 2) {
                        getGurbaniLine(verse, fontType: fontType, selectedVisraamSource: selectedVisraamSource, larivaarOn: larivaarOn, larivaarAssist: larivaarAssist, colorScheme: colorScheme)
                            .font(.headline)
                            .lineLimit(2)

                        if let transliteration = verse.transliteration.value(for: selectedTransliterationSource) {
                            Text(transliteration)
                                .font(.caption2)
                                .lineLimit(1)
                                .foregroundColor(.secondary.opacity(0.8))
                        }

                        if let translation = verse.translation.getTranslation(for: "english", source: selectedEnglishSource) {
                            Text(translation)
                                .font(.caption2)
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                        }

                        if let translation = verse.translation.getTranslation(for: "punjabi", source: selectedPunjabiSource) {
                            Text(translation)
                                .font(.caption2)
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                        }

                        if let translation = verse.translation.getTranslation(for: "hindi", source: selectedHindiSource) {
                            Text(translation)
                                .font(.caption2)
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                        }

                        if let translation = verse.translation.getTranslation(for: "spanish", source: selectedSpanishSource) {
                            Text(translation)
                                .font(.caption2)
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Link(destination: URL(string: "chet://search")!) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.primary)
                    .padding(6)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
                    .padding(.top, -2)
                    .padding(.trailing, -12)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    func getVerses() -> [Verse] {
        let allVerses = entry.sbd.verses
        let total = allVerses.count
        let index = entry.index
        let count = lines

        // If total verses are fewer than the desired lines, just return all
        guard total > count else {
            return allVerses
        }

        var start = index // Calculate start index
        // If not enough verses remain from index to the end, shift start backward
        if start + count > total {
            start = max(total - count, 0)
        }

        // Compute the end index safely
        let end = min(start + count, total)
        print("start: \(start), end: \(end)")
        return Array(allVerses[start ..< end])
    }
}

struct WidgetEntryView: View {
    let entry: RandSbdForWidget
    let heading: String?
    var the_heading: String {
        if let heading = heading {
            return heading + "  " + getWidgetHeadingFromSbdInfo(entry.sbd.shabadInfo)
        } else {
            return getWidgetHeadingFromSbdInfo(entry.sbd.shabadInfo)
        }
    }

    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("fontType") private var fontType = "Unicode"
    @AppStorage("settings.visraamSource") private var selectedVisraamSource = "igurbani"
    @AppStorage("settings.larivaarOn") private var larivaarOn = false
    @AppStorage("settings.larivaarAssist") private var larivaarAssist = false
    @AppStorage("settings.englishSource") private var selectedEnglishSource = "bdb"
    @AppStorage("settings.punjabiSource") private var selectedPunjabiSource = "none"
    @AppStorage("settings.hindiSource") private var selectedHindiSource = "none"
    @AppStorage("settings.spanishSource") private var selectedSpanishSource = "none"
    @AppStorage("settings.transliterationSource") private var selectedTransliterationSource = "none"

    var body: some View {
        switch widgetFamily {
        case .accessoryInline:
            LockScreenInLineView(entry: entry, fontType: fontType, selectedVisraamSource: selectedVisraamSource, larivaarOn: larivaarOn, larivaarAssist: larivaarAssist, colorScheme: colorScheme)
        case .accessoryRectangular:
            LockScreenRectangularView(entry: entry, fontType: fontType, selectedVisraamSource: selectedVisraamSource, larivaarOn: larivaarOn, larivaarAssist: larivaarAssist, selectedEnglishSource: selectedEnglishSource, selectedTransliterationSource: selectedTransliterationSource, colorScheme: colorScheme)
        case .systemSmall:
            HomeScreenView(entry: entry, heading: the_heading, fontType: fontType, selectedVisraamSource: selectedVisraamSource, larivaarOn: larivaarOn, larivaarAssist: larivaarAssist, selectedEnglishSource: selectedEnglishSource, selectedPunjabiSource: selectedPunjabiSource, selectedHindiSource: selectedHindiSource, selectedSpanishSource: selectedSpanishSource, selectedTransliterationSource: selectedTransliterationSource, lines: 3, colorScheme: colorScheme)
        case .systemMedium:
            HomeScreenView(entry: entry, heading: the_heading, fontType: fontType, selectedVisraamSource: selectedVisraamSource, larivaarOn: larivaarOn, larivaarAssist: larivaarAssist, selectedEnglishSource: selectedEnglishSource, selectedPunjabiSource: selectedPunjabiSource, selectedHindiSource: selectedHindiSource, selectedSpanishSource: selectedSpanishSource, selectedTransliterationSource: selectedTransliterationSource, lines: 3, colorScheme: colorScheme)
        case .systemLarge:
            HomeScreenView(entry: entry, heading: the_heading, fontType: fontType, selectedVisraamSource: selectedVisraamSource, larivaarOn: larivaarOn, larivaarAssist: larivaarAssist, selectedEnglishSource: selectedEnglishSource, selectedPunjabiSource: selectedPunjabiSource, selectedHindiSource: selectedHindiSource, selectedSpanishSource: selectedSpanishSource, selectedTransliterationSource: selectedTransliterationSource, lines: 5, colorScheme: colorScheme)
        default:
            Text("Vaheguru")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

func getGurbaniLine(_ verse: Verse, fontType: String, selectedVisraamSource: String, larivaarOn: Bool, larivaarAssist: Bool, colorScheme: ColorScheme) -> Text {
    // Choose between larivaar and regular text
    let text: String
    let isLarivaarMode = larivaarOn || larivaarAssist

    if isLarivaarMode {
        text = fontType == "Unicode" ? verse.larivaar.unicode : verse.larivaar.gurmukhi
    } else {
        text = fontType == "Unicode" ? verse.verse.unicode : verse.verse.gurmukhi
    }

    let words = text.components(separatedBy: " ")

    // Get visraam points based on selected source
    var visraamPoints: [Int: String] = [:] // [position: type]
    if let visraam = verse.visraam {
        let selectedVisraamData: [Visraam.VisraamPoint]
        switch selectedVisraamSource {
        case "sttm":
            selectedVisraamData = visraam.sttm ?? []
        case "sttm2":
            selectedVisraamData = visraam.sttm2 ?? []
        case "igurbani":
            selectedVisraamData = visraam.igurbani ?? []
        default:
            selectedVisraamData = []
        }

        for point in selectedVisraamData {
            visraamPoints[point.p] = point.t
        }
    }

    var result = Text("")
    for (index, word) in words.enumerated() {
        let wordText: Text
        let color: Color

        // Check if this word has a visraam marker
        if let visraamType = visraamPoints[index] {
            // Word has visraam - always use visraam color regardless of assist mode
            switch visraamType {
            case "v": // small pause
                color = colorScheme == .dark ? Color(red: 1.0, green: 0.5, blue: 0.3) : Color(red: 0.9, green: 0.2, blue: 0.0)
            case "y": // big pause
                color = colorScheme == .dark ? Color(red: 0.3, green: 1.0, blue: 0.3) : Color(red: 0.0, green: 0.7, blue: 0.0)
            default:
                // Unknown visraam type - fall through to alternating colors if assist is on
                if larivaarAssist {
                    let isEvenWord = index % 2 == 0
                    color = isEvenWord
                        ? (colorScheme == .dark ? Color(red: 0.7, green: 0.85, blue: 1.0) : Color(red: 0.1, green: 0.2, blue: 0.6))
                        : (colorScheme == .dark ? Color(red: 1.0, green: 0.85, blue: 0.5) : Color(red: 0.6, green: 0.45, blue: 0.0))
                } else {
                    color = .primary
                }
            }
        } else if larivaarAssist {
            // No visraam marker - use alternating colors for larivaar assist
            let isEvenWord = index % 2 == 0
            color = isEvenWord
                ? (colorScheme == .dark ? Color(red: 0.7, green: 0.85, blue: 1.0) : Color(red: 0.1, green: 0.2, blue: 0.6))
                : (colorScheme == .dark ? Color(red: 1.0, green: 0.85, blue: 0.5) : Color(red: 0.6, green: 0.45, blue: 0.0))
        } else {
            // Normal mode - just primary color
            color = .primary
        }

        wordText = Text(word).foregroundColor(color)
        result = result + wordText

        // Add space between words only if not in larivaar or larivaar assist mode
        if index < words.count - 1 && !isLarivaarMode {
            result = result + Text(" ")
        }
    }

    return result
}

struct GradientView: View {
    var body: some View {
        LinearGradient(colors: [.blue.opacity(0.8), .teal.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
