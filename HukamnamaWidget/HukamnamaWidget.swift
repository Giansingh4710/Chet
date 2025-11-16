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
        let hukam: HukamnamaAPIResponse = loadJSON(from: "hukam", as: HukamnamaAPIResponse.self)!
        let sbd = getSbdObjFromHukamObj(hukamObj: hukam)
        return RandSbdForWidget(sbd: sbd, date: Date.now, index: 0)
    }

    func getSnapshot(in _: Context, completion _: @escaping (RandSbdForWidget) -> Void) {
        let hukam: HukamnamaAPIResponse = loadJSON(from: "hukam", as: HukamnamaAPIResponse.self)!
        let sbd = getSbdObjFromHukamObj(hukamObj: hukam)
        RandSbdForWidget(sbd: sbd, date: Date.now, index: 0)
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<RandSbdForWidget>) -> Void) {
        fetchHukamWrapper { response in
            var entries: [RandSbdForWidget] = []
            let currentDate = Date()
            let nextRefreshDate = Calendar.current.date(byAdding: .hour, value: 24, to: currentDate)!
            let hukam = response!
            let sbd = getSbdObjFromHukamObj(hukamObj: hukam)
            let entry = RandSbdForWidget(sbd: sbd, date: currentDate, index: 0)
            entries.append(entry)
            let timeline = Timeline(entries: entries, policy: .after(nextRefreshDate))
            completion(timeline)
        }
    }
}

private func fetchHukamWrapper(completion: @escaping (HukamnamaAPIResponse?) -> Void) {
    Task {
        do {
            let response = try await fetchHukam()
            completion(response)
        } catch {
            completion(nil)
        }
    }
}

struct HukamnamaWidgetEntryView: View {
    // var entry: Provider.Entry
    var entry: RandSbdForWidget
    var body: some View {
        WidgetEntryView(entry: entry, heading: "Today's Hukamnama")
            .widgetURL(URL(string: "chet://shabadid/\(entry.sbd.shabadInfo.shabadId)")) // custom deep link
    }
}

struct HukamnamaWidget: Widget {
    let kind: String = "HukamnamaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                HukamnamaWidgetEntryView(entry: entry)
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
