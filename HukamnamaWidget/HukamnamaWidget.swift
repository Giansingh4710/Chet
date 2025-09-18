//
//  HukamnamaWidget.swift
//  HukamnamaWidget
//
//  Created by gian singh on 9/1/25.
//

import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
    func placeholder(in _: Context) -> HukamEntry {
        HukamEntry(date: Date(), hukam: SampleData.hukamnamResponse)
    }

    func getSnapshot(in _: Context, completion: @escaping (HukamEntry) -> Void) {
        completion(HukamEntry(date: Date(), hukam: SampleData.hukamnamResponse))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<HukamEntry>) -> Void) {
        fetchHukamWrapper { response in
            var entries: [HukamEntry] = []
            let currentDate = Date()
            let entryDate = Calendar.current.date(byAdding: .hour, value: 24, to: currentDate)!
            let hukam = response ?? SampleData.emptyHukam
            let entry = HukamEntry(date: entryDate, hukam: hukam)
            entries.append(entry)

            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }
}

private func fetchHukamWrapper(completion: @escaping (HukamnamaAPIResponse?) -> Void) {
    Task {
        let response = await fetchHukam()
        completion(response)
    }
}

struct HukamEntry: TimelineEntry {
    let date: Date
    let hukam: HukamnamaAPIResponse
}

struct HukamnamaWidgetEntryView: View {
    var entry: Provider.Entry
    var body: some View {
        WidgetEntryView(the_shabad: entry.hukam.hukamnama, heading: "Today's Hukamnama")
            .widgetURL(URL(string: "chet://shabadid/\(entry.hukam.hukamnamainfo.shabadid[0])")) // custom deep link
    }
}

struct HukamnamaWidget: Widget {
    let kind: String = "HukamnamaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                HukamnamaWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                HukamnamaWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Daily Hukamnama")
        .description("This will show a Daily Darbar Sahib hukamnama")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryInline, .accessoryRectangular])
    }
}

#Preview(as: .accessoryInline) {
    HukamnamaWidget()
} timeline: {
    HukamEntry(date: Date.now, hukam: SampleData.hukamnamResponse)
}

#Preview(as: .accessoryRectangular) {
    HukamnamaWidget()
} timeline: {
    HukamEntry(date: Date.now, hukam: SampleData.hukamnamResponse)
}

#Preview(as: .systemSmall) {
    HukamnamaWidget()
} timeline: {
    HukamEntry(date: Date.now, hukam: SampleData.hukamnamResponse)
}

#Preview(as: .systemMedium) {
    HukamnamaWidget()
} timeline: {
    HukamEntry(date: Date.now, hukam: SampleData.hukamnamResponse)
}

#Preview(as: .systemLarge) {
    HukamnamaWidget()
} timeline: {
    HukamEntry(date: Date.now, hukam: SampleData.hukamnamResponse)
}
