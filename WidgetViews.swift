//
//  WidgetViews.swift
//  Chet
//
//  Created by gian singh on 9/1/25.
//

import Foundation
import SwiftUI
import WidgetKit

private func getFontForLine(_ line: LineOfShabad) -> Font {
    if line.type == 2 { // Heading
        return .system(size: 11, weight: .regular)
    } else if line.type == 3 { // Rahao lines
        return .system(size: 14, weight: .medium)
    } else {
        return .system(size: 12, weight: .regular)
    }
}

private func showOneLine(_ sbdLines: [ShabadLineWrapper]) -> String {
    // will try to find Rahao. if not then first non header // line.type 2=heading, 3=rahaho 4=normal
    for obj in sbdLines {
        if obj.line.type == 3 {
            return obj.line.gurmukhi.unicode
        }
    }
    for obj in sbdLines {
        if obj.line.type == 4 {
            return obj.line.gurmukhi.unicode
        }
    }
    return sbdLines.first?.line.gurmukhi.unicode ?? "Vaheguru"
}

struct LockScreenInLineView: View {
    let the_shabad: [ShabadLineWrapper]
    var body: some View {
        Text(showOneLine(the_shabad))
            .lineLimit(1)
            .minimumScaleFactor(0.7) // Allow text to scale down more to fit
    }
}
        
private func filterOutHeadings(_ the_shabad: [ShabadLineWrapper]) -> [ShabadLineWrapper]{
    // return the_shabad.filter { $0.line.type != 2 }.prefix(4).map { $0 }
    return the_shabad.filter { $0.line.type != 2 }.map { $0 }
}

struct LockScreenRectangularView: View {
    let the_shabad: [ShabadLineWrapper]
    var body: some View {
        VStack(alignment: .leading, spacing: 1) { // Reduced spacing
            ForEach(filterOutHeadings(the_shabad), id: \.line.id) { lineWrapper in
                Text(lineWrapper.line.gurmukhi.unicode)
                    .font(.system(size: 10)) // Smaller font size
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 4) // Add horizontal padding
    }
    private func getOptimizedLines() -> [ShabadLineWrapper] {
        return the_shabad.filter { $0.line.type != 2 }.prefix(4).map { $0 }
    }
}

struct HomeScreenSmallView: View {
    let the_shabad: [ShabadLineWrapper]
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
                Text(filterOutHeadings(the_shabad).map { $0.line.gurmukhi.unicode }.joined(separator: " "))
                    .font(.system(size: 16, weight: .medium)) // Smaller font
            }
            //.clipped() // Clip any content that exceeds the frame
        }
    }
}

// Enhanced medium view with more efficient space usage
struct HomeScreenMediumView: View {
    let the_shabad: [ShabadLineWrapper]
    let heading: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title = heading {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Use a grid layout for more efficient space usage
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], alignment: .leading, spacing: 4) {
                ForEach(getDisplayLines(), id: \.line.id) { lineWrapper in
                    VStack(alignment: .leading, spacing: 0) {
                        if lineWrapper.line.type == 2 {
                            Text(lineWrapper.line.gurmukhi.unicode)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else if lineWrapper.line.type == 3 {
                            Text(lineWrapper.line.gurmukhi.unicode)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(lineWrapper.line.gurmukhi.unicode)
                                .font(.system(size: 11))
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func getDisplayLines() -> [ShabadLineWrapper] {
        // For medium widget, show up to 8 lines intelligently
        let maxLines = 8
        let filteredLines = the_shabad.filter { $0.line.type != 2 || the_shabad.count <= 3 }
        return Array(filteredLines.prefix(maxLines))
    }
}

struct HomeScreenLargeView: View {
    let the_shabad: [ShabadLineWrapper]
    let heading: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title = heading {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 3) {
                    // Group lines by type for better organization
                    let headings = the_shabad.filter { $0.line.type == 2 }
                    let rahaoLines = the_shabad.filter { $0.line.type == 3 }
                    let normalLines = the_shabad.filter { $0.line.type == 4 }
                    
                    // Display headings first
                    if !headings.isEmpty {
                        ForEach(headings, id: \.line.id) { lineWrapper in
                            Text(lineWrapper.line.gurmukhi.unicode)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .padding(.top, 2)
                        }
                    }
                    
                    // Display Rahao lines with emphasis
                    if !rahaoLines.isEmpty {
                        ForEach(rahaoLines, id: \.line.id) { lineWrapper in
                            Text(lineWrapper.line.gurmukhi.unicode)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .padding(.vertical, 1)
                        }
                    }
                    
                    // Display normal lines in a grid for better space usage
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], alignment: .leading, spacing: 3) {
                        ForEach(normalLines, id: \.line.id) { lineWrapper in
                            Text(lineWrapper.line.gurmukhi.unicode)
                                .font(.system(size: 12))
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct WidgetEntryView: View {
    let the_shabad: [ShabadLineWrapper]
    let heading: String?
    @Environment(\.widgetFamily) var widgetFamily
    
    init(the_shabad: [ShabadLineWrapper], heading: String? = nil) {
        self.the_shabad = the_shabad
        self.heading = heading
    }

    var body: some View {
        switch widgetFamily {
        case .accessoryInline:
            LockScreenInLineView(the_shabad: the_shabad)
        case .accessoryRectangular:
            LockScreenRectangularView(the_shabad: the_shabad)
        case .systemSmall:
            HomeScreenSmallView(the_shabad: the_shabad, heading: heading)
        case .systemMedium:
            HomeScreenMediumView(the_shabad: the_shabad, heading: heading)
        case .systemLarge:
            HomeScreenLargeView(the_shabad: the_shabad, heading: heading)
        default:
            Text("Vaheguru")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
