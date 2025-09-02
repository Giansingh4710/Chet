//
//  FavShabadsWidget.swift
//  FavShabadsWidget
//
//  Created by gian singh on 9/1/25.
//

import SwiftData
import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
    let modelContainer = ModelContainer.shared

    @MainActor func placeholder(in _: Context) -> ShabadEntry {
        ShabadEntry(date: Date.now, sbd: SampleData.shabadResponse)
    }

    @MainActor func getSnapshot(in _: Context, completion: @escaping (ShabadEntry) -> Void) {
        let favSbds = getFavShabads()
        completion(ShabadEntry(date: Date.now, sbd: favSbds.first ?? SampleData.shabadResponse))
    }

    @MainActor func getTimeline(in _: Context, completion: @escaping (Timeline<ShabadEntry>) -> Void) {
        let favSbds = getFavShabads()
        var entries: [ShabadEntry] = []
        let currentDate = Date()
        for hourOffset in 0 ..< favSbds.count {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = ShabadEntry(date: entryDate, sbd: favSbds[hourOffset])
            print("added entry")
            print(entry)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    @MainActor
    private func getFavShabads() -> [ShabadAPIResponse] {
        do {
            let context = modelContainer.mainContext
            let descriptor = FetchDescriptor<FavoriteShabad>(sortBy: [SortDescriptor(\.dateViewed, order: .reverse)])
            let results = try context.fetch(descriptor)
            let lst = results.map{ $0.shabad }
            print("Widget fetched \(lst.count) favorites")
            return lst
        } catch {
            print("Widget fetch error: \(error)")
            return []
        }
    }

    //    func relevances() async -> WidgetRelevances<Void> {
    //        // Generate a list containing the contexts this widget is relevant in.
    //    }
}

struct FavShabadsWidgetEntryView: View {
    var entry: ShabadEntry
    var body: some View {
        WidgetEntryView(the_shabad: entry.sbd.shabad, heading: "From Favorites")
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
    }
}

#Preview(as: .accessoryInline) {
    FavShabadsWidget()
} timeline: {
    ShabadEntry(date: Date.now, sbd: SampleData.shabadResponse)
}

#Preview(as: .accessoryRectangular) {
    FavShabadsWidget()
} timeline: {
    ShabadEntry(date: Date.now, sbd: SampleData.shabadResponse)
}

#Preview(as: .systemSmall) {
    FavShabadsWidget()
} timeline: {
    ShabadEntry(date: Date.now, sbd: SampleData.shabadResponse)
}

#Preview(as: .systemMedium) {
    FavShabadsWidget()
} timeline: {
    ShabadEntry(date: Date.now, sbd: SampleData.shabadResponse)
}

#Preview(as: .systemLarge) {
    FavShabadsWidget()
} timeline: {
    ShabadEntry(date: Date.now, sbd: SampleData.shabadResponse)
}
