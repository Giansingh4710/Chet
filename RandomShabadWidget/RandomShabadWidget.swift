//
//  RandomShabadWidget.swift
//  RandomShabadWidget
//
//  Created by gian singh on 9/1/25.
//

import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
    func placeholder(in _: Context) -> ShabadEntry {
        ShabadEntry(date: Date.now, sbd: SampleData.shabadResponse)
    }

    func getSnapshot(in _: Context, completion: @escaping (ShabadEntry) -> Void) {
        completion(ShabadEntry(date: Date.now, sbd: SampleData.shabadResponse))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<ShabadEntry>) -> Void) {
        fetchRandomShabadWrapper { response in

            var entries: [ShabadEntry] = []

            // Generate a timeline consisting of five entries an hour apart, starting from the current date.
            let currentDate = Date()
            for hourOffset in 0 ..< 8 {
                let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset * 3, to: currentDate)!
                let the_rand_sbd = response ?? SampleData.shabadResponse
                let entry = ShabadEntry(date: entryDate, sbd: the_rand_sbd)
                entries.append(entry)
            }

            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }
}

private func fetchRandomShabadWrapper(completion: @escaping (ShabadAPIResponse?) -> Void) {
    Task {
        let response = await fetchRandomShabad()
        completion(response)
    }
}

struct ShabadEntry: TimelineEntry {
    let date: Date
    let sbd: ShabadAPIResponse
}

struct RandomShabadWidgetEntryView: View {
    var entry: ShabadEntry
    var body: some View {
        WidgetEntryView(the_shabad: entry.sbd.shabad, heading: "Random Shabad")
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

#Preview(as: .accessoryInline) {
    RandomShabadWidget()
} timeline: {
    ShabadEntry(date: Date.now, sbd: SampleData.shabadResponse)
}

#Preview(as: .accessoryRectangular) {
    RandomShabadWidget()
} timeline: {
    ShabadEntry(date: Date.now, sbd: SampleData.shabadResponse)
}

#Preview(as: .systemSmall) {
    RandomShabadWidget()
} timeline: {
    ShabadEntry(date: Date.now, sbd: SampleData.shabadResponse)
}

#Preview(as: .systemMedium) {
    RandomShabadWidget()
} timeline: {
    ShabadEntry(date: Date.now, sbd: SampleData.shabadResponse)
}

#Preview(as: .systemLarge) {
    RandomShabadWidget()
} timeline: {
    ShabadEntry(date: Date.now, sbd: SampleData.shabadResponse)
}
