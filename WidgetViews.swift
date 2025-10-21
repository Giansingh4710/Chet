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
    let colorScheme: ColorScheme

    var body: some View {
        if let verse = entry.sbd.verses.first {
            getGurbaniLine(verse, fontType: fontType, selectedVisraamSource: selectedVisraamSource, colorScheme: colorScheme)
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
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let verse = entry.sbd.verses.first {
                getGurbaniLine(verse, fontType: fontType, selectedVisraamSource: selectedVisraamSource, colorScheme: colorScheme)
                    .font(.headline)
                    .lineLimit(2)
                if let a = verse.translation.en.bdb {
                    Text(a)
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
    let prefix: Int
    let colorScheme: ColorScheme

    var body: some View {
        let verses = entry.sbd.verses.prefix(prefix)

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
                    VStack(alignment: .leading) {
                        getGurbaniLine(verse, fontType: fontType, selectedVisraamSource: selectedVisraamSource, colorScheme: colorScheme)
                            .font(.headline)
                            .lineLimit(2)

                        if let a = verse.translation.en.bdb {
                            Text(a)
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

    var body: some View {
        switch widgetFamily {
        case .accessoryInline:
            LockScreenInLineView(entry: entry, fontType: fontType, selectedVisraamSource: selectedVisraamSource, colorScheme: colorScheme)
        case .accessoryRectangular:
            LockScreenRectangularView(entry: entry, fontType: fontType, selectedVisraamSource: selectedVisraamSource, colorScheme: colorScheme)
        case .systemSmall:
            HomeScreenView(entry: entry, heading: the_heading, fontType: fontType, selectedVisraamSource: selectedVisraamSource, prefix: 3, colorScheme: colorScheme)
        case .systemMedium:
            HomeScreenView(entry: entry, heading: the_heading, fontType: fontType, selectedVisraamSource: selectedVisraamSource, prefix: 3, colorScheme: colorScheme)
        case .systemLarge:
            HomeScreenView(entry: entry, heading: the_heading, fontType: fontType, selectedVisraamSource: selectedVisraamSource, prefix: 5, colorScheme: colorScheme)
        default:
            Text("Vaheguru")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

func getGurbaniLine(_ verse: Verse, fontType: String, selectedVisraamSource: String, colorScheme: ColorScheme) -> Text {
    let text = fontType == "Unicode" ? verse.verse.unicode : verse.verse.gurmukhi
    let words = text.components(separatedBy: " ")

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
            wordText = Text(word).foregroundColor(.primary)
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
