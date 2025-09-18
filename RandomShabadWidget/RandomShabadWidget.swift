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
        RandSbdForWidget(sbd: SampleData.shabadResponse, date: Date.now, index: 0)
    }

    func getSnapshot(in _: Context, completion: @escaping (RandSbdForWidget) -> Void) {
        if let historyData = UserDefaults.appGroup.data(forKey: "randShabadList"),
           let first = try? JSONDecoder().decode([RandSbdForWidget].self, from: historyData).first
        {
            completion(first)
        } else {
            completion(RandSbdForWidget(sbd: SampleData.shabadResponse, date: Date.now, index: 0))
        }
    }


    func getTimeline(in _: Context, completion: @escaping (Timeline<RandSbdForWidget>) -> Void) {
        Task {
            let entries: [RandSbdForWidget]
            if let saved = UserDefaults.appGroup.data(forKey: "randShabadList"),
               let decoded = try? JSONDecoder().decode([RandSbdForWidget].self, from: saved)
            {
                entries = decoded
            } else {
                let refreshInterval = UserDefaults.appGroup.integer(forKey: "refreshInterval")
                entries = await getRandShabads(interval: refreshInterval > 0 ? refreshInterval : 3)
            }

            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }
}

// struct ShabadEntry: TimelineEntry {
//     let date: Date
//     let sbd: ShabadAPIResponse
//     let index: Int
// }

struct RandomShabadWidgetEntryView: View {
    var entry: RandSbdForWidget
    var body: some View {
        WidgetEntryView(the_shabad: entry.sbd.shabad, heading: "Random Shabad" + getWidgetHeadingFromSbdInfo(entry.sbd.shabadinfo))
            .widgetURL(URL(string: "chet://shabadid/\(entry.sbd.shabadinfo.shabadid)")) // custom deep link
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
        .description("This will show a Random Shabad every Pehar(3 hours)")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryInline, .accessoryRectangular])
    }
}

#Preview(as: .systemSmall) {
    RandomShabadWidget()
} timeline: {
    RandSbdForWidget(sbd: SampleData.shabadResponse, date: Date.now, index: 0)
}

// #Preview(as: .accessoryInline) {
//    RandomShabadWidget()
// } timeline: {
//    RandSbdForWidget(date: Date.now, sbd: SampleData.shabadResponse)
// }
//
// #Preview(as: .accessoryRectangular) {
//    RandomShabadWidget()
// } timeline: {
//    RandSbdForWidget(date: Date.now, sbd: SampleData.shabadResponse)
// }
//
// #Preview(as: .systemMedium) {
//    RandomShabadWidget()
// } timeline: {
//    RandSbdForWidget(date: Date.now, sbd: SampleData.shabadResponse)
// }
//
// #Preview(as: .systemLarge) {
//    RandomShabadWidget()
// } timeline: {
//    RandSbdForWidget(date: Date.now, sbd: SampleData.shabadResponse)
// }
