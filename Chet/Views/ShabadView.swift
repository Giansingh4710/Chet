import SwiftData
import SwiftUI

struct ShabadView: View {
    let searchedLine: LineObjFromSearch
    let alreadyInHistory = false
    @State private var shabadResponse: ShabadAPIResponse?
    @State private var isLoadingShabad = true
    @State private var errorMessage: String?
    @Environment(\.colorScheme) private var colorScheme
    @Query private var historyItems: [ShabadHistory]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {
            if isLoadingShabad {
                ProgressView("Loading Shabad…")
            } else if let errorMessage = errorMessage {
                Text(errorMessage).foregroundColor(.red)
            } else if let shabadResponse = shabadResponse {
                let foundByLine = LineOfShabad(from: searchedLine) // where `line` is LineObjFromSearch
                ShabadViewDisplay(shabadResponse: shabadResponse, foundByLine: foundByLine)
            }
        }
        .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
        // 👇 automatically runs when the view appears
        .task {
            await fetchFullShabad(shabadId: searchedLine.shabadid)
        }
    }

    private func fetchFullShabad(shabadId: String) async {
        let urlString = "https://data.gurbaninow.com/v2/shabad/\(shabadId)"
        let foundByLine = LineOfShabad(from: searchedLine) // where `line` is LineObjFromSearch
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                errorMessage = "Invalid shabad URL"
                isLoadingShabad = false
            }
            return
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200 ... 299).contains(httpResponse.statusCode)
            else {
                throw URLError(.badServerResponse)
            }
            let decoded = try JSONDecoder().decode(ShabadAPIResponse.self, from: data)
            await MainActor.run {
                isLoadingShabad = false
                shabadResponse = decoded
                addToHistory(decoded, foundByLine) // Automatically add to history
            }
        } catch {
            await MainActor.run {
                isLoadingShabad = false
                errorMessage = "Failed to fetch shabad: \(error.localizedDescription)"
            }
        }
    }

    private func addToHistory(_ shabadResponse: ShabadAPIResponse, _ foundByLine: LineOfShabad) {
        // Check if already exists and update date
        if let existing = historyItems.first(where: { $0.shabadID == shabadResponse.shabadinfo.shabadid }) {
            existing.dateViewed = Date()
        } else {
            let historyEntry = ShabadHistory(shabadResponse: shabadResponse, selectedLine: foundByLine)
            modelContext.insert(historyEntry)
        }

        // Keep only last 100 history entries
        if historyItems.count > 100 {
            let toDelete = historyItems.suffix(from: 100)
            for history in toDelete {
                modelContext.delete(history)
            }
        }

        do {
            try modelContext.save()
            print("Saved history successfully")
        } catch {
            print("Save failed:", error)
        }
    }
}

struct ShabadViewDisplay: View {
    let shabadResponse: ShabadAPIResponse
    let foundByLine: LineOfShabad

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Query private var favoriteShabads: [FavoriteShabad]
    @State private var isFavorite = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Shabad Info Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Source")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(shabadResponse.shabadinfo.source.english)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Writer")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(shabadResponse.shabadinfo.writer.english)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Raag")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(shabadResponse.shabadinfo.raag.english)
                                .font(.subheadline)
                        }

                        HStack {
                            Text("Page \(shabadResponse.shabadinfo.pageno)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(shabadResponse.shabadinfo.count) lines")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                    .cornerRadius(10)

                    // Favorite Button
                    HStack {
                        Button(action: {
                            if isFavorite {
                                removeFavorite()
                            } else {
                                addFavorite()
                            }
                        }) {
                            HStack {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                Text(isFavorite ? "Favorited" : "Add to Favorites")
                            }
                            .foregroundColor(isFavorite ? .red : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                        }

                        Spacer()
                    }
                    .padding(.horizontal)

                    // Shabad Lines (Compact, like bani)
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(shabadResponse.shabad, id: \.line.id) { shabadLine in
                            VStack(alignment: .leading, spacing: 4) {
                                // Gurbani
                                Text(shabadLine.line.gurmukhi.unicode)
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.leading)

                                // English Translation (smaller & subtle)
                                Text(shabadLine.line.translation.english.default)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .lineSpacing(2)

                                // Small line type markers
                                if shabadLine.line.type == 2 {
                                    Text("• Title •")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                } else if shabadLine.line.type == 3 {
                                    Text("• Refrain •")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(.vertical, 4) // much smaller padding
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }
            .navigationTitle("Shabad")
            .navigationBarTitleDisplayMode(.inline)
            .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            checkFavoriteStatus()
        }
    }

    private func checkFavoriteStatus() {
        isFavorite = favoriteShabads.contains { $0.shabadID == shabadResponse.shabadinfo.shabadid }
    }

    private func addFavorite() {
        let favoriteShabad = FavoriteShabad(shabadResponse: shabadResponse, selectedLine: foundByLine)
        modelContext.insert(favoriteShabad)
        isFavorite = true
        try? modelContext.save()
    }

    private func removeFavorite() {
        if let favorite = favoriteShabads.first(where: { $0.shabadID == shabadResponse.shabadinfo.shabadid }) {
            modelContext.delete(favorite)
            isFavorite = false
            try? modelContext.save()
        }
    }
}
