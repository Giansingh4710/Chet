//
//  ShabadHistoryView.swift
//  Chet
//
//  Created by gian singh on 8/29/25.
//

import SwiftData
import SwiftUI

// Remove the NavigationView wrapper in ShabadHistoryView
struct ShabadHistoryView: View {
    @Query(sort: \ShabadHistory.dateViewed, order: .reverse) private var historyItems: [ShabadHistory]
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            if historyItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No History")
                        .font(.headline)
                    Text("Your viewed shabads will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(historyItems) { historyItem in
                        NavigationLink(destination: ShabadViewDisplayWrapper(sbdRes: historyItem.sbdRes, indexOfLine: historyItem.indexOfSelectedLine, onIndexChange: { newIndex in
                            historyItem.indexOfSelectedLine = newIndex
                        })) {
                            RowView(sbdRes: historyItem.sbdRes, indexOfLine: historyItem.indexOfSelectedLine, the_date: historyItem.dateViewed)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .onDelete(perform: deleteHistoryItems)
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("History")
        .toolbar {
            Text("\(historyItems.count)").font(.caption).foregroundColor(.secondary)
        }
    }

    private func deleteHistoryItems(at offsets: IndexSet) {
        for index in offsets {
            let history = historyItems[index]
            modelContext.delete(history)
        }
        try? modelContext.save()
    }

    private func clearHistory() {
        for history in historyItems {
            modelContext.delete(history)
        }
        try? modelContext.save()
    }
}

struct RowView: View {
    let sbdRes: ShabadAPIResponse
    let indexOfLine: Int
    let the_date: Date

    @AppStorage("CompactRowViewSetting") private var compactRowViewSetting = false
    @AppStorage("settings.larivaarOn") private var larivaarOn: Bool = true
    @AppStorage("fontType") private var fontType: String = "Unicode"

    let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    var gurmukhiText: String {
        let ind = indexOfLine == -1 ? 0 : indexOfLine
        if fontType == "Unicode" {
            if larivaarOn {
                return sbdRes.verses[ind].larivaar.unicode
            }
            return sbdRes.verses[ind].verse.unicode
        } else {
            if larivaarOn {
                return sbdRes.verses[ind].larivaar.gurmukhi
            }
            return sbdRes.verses[ind].verse.gurmukhi
        }
    }

    var body: some View {
        if compactRowViewSetting {
            HStack {
                Text(gurmukhiText)
                    .font(resolveFont(size: 24, fontType: fontType == "Unicode" ? "AnmolLipiSG" : fontType))
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)

                Spacer()
                Text(formatter.string(from: the_date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(gurmukhiText)
                            .font(resolveFont(size: 24, fontType: fontType == "Unicode" ? "AnmolLipiSG" : fontType))
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if let a = sbdRes.verses[indexOfLine].translation.en.bdb {
                            Text(a)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(the_date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(the_date, style: .time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Text(sbdRes.shabadInfo.source.english)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)

                    Text(sbdRes.shabadInfo.writer.english)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)

                    Text("Ang \(String(sbdRes.shabadInfo.pageNo))")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)

                    Spacer()
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
