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
        let interval = UserDefaults.appGroup.integer(forKey: "favSbdRefreshInterval")
        let actualInterval = interval > 0 ? interval : 3 // Default to 3 hours if not set
        var lastDate = Date.now
        for offset in 0 ..< svdSbds.count {
            let sbd = svdSbds[offset]
            let entryDate = Calendar.current.date(byAdding: .hour, value: offset * actualInterval, to: Date())!
            let entry = RandSbdForWidget(sbd: sbd.sbdRes, date: entryDate, index: sbd.indexOfSelectedLine)
            lastDate = entryDate
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .after(lastDate))
        completion(timeline)
    }

    @MainActor
    private func getFavShabads() -> [SavedShabad] {
        do {
            let context = modelContainer.mainContext

            let descriptor = FetchDescriptor<SavedShabad>(
                predicate: #Predicate { $0.folder?.name == "Favorites" && $0.folder?.parentFolder == nil && $0.folder?.isSystemFolder == true },
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
        WidgetEntryView(entry: entry, heading: "From Favorites")
            .widgetURL(URL(string: "chet://favshabadid/\(entry.sbd.shabadInfo.shabadId)")) // custom deep link
        // Text("Favs")
    }
}

struct FavShabadsWidget: Widget {
    let kind: String = "FavShabadsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                FavShabadsWidgetEntryView(entry: entry)
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
