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

    @MainActor func placeholder(in _: Context) -> FavShabadEntry {
        FavShabadEntry(date: Date.now, obj: SampleData.favSbd)
    }

    @MainActor func getSnapshot(in _: Context, completion: @escaping (FavShabadEntry) -> Void) {
        let favSbds = getFavShabads()
        completion(FavShabadEntry(date: Date.now, obj: favSbds.first ?? SampleData.favSbd))
    }

    @MainActor func getTimeline(in _: Context, completion: @escaping (Timeline<FavShabadEntry>) -> Void) {
        let favSbds = getFavShabads()
        var entries: [FavShabadEntry] = []
        let currentDate = Date()
        for hourOffset in 0 ..< favSbds.count {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = FavShabadEntry(date: entryDate, obj: favSbds[hourOffset])
            print("added entry")
            print(entry)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    @MainActor
    private func getFavShabads() -> [FavoriteShabad] {
        do {
            let context = modelContainer.mainContext
            let descriptor = FetchDescriptor<FavoriteShabad>(sortBy: [SortDescriptor(\.dateViewed, order: .reverse)])
            let results = try context.fetch(descriptor)
            return results
        } catch {
            print("Widget fetch error: \(error)")
            return []
        }
    }

    //    func relevances() async -> WidgetRelevances<Void> {
    //        // Generate a list containing the contexts this widget is relevant in.
    //    }
}

struct FavShabadEntry: TimelineEntry {
    let date: Date
    let obj: FavoriteShabad
}

struct FavShabadsWidgetEntryView: View {
    var entry: FavShabadEntry
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

#Preview(as: .accessoryInline) {
    FavShabadsWidget()
} timeline: {
    FavShabadEntry(date: Date.now, obj: SampleData.favSbd)
}

#Preview(as: .accessoryRectangular) {
    FavShabadsWidget()
} timeline: {
    FavShabadEntry(date: Date.now, obj: SampleData.favSbd)
}

#Preview(as: .systemSmall) {
    FavShabadsWidget()
} timeline: {
    FavShabadEntry(date: Date.now, obj: SampleData.favSbd)
}

#Preview(as: .systemMedium) {
    FavShabadsWidget()
} timeline: {
    FavShabadEntry(date: Date.now, obj: SampleData.favSbd)
}

#Preview(as: .systemLarge) {
    FavShabadsWidget()
} timeline: {
    FavShabadEntry(date: Date.now, obj: SampleData.favSbd)
}
