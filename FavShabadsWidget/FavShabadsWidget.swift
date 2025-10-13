//
//  FavShabadsWidget.swift
//  FavShabadsWidget
//
//  Created by gian singh on 9/1/25.
//

import SwiftData
import SwiftUI
import WidgetKit

struct Provider: @preconcurrency TimelineProvider {
    let modelContainer = ModelContainer.shared

    @MainActor func placeholder(in _: Context) -> RandSbdForWidget {
        let sbd: ShabadAPIResponse = loadJSON(from: "random_sbd", as: ShabadAPIResponse.self)!
        return RandSbdForWidget(sbd: sbd, date: Date.now, index: 0)
    }

    @MainActor func getSnapshot(in _: Context, completion: @escaping (RandSbdForWidget) -> Void) {
        let svdSbds = getFavShabads()
        if let first = svdSbds.first {
            completion(RandSbdForWidget(sbd: first.sbdRes, date: Date.now, index: first.indexOfSelectedLine))
        } else {
            let sbd: ShabadAPIResponse = loadJSON(from: "random_sbd", as: ShabadAPIResponse.self)!
            completion(RandSbdForWidget(sbd: sbd, date: Date.now, index: 0))
        }
    }

    @MainActor func getTimeline(in _: Context, completion: @escaping (Timeline<RandSbdForWidget>) -> Void) {
        let svdSbds = getFavShabads()
        var entries: [RandSbdForWidget] = []
        let interval = UserDefaults.appGroup.data(forKey: "favSbdRefreshInterval") as? Int ?? 3
        print("typeof interval: ", interval, type(of: interval))
        var lastDate = Date.now
        for offset in 0 ..< svdSbds.count {
            let entryDate = Calendar.current.date(byAdding: .hour, value: offset * interval, to: Date())!
            let entry = RandSbdForWidget(sbd: svdSbds[offset].sbdRes, date: entryDate, index: svdSbds[offset].indexOfSelectedLine)
            lastDate = entryDate
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .after(lastDate))
        completion(timeline)
    }

    @MainActor
    private func getFavShabads() -> [SavedShabad] {
        do {
            let favSbdFolderName = UserDefaults.appGroup.data(forKey: "favSbdFolderName") as? String ?? default_fav_widget_folder_name
            let context = modelContainer.mainContext

            let descriptor = FetchDescriptor<SavedShabad>(
                predicate: #Predicate { $0.folder?.name == favSbdFolderName },
                sortBy: [SortDescriptor(\.sortIndex)]
            )
            let results = try context.fetch(descriptor)
            return results
        } catch {
            print("Widget fetch error: \(error)")
            return []
        }
    }
}

struct FavShabadsWidgetEntryView: View {
    var entry: RandSbdForWidget
    var body: some View {
        WidgetEntryView(entry: entry, heading: "From Favorites " + getWidgetHeadingFromSbdInfo(entry.sbd.shabadInfo))
            .widgetURL(URL(string: "chet://shabadid/\(entry.sbd.shabadInfo.shabadId)")) // custom deep link
        // Text("Favs")
    }
}

struct FavShabadsWidget: Widget {
    let kind: String = "FavShabadsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                FavShabadsWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                FavShabadsWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Favorite Shabads")
        .description("This will rotate Shabad From your Favorites")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryInline, .accessoryRectangular])
    }
}

// #Preview(as: .accessoryInline) {
//     FavShabadsWidget()
// } timeline: {
//     SavedSbdEntry(date: Date.now, obj: SampleData.svdSbd)
// }
//
// #Preview(as: .accessoryRectangular) {
//     FavShabadsWidget()
// } timeline: {
//     SavedSbdEntry(date: Date.now, obj: SampleData.svdSbd)
// }
//
// #Preview(as: .systemSmall) {
//     FavShabadsWidget()
// } timeline: {
//     SavedSbdEntry(date: Date.now, obj: SampleData.svdSbd)
// }
//
// #Preview(as: .systemMedium) {
//     FavShabadsWidget()
// } timeline: {
//     SavedSbdEntry(date: Date.now, obj: SampleData.svdSbd)
// }
//
// #Preview(as: .systemLarge) {
//     FavShabadsWidget()
// } timeline: {
//     SavedSbdEntry(date: Date.now, obj: SampleData.svdSbd)
// }
