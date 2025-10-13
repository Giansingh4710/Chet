//
//  HukamnamaWidget.swift
//  HukamnamaWidget
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
        RandSbdForWidget(sbd: SampleData.shabadResponse, date: Date.now, index: 0)
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<RandSbdForWidget>) -> Void) {
        fetchHukamWrapper { response in
            var entries: [RandSbdForWidget] = []
            let currentDate = Date()
            let entryDate = Calendar.current.date(byAdding: .hour, value: 24, to: currentDate)!
            // let hukam = response ?? SampleData.emptyHukam
            let hukam = response ?? SampleData.shabadResponse
            let entry = RandSbdForWidget(sbd: hukam, date: Date.now, index: 0)
            entries.append(entry)

            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }
}

private func fetchHukamWrapper(completion: @escaping (ShabadAPIResponse?) -> Void) {
    Task {
        let response = await fetchHukam()
        completion(response)
    }
}

struct HukamnamaWidgetEntryView: View {
    // var entry: Provider.Entry
    var entry: RandSbdForWidget
    var body: some View {
        WidgetEntryView(entry: entry, heading: "Today's Hukamnama")
            .widgetURL(URL(string: "chet://shabadid/\(entry.sbd.shabadinfo.shabadid)")) // custom deep link
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

// #Preview(as: .accessoryInline) {
//     HukamnamaWidget()
// } timeline: {
//     HukamEntry(date: Date.now, hukam: SampleData.hukamnamResponse)
// }
//
// #Preview(as: .accessoryRectangular) {
//     HukamnamaWidget()
// } timeline: {
//     HukamEntry(date: Date.now, hukam: SampleData.hukamnamResponse)
// }
//
// #Preview(as: .systemSmall) {
//     HukamnamaWidget()
// } timeline: {
//     HukamEntry(date: Date.now, hukam: SampleData.hukamnamResponse)
// }
//
// #Preview(as: .systemMedium) {
//     HukamnamaWidget()
// } timeline: {
//     HukamEntry(date: Date.now, hukam: SampleData.hukamnamResponse)
// }
//
// #Preview(as: .systemLarge) {
//     HukamnamaWidget()
// } timeline: {
//     HukamEntry(date: Date.now, hukam: SampleData.hukamnamResponse)
// }
