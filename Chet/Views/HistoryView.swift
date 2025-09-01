//
//  ShabadHistoryView.swift
//  Chet
//
//  Created by gian singh on 8/29/25.
//

import SwiftData
import SwiftUI

struct ShabadHistoryView: View {
    @Query(sort: \ShabadHistory.dateViewed, order: .reverse) private var historyItems: [ShabadHistory]
    @State private var showingClearConfirmation = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Clear History Button
                HStack {
                    Spacer()
                    Button(action: {
                        showingClearConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
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
                    List(historyItems) { historyItem in
                        // NavigationLink(destination: HistoryShabadDetailView(historyItem: historyItem)) {
                        NavigationLink(destination: ShabadViewDisplay(shabadResponse: historyItem.shabad, foundByLine: historyItem.selectedLine) ) {
                            HistoryShabadRowView(historyItem: historyItem)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("History")
            .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
            .alert("Clear History", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    clearHistory()
                }
            } message: {
                Text("Are you sure you want to clear all history? This action cannot be undone.")
            }
        }
    }

    private func clearHistory() {
        for history in historyItems {
            modelContext.delete(history)
        }
        try? modelContext.save()
    }
}

struct HistoryShabadRowView: View {
    let historyItem: ShabadHistory
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(historyItem.selectedLine.gurmukhi.unicode)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(historyItem.selectedLine.translation.english.default)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(historyItem.dateViewed, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(historyItem.dateViewed, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Text(historyItem.shabad.shabadinfo.source.unicode)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)

                Text(historyItem.shabad.shabadinfo.writer.english)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(4)

                Text("Page \(historyItem.shabad.shabadinfo.pageno)")
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

struct HistoryShabadDetailView: View {
    let historyItem: ShabadHistory
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Shabad Info Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Source")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(historyItem.shabad.shabadinfo.source.english)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Writer")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(historyItem.shabad.shabadinfo.writer.english)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Raag")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(historyItem.shabad.shabadinfo.raag.english)
                            .font(.subheadline)
                    }

                    HStack {
                        Text("Page \(historyItem.shabad.shabadinfo.pageno)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(historyItem.shabad.shabad.count) lines")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("Viewed: \(historyItem.dateViewed, style: .date)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Spacer()
                        Text("Time: \(historyItem.dateViewed, style: .time)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                .cornerRadius(10)

                // Selected Line Preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Line")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(historyItem.selectedLine.gurmukhi.unicode)
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)

                    Text(historyItem.selectedLine.translation.english.default)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
        .navigationTitle("History Item")
        .navigationBarTitleDisplayMode(.inline)
        .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}

#Preview {
    ShabadHistoryView()
}
