//
//  FavShabadsWidget.swift
//  FavShabadsWidget
//
//  Created by gian singh on 9/1/25.
//

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    @Query(sort: \FavoriteShabad.dateViewed, order: .reverse) private var favoriteShabads: [FavoriteShabad]
    func placeholder(in _: Context) -> ShabadEntry {
        ShabadEntry(date: Date.now, sbd: SampleData.shabadResponse)
    }

    func getSnapshot(in _: Context, completion: @escaping (ShabadEntry) -> Void) {
        completion(ShabadEntry(date: Date.now, sbd: favoriteShabads.first?.shabad ?? SampleData.shabadResponse ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShabadEntry>) -> ()) {
        var entries: [ShabadEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< favoriteShabads.count {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = ShabadEntry(date: entryDate, sbd: favoriteShabads[hourOffset].shabad)
            print("added entry")
            print(entry)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    //    func relevances() async -> WidgetRelevances<Void> {
    //        // Generate a list containing the contexts this widget is relevant in.
    //    }
}

struct FavShabadsWidgetEntryView : View {
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
