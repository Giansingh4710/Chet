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

    @MainActor func placeholder(in _: Context) -> ShabadInHistoryEntry {
        ShabadInHistoryEntry(date: Date.now, obj: SampleData.sbdHist)
    }

    @MainActor func getSnapshot(in _: Context, completion: @escaping (ShabadInHistoryEntry) -> Void) {
        let sbdHists = getFavShabads()
        completion(ShabadInHistoryEntry(date: Date.now, obj: sbdHists.first ?? SampleData.sbdHist))
    }

    @MainActor func getTimeline(in _: Context, completion: @escaping (Timeline<ShabadInHistoryEntry>) -> Void) {
        let sbdHists = getFavShabads()
        var entries: [ShabadInHistoryEntry] = []
        let currentDate = Date()
        for hourOffset in 0 ..< sbdHists.count {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = ShabadInHistoryEntry(date: entryDate, obj: sbdHists[hourOffset])
            print("added entry")
            print(entry)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    @MainActor
    private func getFavShabads() -> [ShabadHistory] {
        do {
            let context = modelContainer.mainContext
            let descriptor = FetchDescriptor<ShabadHistory>(
                predicate: #Predicate { $0.isFavorite == true },
                sortBy: [SortDescriptor(\.dateViewed, order: .reverse)]
                // fetchLimit: 100
            )
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

struct ShabadInHistoryEntry: TimelineEntry {
    let date: Date
    let obj: ShabadHistory
}

struct FavShabadsWidgetEntryView: View {
    var entry: ShabadInHistoryEntry
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
    ShabadInHistoryEntry(date: Date.now, obj: SampleData.sbdHist)
}

#Preview(as: .accessoryRectangular) {
    FavShabadsWidget()
} timeline: {
    ShabadInHistoryEntry(date: Date.now, obj: SampleData.sbdHist)
}

#Preview(as: .systemSmall) {
    FavShabadsWidget()
} timeline: {
    ShabadInHistoryEntry(date: Date.now, obj: SampleData.sbdHist)
}

#Preview(as: .systemMedium) {
    FavShabadsWidget()
} timeline: {
    ShabadInHistoryEntry(date: Date.now, obj: SampleData.sbdHist)
}

#Preview(as: .systemLarge) {
    FavShabadsWidget()
} timeline: {
    ShabadInHistoryEntry(date: Date.now, obj: SampleData.sbdHist)
}
