import SwiftData
import SwiftUI

struct ShabadView: View {
    let searchedLine: LineObjFromSearch
    let alreadyInHistory = false
    @State private var shabadResponse: ShabadAPIResponse?
    @State private var indexOfLine: Int = -1
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
                ShabadViewDisplay(shabadResponse: shabadResponse, indexOfSelectedLine: indexOfLine)
            }
        }
        .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
        // 👇 automatically runs when the view appears
        .task {
            await fetchFullShabad()
        }
    }

    private func fetchFullShabad() async {
        let urlString = "https://data.gurbaninow.com/v2/shabad/\(searchedLine.shabadid)"
        let foundByLineID = searchedLine.id // where `line` is LineObjFromSearch
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
            guard let aindexOfLine = decoded.shabad.firstIndex(where: { $0.line.id == foundByLineID }) else {
                throw URLError(.badServerResponse)
            }
            await MainActor.run {
                isLoadingShabad = false
                shabadResponse = decoded
                indexOfLine = aindexOfLine
                addToHistory() // Automatically add to history
            }
        } catch {
            await MainActor.run {
                isLoadingShabad = false
                errorMessage = "Failed to fetch shabad: \(error.localizedDescription)"
            }
        }
    }

    private func addToHistory() {
        // Check if already exists and update date
        if let existing = historyItems.first(where: { $0.shabadID == shabadResponse?.shabadinfo.shabadid }) {
            existing.dateViewed = Date()
        } else {
            if let sbdRes = shabadResponse {
                let historyEntry = ShabadHistory(shabadResponse: sbdRes, indexOfSelectedLine: indexOfLine)
                modelContext.insert(historyEntry)
            }
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
    let indexOfSelectedLine: Int

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Query private var favoriteShabads: [FavoriteShabad]
    @State private var isFavorite = false

    // Persistent settings
    @AppStorage("shabadTextScale") private var textScale: Double = 1.0
    @AppStorage("showTranslations") private var showTranslations: Bool = true
    @AppStorage("larivaar") private var larivaarOn: Bool = true

    // Temporary scaling during pinch
    @State private var gestureScale: CGFloat = 1.0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // --- Sleek Meta Info Card ---
                    VStack(alignment: .leading) {
                        HStack(spacing: 12) {
                            Label {
                                Text("Ang \(shabadResponse.shabadinfo.pageno)")
                                    .fontWeight(.semibold)
                            } icon: {
                                Image(systemName: "book.closed")
                            }
                            .font(.subheadline)
                            Spacer()
                            Label {
                                Text(shabadResponse.shabadinfo.writer.english)
                                    .fontWeight(.semibold)
                            } icon: {
                                Image(systemName: "pencil")
                            }
                            .font(.subheadline)
                        }
                        Spacer()
                        Text("\(shabadResponse.shabad.count) Lines")
                            .font(.system(size: 16, weight: .medium)) // Smaller font
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    HStack(spacing: 8) {
                        // --- Favorite Button styled like toggles ---
                        Button(action: {
                            if isFavorite {
                                removeFavorite()
                            } else {
                                addFavorite()
                            }
                        }) {
                            Label(
                                isFavorite ? "Favorited" : "Favorite",
                                systemImage: isFavorite ? "heart.fill" : "heart"
                            )
                            .labelStyle(.titleAndIcon) // icon left, text right
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .tint(isFavorite ? .red : .gray)

                        // --- Translation Toggle ---
                        Toggle(isOn: $showTranslations) {
                            Label("Translation", systemImage: "text.alignleft").font(.caption2)
                        }
                        .toggleStyle(.button)
                        .tint(.accentColor)

                        // --- Larivaar Toggle ---
                        Toggle(isOn: $larivaarOn) {
                            Label("Larivaar", systemImage: "textformat").font(.caption)
                        }
                        .toggleStyle(.button)
                        .tint(.accentColor)
                    }
                    .padding(.horizontal)

                    // --- Shabad Lines ---
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(shabadResponse.shabad, id: \.line.id) { shabadLine in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(getGurbaniLine(shabadLine))
                                    .font(.system(size: 20 * textScale * gestureScale))
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.leading)

                                if showTranslations {
                                    Text(shabadLine.line.translation.english.default)
                                        .font(.system(size: 15 * textScale * gestureScale))
                                        .foregroundColor(.secondary)
                                        .lineSpacing(2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                gestureScale = value
                            }
                            .onEnded { value in
                                textScale *= value
                                gestureScale = 1.0
                            }
                    )
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            checkFavoriteStatus()
        }
    }

    private func getGurbaniLine(_ shabadLine: ShabadLineWrapper) -> String {
        larivaarOn ? shabadLine.line.larivaar.unicode : shabadLine.line.gurmukhi.unicode
    }

    private func checkFavoriteStatus() {
        isFavorite = favoriteShabads.contains { $0.shabadID == shabadResponse.shabadinfo.shabadid }
    }

    private func addFavorite() {
        let favoriteShabad = FavoriteShabad(shabadResponse: shabadResponse, indexOfSelectedLine: indexOfSelectedLine)
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

#Preview {
    // ShabadView(searchedLine: SampleData.searchedLine)
    ShabadViewDisplay(shabadResponse: SampleData.shabadResponse,
                      indexOfSelectedLine: 4)
}
