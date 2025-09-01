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
    let the_shabad: [ShabadLineWrapper]
    var body: some View {
        Text(showOneLine(the_shabad)).lineLimit(1)
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
}

struct LockScreenRectangularView: View {
    let the_shabad: [ShabadLineWrapper]
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(getShabadForRectangle(the_shabad))
                .font(.caption)
                //.minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func getShabadForRectangle(_ sbdLines: [ShabadLineWrapper]) -> String {
        var theSbdTxt = ""
        for obj in sbdLines {
            if obj.line.type == 2 {
                continue
            } else {
                theSbdTxt += obj.line.gurmukhi.unicode
            }
        }
        return theSbdTxt
    }
}

struct HomeScreenSmallView: View {
    let the_shabad: [ShabadLineWrapper]
    let heading: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let title = heading {
                Text(title).font(.headline)
            }
            ForEach(the_shabad, id: \.line.id) { lineWrapper in
                if lineWrapper.line.type == 2 {
                    Text(lineWrapper.line.gurmukhi.unicode)
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .lineLimit(1)
                } else if lineWrapper.line.type == 3 {
                    Text(lineWrapper.line.gurmukhi.unicode)
                        .font(.headline)
                        .foregroundColor(.secondary)
                } else {
                    Text(lineWrapper.line.gurmukhi.unicode)
                        .font(.footnote)
                }
            }
        }
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
            HomeScreenSmallView(the_shabad: the_shabad, heading: heading)
        case .systemLarge:
            HomeScreenSmallView(the_shabad: the_shabad, heading: heading)
        default:
            Text("Default")
        }
    }
}
