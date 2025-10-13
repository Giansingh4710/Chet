//
//  WidgetViews.swift
//  Chet
//
//  Created by gian singh on 9/1/25.
//

import Foundation
import SwiftUI
import WidgetKit

private func showOneLine(_ sbdLines: [Verse]) -> String {
    // will try to find Rahao. if not then first non header // line.type 2=heading, 3=rahaho 4=normal
    for obj in sbdLines {
        return obj.verse.gurmukhi
        // if obj.line.type == 3 { }
    }
    return "Vaheguru"
    
//    for obj in sbdLines {
//        if obj.line.type == 4 {
//            return obj.line.gurmukhi.unicode
//        }
//    }
//    return sbdLines.first?.line.gurmukhi.unicode ?? "Vaheguru"
}

struct LockScreenInLineView: View {
    let entry: RandSbdForWidget
    var body: some View {
        Text(showOneLine(entry.sbd.verses))
            .lineLimit(1)
            .minimumScaleFactor(0.7) // Allow text to scale down more to fit
    }
}

private func filterOutHeadings(_ the_shabad: [Verse]) -> [Verse] {
    return the_shabad.filter { $0.verse.unicode.contains(":") }.map { $0 }
}

struct LockScreenRectangularView: View {
    let entry: RandSbdForWidget
    var body: some View {
        VStack(alignment: .leading, spacing: 1) { // Reduced spacing
            ForEach(filterOutHeadings(entry.sbd.verses),id: \.verseId) { line in
                Text(line.verse.unicode)
                    .font(.system(size: 10)) // Smaller font size
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 4) // Add horizontal padding
    }
}

struct HomeScreenSmallView: View {
    let entry: RandSbdForWidget
    let heading: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) { // Reduced spacing for more content
            if let title = heading {
                Text(title)
                    .font(.system(size: 9, weight: .medium)) // Smaller font
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                // .padding(.bottom, 1) // Small padding below title
            }

            VStack(alignment: .leading) {
                Text(filterOutHeadings(entry.sbd.verses).map { $0.verse.unicode }.joined(separator: " "))
                    .font(.system(size: 16, weight: .medium)) // Smaller font
            }
            // .clipped() // Clip any content that exceeds the frame
        }
    }
}

// Enhanced medium view with more efficient space usage
struct HomeScreenMediumView: View {
    let entry: RandSbdForWidget
    let heading: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title = heading {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Text("Vahegru")
            }

            // Use a grid layout for more efficient space usage
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], alignment: .leading, spacing: 4) {
                ForEach(entry.sbd.verses, id: \.verseId) { line in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(line.verse.unicode)
                                .font(.system(size: 11))
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

//    private func getDisplayLines() -> [Verse] {
//        // For medium widget, show up to 8 lines intelligently
//        let maxLines = 8
//        let filteredLines = entry.sbd.shabad.filter { $0.line.type != 2 || entry.sbd.shabad.count <= 3 }
//        return Array(filteredLines.prefix(maxLines))
//    }
}

struct HomeScreenLargeView: View {
    let entry: RandSbdForWidget
    let heading: String?

    var body: some View {
        ZStack {
            // Background gradient — closer to your image
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.8, blue: 0.7),
                    Color(red: 0.7, green: 1.0, blue: 0.8),
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 10) {
                // Heading + Date
                VStack(alignment: .leading, spacing: 2) {
                    Text(heading ?? "Random Shabad (P:5)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.95))

                    Text(entry.date, style: .date)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                }

                // Gurbani lines
                if let firstLine = entry.sbd.verses.first {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(firstLine.verse.unicode)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(firstLine.translation.en.bdb)
                            .italic()
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 4)
                } else {
                    Text("No Shabad data available.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 8)
                }

                Spacer()

                // "View more" footer
                Text("View more")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.top, 4)
            }
            .padding(16)
        }
    }
}

struct WidgetEntryView: View {
    let entry: RandSbdForWidget
    let heading: String?
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .accessoryInline:
            LockScreenInLineView(entry: entry)
        case .accessoryRectangular:
            LockScreenRectangularView(entry: entry)
        case .systemSmall:
            HomeScreenSmallView(entry: entry, heading: heading)
        case .systemMedium:
            HomeScreenMediumView(entry: entry, heading: heading)
        case .systemLarge:
            HomeScreenLargeView(entry: entry, heading: heading)
        default:
            Text("Vaheguru")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
