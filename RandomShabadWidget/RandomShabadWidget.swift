//
//  RandomShabadWidget.swift
//  RandomShabadWidget
//
//  Created by gian singh on 9/1/25.
//

import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
    func placeholder(in _: Context) -> RandSbdForWidget {
        let sbd: ShabadAPIResponse = loadJSON(from: "random_sbd", as: ShabadAPIResponse.self)!
        return RandSbdForWidget(sbd: sbd, date: Date.now, index: 0)
    }

    func getSnapshot(in _: Context, completion: @escaping (RandSbdForWidget) -> Void) {
        if let historyData = UserDefaults.appGroup.data(forKey: "randShabadList"),
           let first = try? JSONDecoder().decode([RandSbdForWidget].self, from: historyData).first
        {
            completion(first)
        } else {
            let sbd: ShabadAPIResponse = loadJSON(from: "random_sbd", as: ShabadAPIResponse.self)!
            completion(RandSbdForWidget(sbd: sbd, date: Date.now, index: 0))
        }
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<RandSbdForWidget>) -> Void) {
        Task {
            if let saved = UserDefaults.appGroup.data(forKey: "randShabadList"),
               let savedEntries = try? JSONDecoder().decode([RandSbdForWidget].self, from: saved),
               let lastDate = savedEntries.last?.date
            {
                if Date() < lastDate {
                    // ✅ Still within current timeline → reuse saved
                    completion(Timeline(entries: savedEntries, policy: .after(lastDate)))
                    return
                }
            }

            // ❌ Expired or no saved entries → regenerate
            let randSbdRefreshInterval = UserDefaults.appGroup.integer(forKey: "randSbdRefreshInterval")
            let entries = await getRandShabads(interval: randSbdRefreshInterval > 0 ? randSbdRefreshInterval : 3)
            let lastDate = entries.last?.date
            completion(Timeline(entries: entries, policy: .after(lastDate ?? Date.now)))
        }
    }
}

struct RandomShabadWidgetEntryView: View {
    var entry: RandSbdForWidget
    var body: some View {
        WidgetEntryView(entry: entry, heading: "Random Shabad" + getWidgetHeadingFromSbdInfo(entry.sbd.shabadInfo))
            .widgetURL(URL(string: "chet://shabadid/\(entry.sbd.shabadInfo.shabadId)")) // custom deep link
    }
}

struct RandomShabadWidget: Widget {
    let kind: String = "RandomShabadWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                RandomShabadWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                RandomShabadWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Random Shabad")
        .description("This will show a Random Shabad")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryInline, .accessoryRectangular])
    }
}

// #Preview(as: .systemSmall) {
//     RandomShabadWidget()
// } timeline: {
//     RandSbdForWidget(sbd: SampleData.shabadResponse, date: Date.now, index: 0)
// }
//
// #Preview(as: .accessoryInline) {
//    RandomShabadWidget()
// } timeline: {
//     RandSbdForWidget(sbd: SampleData.shabadResponse, date: Date.now, index: 0)
// }
//
// #Preview(as: .accessoryRectangular) {
//    RandomShabadWidget()
// } timeline: {
//     RandSbdForWidget(sbd: SampleData.shabadResponse, date: Date.now, index: 0)
// }
//
// #Preview(as: .systemMedium) {
//    RandomShabadWidget()
// } timeline: {
//     RandSbdForWidget(sbd: SampleData.shabadResponse, date: Date.now, index: 0)
// }
//
// #Preview(as: .systemLarge) {
//    RandomShabadWidget()
// } timeline: {
//     RandSbdForWidget(sbd: SampleData.shabadResponse, date: Date.now, index: 0)
// }
