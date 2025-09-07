import SwiftUI
import SwiftData

struct ShabadViewDisplayWrapper: View {
    let sbdHistory: ShabadHistory
    @State var sbdHistory2: ShabadHistory?

    // @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var isLoadingShabad = false
    @State private var errorMessage: String?

    var body: some View {
        if isLoadingShabad {
            ProgressView("Loading Shabad…")
        } else if let errorMessage = errorMessage {
            Text(errorMessage).foregroundColor(.red)
        } else if let sbdHist = sbdHistory2 {
            ShabadViewDisplay(sbdHistory: sbdHist, fetchNewShabad: fetchNewShabad)
        } else {
            ShabadViewDisplay(sbdHistory: sbdHistory, fetchNewShabad: fetchNewShabad)
        }
    }

    private func fetchNewShabad(_ sbdID: String) async {
        isLoadingShabad = true
        let urlString = "https://data.gurbaninow.com/v2/shabad/\(sbdID)"
        var aindexOfLine = 0
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
                sbdHistory2 = ShabadHistory(sbdRes: decoded, indexOfSelectedLine: 0)
            }
        } catch {
            await MainActor.run {
                isLoadingShabad = false
                errorMessage = "Failed to fetch shabad: \(error.localizedDescription)"
            }
        }
    }
}

struct ShabadViewDisplay: View {
    let sbdHistory: ShabadHistory
    let fetchNewShabad: (String) async -> Void
    @Environment(\.modelContext) private var modelContext

    @AppStorage("shabadTextScale") private var textScale: Double = 1.0
    @AppStorage("showTranslations") private var showTranslations: Bool = true
    @AppStorage("larivaar") private var larivaarOn: Bool = true
    @State private var gestureScale: CGFloat = 1.0

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // --- Meta Info Card ---
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label {
                                    Text("Ang \(sbdHistory.sbdRes.shabadinfo.pageno)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                } icon: {
                                    Image(systemName: "book.closed")
                                }

                                Spacer()

                                Label {
                                    Text(sbdHistory.sbdRes.shabadinfo.writer.english)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                } icon: {
                                    Image(systemName: "pencil")
                                }
                            }

                            Divider()

                            HStack(spacing: 20) {
                                Text("\(sbdHistory.sbdRes.shabad.count) lines")
                                    .font(.callout)
                                    .foregroundColor(.secondary)

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Shabad ID")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(sbdHistory.sbdRes.shabadinfo.shabadid)
                                        .font(.callout)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                        .monospaced() // keeps IDs aligned
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                        )
                        .padding(.horizontal)


                        HStack(spacing: 8) {
                            // --- Favorite Button ---
                            Button(action: {
                                if sbdHistory.isFavorite {
                                    removeFavorite()
                                } else {
                                    addFavorite()
                                }
                            }) {
                                Label(
                                    sbdHistory.isFavorite ? "Favorited" : "Favorite",
                                    systemImage: sbdHistory.isFavorite ? "heart.fill" : "heart"
                                )
                                .labelStyle(.titleAndIcon)
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .tint(sbdHistory.isFavorite ? .red : .gray)

                            Toggle(isOn: $showTranslations) {
                                Label("Translation", systemImage: "text.alignleft").font(.caption2)
                            }
                            .toggleStyle(.button)
                            .tint(.accentColor)

                            Toggle(isOn: $larivaarOn) {
                                Label("Larivaar", systemImage: "textformat").font(.caption)
                            }
                            .toggleStyle(.button)
                            .tint(.accentColor)
                        }
                        .padding(.horizontal)

                        // --- Shabad Lines ---
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(sbdHistory.sbdRes.shabad, id: \.line.id) { shabadLine in
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

                        // --- Next / Previous Navigation ---
                        HStack {
                            if let prevID = sbdHistory.sbdRes.shabadinfo.navigation.previous?.id {
                                Button("◀︎ Previous") {
                                    Task {
                                        await fetchNewShabad(prevID)
                                    }
                                }
                            }
                            Spacer()
                            if let nextID = sbdHistory.sbdRes.shabadinfo.navigation.next?.id {
                                Button("Next ▶︎") {
                                    Task {
                                        await fetchNewShabad(nextID)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func getGurbaniLine(_ shabadLine: ShabadLineWrapper) -> String {
        larivaarOn ? shabadLine.line.larivaar.unicode : shabadLine.line.gurmukhi.unicode
    }

    private func addFavorite() {
        sbdHistory.isFavorite = true
        let shabadID = sbdHistory.shabadID
        let descriptor = FetchDescriptor<ShabadHistory>(
            predicate: #Predicate { $0.shabadID == shabadID }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.dateViewed = Date()
        } else {
            modelContext.insert(sbdHistory)
        }
        try? modelContext.save()
    }

    private func removeFavorite() {
        sbdHistory.isFavorite = false
        try? modelContext.save()
    }
}

 #Preview {
    ShabadViewDisplayWrapper(sbdHistory: SampleData.sbdHist)
 }
