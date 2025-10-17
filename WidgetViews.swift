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

    var body: some View {
        if let verse = entry.sbd.verses.first {
            getGurbaniLine(verse, fontType: fontType, selectedVisraamSource: selectedVisraamSource)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let verse = entry.sbd.verses.first {
                getGurbaniLine(verse, fontType: fontType, selectedVisraamSource: selectedVisraamSource)
                    .font(.headline)
                    .lineLimit(2)
                if let a = verse.translation.en.bdb {
                    Text(a)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
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
    let prefix: Int

    var body: some View {
        let verses = entry.sbd.verses.prefix(prefix)
        VStack(alignment: .leading) {
            if let heading = heading {
                Text(heading)
                    .font(.caption)
                    .bold()
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }

            ForEach(verses, id: \.verseId) { verse in
                VStack(alignment: .leading) {
                    getGurbaniLine(verse, fontType: fontType, selectedVisraamSource: selectedVisraamSource)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)

                    if let a = verse.translation.en.bdb {
                        Text(a)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

struct HomeScreenSmallView: View {
    let entry: RandSbdForWidget
    let heading: String?
    let fontType: String
    let selectedVisraamSource: String

    var body: some View {
        let verses = entry.sbd.verses.prefix(3)
        VStack(alignment: .leading) {
            if let heading = heading {
                Text(heading)
                    .font(.caption)
                    .bold()
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }

            ForEach(verses, id: \.verseId) { verse in
                VStack(alignment: .leading) {
                    getGurbaniLine(verse, fontType: fontType, selectedVisraamSource: selectedVisraamSource)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)

                    if let a = verse.translation.en.bdb {
                        Text(a)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

struct HomeScreenMediumView: View {
    let entry: RandSbdForWidget
    let heading: String?
    let fontType: String
    let selectedVisraamSource: String

    var body: some View {
        let verses = entry.sbd.verses.prefix(4)
        VStack(alignment: .leading) {
            if let heading = heading {
                Text(heading)
                    .font(.caption)
                    .bold()
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }

            ForEach(verses, id: \.verseId) { verse in
                VStack(alignment: .leading) {
                    getGurbaniLine(verse, fontType: fontType, selectedVisraamSource: selectedVisraamSource)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)

                    if let a = verse.translation.en.bdb {
                        Text(a)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

struct HomeScreenLargeView: View {
    let entry: RandSbdForWidget
    let heading: String?

    let fontType: String
    let selectedVisraamSource: String

    var body: some View {
        let verses = entry.sbd.verses.prefix(5)
        let shabadInfo = entry.sbd.shabadInfo

        ZStack {
            VStack(alignment: .leading, spacing: 8) {
                if let heading = heading {
                    Text(heading.uppercased())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(verses, id: \.verseId) { verse in
                    VStack(alignment: .leading, spacing: 3) {
                        getGurbaniLine(verse, fontType: fontType, selectedVisraamSource: selectedVisraamSource)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(2)

                        if let a = verse.translation.en.bdb {
                            Text(a)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct WidgetEntryView: View {
    let entry: RandSbdForWidget
    let heading: String?
    @Environment(\.widgetFamily) var widgetFamily

    @AppStorage("fontType") private var fontType = "Unicode"
    @AppStorage("settings.visraamSource") private var selectedVisraamSource = "igurbani"

    var body: some View {
        switch widgetFamily {
        case .accessoryInline:
            LockScreenInLineView(entry: entry, fontType: fontType, selectedVisraamSource: selectedVisraamSource)
        case .accessoryRectangular:
            LockScreenRectangularView(entry: entry, fontType: fontType, selectedVisraamSource: selectedVisraamSource)
        case .systemSmall:
            // HomeScreenSmallView(entry: entry, heading: heading, fontType: fontType, selectedVisraamSource: selectedVisraamSource)
            HomeScreenView(entry: entry, heading: heading, fontType: fontType, selectedVisraamSource: selectedVisraamSource, prefix: 3)
        case .systemMedium:
            // HomeScreenMediumView(entry: entry, heading: heading, fontType: fontType, selectedVisraamSource: selectedVisraamSource)
            HomeScreenView(entry: entry, heading: heading, fontType: fontType, selectedVisraamSource: selectedVisraamSource, prefix: 3)
        case .systemLarge:
            // HomeScreenLargeView(entry: entry, heading: heading, fontType: fontType, selectedVisraamSource: selectedVisraamSource)
            HomeScreenView(entry: entry, heading: heading, fontType: fontType, selectedVisraamSource: selectedVisraamSource, prefix: 5)
        default:
            Text("Vaheguru")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

extension Array {
    func limited(for family: WidgetFamily) -> [Element] {
        switch family {
        case .systemSmall:
            return Array(prefix(1))
        case .systemMedium:
            return Array(prefix(2))
        case .systemLarge:
            return Array(prefix(4))
        case .accessoryRectangular:
            return Array(prefix(1))
        case .accessoryInline:
            return Array(prefix(1))
        default:
            return Array(prefix(1))
        }
    }
}

func getGurbaniLine(_ verse: Verse, fontType: String, selectedVisraamSource: String) -> Text {
    // let text = lineLarivaar ? verse.larivaar.unicode : verse.verse.unicode
    let text = fontType == "Unicode" ? verse.verse.unicode : verse.verse.gurmukhi
    let words = text.components(separatedBy: " ")

    // @Environment(\.colorScheme) var colorScheme
    var colorScheme: ColorScheme = .light

    // Get visraam points based on selected source
    var visraamPoints: [Int: String] = [:] // [position: type]
    if let visraam = verse.visraam {
        let selectedVisraamData: [Visraam.VisraamPoint]
        switch selectedVisraamSource {
        case "sttm":
            selectedVisraamData = visraam.sttm
        case "sttm2":
            selectedVisraamData = visraam.sttm2
        case "igurbani":
            selectedVisraamData = visraam.igurbani
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

        if let visraamType = visraamPoints[index] {
            let color: Color
            switch visraamType {
            case "v": // small pause
                color = colorScheme == .dark ? Color(red: 1.0, green: 0.6, blue: 0.4) : Color(red: 0.8, green: 0.3, blue: 0.1)
            case "y": // big pause
                color = colorScheme == .dark ? Color(red: 0.4, green: 0.8, blue: 0.4) : Color(red: 0.2, green: 0.6, blue: 0.2)
            default:
                color = .primary
            }
            wordText = Text(word).foregroundColor(color)
        } else {
            wordText = Text(word)
        }

        result = result + wordText

        if index < words.count - 1 {
            // if !lineLarivaar { }
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
