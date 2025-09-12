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

    @MainActor func placeholder(in _: Context) -> SavedSbdEntry {
        SavedSbdEntry(date: Date.now, obj: SampleData.svdSbd)
    }

    @MainActor func getSnapshot(in _: Context, completion: @escaping (SavedSbdEntry) -> Void) {
        let svdSbds = getFavShabads()
        completion(SavedSbdEntry(date: Date.now, obj: svdSbds.first ?? SampleData.svdSbd))
    }

    @MainActor func getTimeline(in _: Context, completion: @escaping (Timeline<SavedSbdEntry>) -> Void) {
        let svdSbds = getFavShabads()
        var entries: [SavedSbdEntry] = []
        let currentDate = Date()
        for hourOffset in 0 ..< svdSbds.count {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SavedSbdEntry(date: entryDate, obj: svdSbds[hourOffset])
            print("added entry")
            print(entry)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    @MainActor
    private func getFavShabads() -> [SavedShabad] {
        do {
            let context = modelContainer.mainContext
            let descriptor = FetchDescriptor<Folder>(
                predicate: #Predicate { $0.name == "For Widgets" }
            )
            let results = try context.fetch(descriptor)
            // return results[0].savedShabads.map { $0.res }
            return results[0].savedShabads
        } catch {
            print("Widget fetch error: \(error)")
            return []
        }
    }

    //    func relevances() async -> WidgetRelevances<Void> {
    //        // Generate a list containing the contexts this widget is relevant in.
    //    }
}

struct SavedSbdEntry: TimelineEntry {
    let date: Date
    let obj: SavedShabad
}

struct FavShabadsWidgetEntryView: View {
    var entry: SavedSbdEntry
    var body: some View {
        // WidgetEntryView(the_shabad: entry.obj.shabad, heading: "From Favorites")
        Text("Favs")
    }

//    private getShabdObjFromFavLine(_ sbdObj:ShabadAPIResponse) -> {
//        let ind = entry.obj.indexOfSelectedLine
//        let lines = entry.obj.shabad.shabad
//        let lns = Array(lines[ind..<lines.endIndex])
//        entry.obj.shabad
//    }
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
