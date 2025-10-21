import SwiftData
import SwiftUI

struct SearchView: View {
    @Binding var shouldFocusSearchBar: Bool
    @State private var searchText = ""
    @State private var results: [SearchVerse] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    // @FocusState private var isSearchFieldFocused: Bool
    @State private var isSearchFieldFocused = false

    @State private var selectedShabad: ShabadAPIResponse?
    @State private var isNavigatingToSearchedSbd = false
    @State private var isNavigatingToHukam = false


    @State private var showingPunjabiKeyboard = false

    @AppStorage("fontType") private var fontType: String = "Unicode"
    @AppStorage("settings.larivaarOn") private var larivaarOn: Bool = true
    @AppStorage("settings.qwertyKeyboard") private var qwertyKeyboard: Bool = true

    // var displayedGurmukhi: String {}

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Searching for shabads...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("Search Error")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if results.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No Results Found")
                            .font(.headline)
                        Text("Try searching with different keywords")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        Text("Search Gurbani")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Enter keywords to search for shabads")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            Button(action: {
                                Task { await openRandomShabad() }
                            }) {
                                Image(systemName: "shuffle")
                                Text("Random Shabad")
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Darbar Sahib Hukamnama") {
                                isNavigatingToHukam = true
                            }
                            .buttonStyle(.bordered)
                        }
                        .navigationDestination(isPresented: $isNavigatingToSearchedSbd) {
                            if let sbd = selectedShabad {
                                ShabadViewDisplayWrapper(sbdRes: sbd, indexOfLine: 0)
                            }
                        }
                        .navigationDestination(isPresented: $isNavigatingToHukam) {
                            HukamnamaView()
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(results) { searchedLine in
                        NavigationLink(destination: ShabadViewFromSearchedLine(
                            searchedLine: searchedLine
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    // Text(searchedLine.verse.unicode)
                                    // .font(.title3)
                                    Text(
                                        larivaarOn ?
                                            fontType == "Unicode" ? searchedLine.larivaar.unicode : searchedLine.larivaar.gurmukhi :
                                            fontType == "Unicode" ? searchedLine.verse.unicode : searchedLine.verse.gurmukhi
                                    )
                                    .font(resolveFont(size: 24, fontType: fontType))
                                    .fontWeight(.semibold)
                                    .lineLimit(3)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.primary)
                                    Spacer()
                                    Text("Ang \(String(searchedLine.pageNo))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                if let a = searchedLine.translation.en.bdb {
                                    Text(a)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .onTapGesture {
                withAnimation(.spring()) {
                    isSearchFieldFocused = false
                    showingPunjabiKeyboard = false
                }
            }

            HStack(spacing: 16) {
                MyTextField(text: $searchText, isFocused: $isSearchFieldFocused, fontType: fontType, placeholder: "cyq")
                    .frame(height: 44)
                    .padding(.horizontal)
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 1)

                // Punjabi keyboard toggle
                Button(action: {
                    withAnimation(.spring()) {
                        showingPunjabiKeyboard.toggle()
                        isSearchFieldFocused = showingPunjabiKeyboard
                    }
                }) {
                    Image(systemName: showingPunjabiKeyboard ? "keyboard.chevron.compact.down" : "keyboard")
                        .foregroundColor(showingPunjabiKeyboard ? .blue : .gray)
                        .animation(.spring(), value: showingPunjabiKeyboard)
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 5)
            .background(Color(.systemGray6))
            .cornerRadius(10) // pill shape
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
            .padding(.horizontal)
            .offset(y: -20)

            if showingPunjabiKeyboard {
                if qwertyKeyboard {
                    QwertyPunjabiKeyboardView(
                        onKeyPress: { key in
                            searchText.append(key)
                        },
                        onDelete: {
                            if !searchText.isEmpty { searchText.removeLast() }
                        },
                        onSpace: {
                            searchText.append(" ")
                        },
                        switchKeyboard: {
                            qwertyKeyboard.toggle()
                        },
                        onReturn: {
                            Task { await fetchResults() }
                            showingPunjabiKeyboard = false
                            isSearchFieldFocused = false
                        }
                    )
                    .frame(height: 300)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    PunjabiKeyboardView(
                        onKeyPress: { key in
                            searchText.append(key)
                        },
                        onDelete: {
                            if !searchText.isEmpty { searchText.removeLast() }
                        },
                        onSpace: {
                            searchText.append(" ")
                        },
                        switchKeyboard: {
                            qwertyKeyboard.toggle()
                        },
                        onReturn: {
                            Task { await fetchResults() }
                            showingPunjabiKeyboard = false
                            isSearchFieldFocused = false
                        }
                    )
                }
            }
        }
        .onChange(of: shouldFocusSearchBar) { _, newValue in
            if newValue {
                isSearchFieldFocused = true
            }
        }
        .onChange(of: isSearchFieldFocused) { newValue in
            if newValue {
                showingPunjabiKeyboard = true
            }
        }
        .onChange(of: searchText) { newValue in
            if newValue.count > 2 {
                Task { await fetchResults() }
            }
        }
        .navigationTitle("Gurbani Search")
        .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
    }

    private func fetchResults() async {
        isLoading = true
        errorMessage = nil

        do {
            if searchText.isEmpty {
                results = []
                isLoading = false
                return
            }
            print("Search text:", searchText)
            let decoded = try await searchGurbani(from: searchText)
            results = decoded.verses
            isLoading = false
        } catch {
            errorMessage = "Failed to fetch results: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func openRandomShabad() async {
        if let response = await fetchRandomShabad() {
            selectedShabad = response
            isNavigatingToSearchedSbd = true
            let sbdHistory = ShabadHistory(sbdRes: response, indexOfSelectedLine: 0)
            addToHistory(sbdHistory: sbdHistory)
        }
    }

    private func addToHistory(sbdHistory: ShabadHistory) {
        let shabadID = sbdHistory.sbdRes.shabadInfo.shabadId
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
}

struct ShabadViewFromSearchedLine: View {
    let searchedLine: SearchVerse

    @State private var isLoadingShabad = true
    @State private var sbdHistory: ShabadHistory?
    @State private var indexOfLine: Int = -1
    @State private var errorMessage: String?
    @Environment(\.colorScheme) private var colorScheme
    @Query private var historyItems: [ShabadHistory]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {
            if isLoadingShabad {
                ProgressView("Loading Shabad…")
            } else if let errorMessage = errorMessage {
                Text(errorMessage).foregroundColor(.red)
            } else if let sbdHist = sbdHistory {
                ShabadViewDisplayWrapper(sbdRes: sbdHist.sbdRes, indexOfLine: indexOfLine)
            }
        }
        .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
        .task {
            await fetchFullShabad()
        }
    }

    private func fetchFullShabad() async {
        do {
            let decoded = try await fetchShabadResponse(from: searchedLine.shabadId)
            print("decoded", decoded)
            guard let indexOfLine = decoded.verses.firstIndex(where: { $0.verseId == searchedLine.verseId }) else {
                throw URLError(.cannotFindHost)
            }

            isLoadingShabad = false
            sbdHistory = ShabadHistory(sbdRes: decoded, indexOfSelectedLine: indexOfLine)
            self.indexOfLine = indexOfLine
            if let sbdHist = sbdHistory {
                addToHistory(sbdHistory: sbdHist)
            }

        } catch {
            isLoadingShabad = false
            errorMessage = "Failed to fetch shabad: \(error.localizedDescription)"

            print("Error: \(error)")
            print("LineId:", searchedLine.verseId, " ShabadId:", searchedLine.shabadId)
        }
    }

    private func addToHistory(sbdHistory: ShabadHistory) {
        let shabadID = sbdHistory.sbdRes.shabadInfo.shabadId
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
}

struct PunjabiKeyboardView: View {
    let onKeyPress: (String) -> Void
    let onDelete: () -> Void
    let onSpace: () -> Void
    let switchKeyboard: () -> Void
    let onReturn: () -> Void

    @AppStorage("fontType") private var fontType: String = "Unicode"
    private let rows: [[String]] = [
        ["a", "A", "e", "s", "h", "k", "K", "g", "G", "|"],
        ["c", "C", "j", "J", "\\", "t", "T", "f", "F", "x"],
        ["q", "Q", "d", "D", "n", "p", "P", "b", "B", "m"],
        ["X", "r", "l", "v", "V", "S", "^", "Z", "z", "&"],
    ]

    var body: some View {
        VStack(spacing: 12) {
            // Regular rows
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(Array(row.enumerated()), id: \.offset) { index, key in
                        KeyButton(label: key, fontType: fontType) {
                            onKeyPress(key)
                        }
                        // Insert a grouping gap every 5 keys
                        if (index + 1) % 5 == 0 && index != row.count - 1 {
                            Spacer(minLength: 14)
                        }
                    }
                }
            }

            LastKeyBoardRow(switchKeyboard: switchKeyboard, onSpace: onSpace, onReturn: onReturn)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(Color(UIColor.systemGray6))
    }
}

struct QwertyPunjabiKeyboardView: View {
    let onKeyPress: (String) -> Void
    let onDelete: () -> Void
    let onSpace: () -> Void
    let switchKeyboard: () -> Void
    let onReturn: () -> Void

    @AppStorage("fontType") private var fontType: String = "Unicode"
    @State private var isShifted: Bool = false

    // Lowercase layout - exact QWERTY
    private let lowercaseRows: [[String]] = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"],
    ]

    // Uppercase layout - exact QWERTY shifted
    private let uppercaseRows: [[String]] = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"],
    ]

    var currentRows: [[String]] {
        isShifted ? uppercaseRows : lowercaseRows
    }

    var body: some View {
        VStack(spacing: 12) {
            // Letter rows
            ForEach(currentRows.indices, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    // Add padding for rows to create QWERTY offset
                    if rowIndex == 1 {
                        Spacer().frame(width: 10)
                    } else if rowIndex == 2 {
                        Button(action: {
                            isShifted.toggle()
                        }) {
                            Image(systemName: isShifted ? "shift.fill" : "shift")
                                .font(.system(size: 20))
                                .foregroundColor(.primary)
                                .frame(width: 50, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(isShifted ? Color(UIColor.systemGray3) : Color(UIColor.systemGray5))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(Color(UIColor.systemGray3), lineWidth: 0.5)
                                        )
                                )
                        }
                        // Spacer().frame(width: 40)
                    }

                    ForEach(currentRows[rowIndex], id: \.self) { key in
                        KeyButton(label: key, fontType: fontType) {
                            onKeyPress(key)
                        }
                    }
                    if rowIndex == 2 {
                        // Backspace button
                        Button(action: onDelete) {
                            Image(systemName: "delete.left")
                                .font(.system(size: 20))
                                .foregroundColor(.primary)
                                .frame(width: 50, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color(UIColor.systemGray5))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(Color(UIColor.systemGray3), lineWidth: 0.5)
                                        )
                                )
                        }
                    }

                    if rowIndex == 1 {
                        Spacer().frame(width: 10)
                    }
                }
            }

            // Bottom row with shift, space, and backspace
            LastKeyBoardRow(switchKeyboard: switchKeyboard, onSpace: onSpace, onReturn: onReturn)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(Color(UIColor.systemGray6))
    }
}

struct LastKeyBoardRow: View {
    let switchKeyboard: () -> Void
    let onSpace: () -> Void
    let onReturn: () -> Void
    var body: some View {
        HStack(spacing: 6) {
            Button(action: switchKeyboard) {
                Image(systemName: "keyboard.onehanded.right")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .frame(width: 50, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(UIColor.systemGray3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color(UIColor.systemGray3), lineWidth: 0.5)
                            )
                    )
            }
            // Space bar
            Button(action: onSpace) {
                Text("ਖਾਲੀ ਥਾਂ")
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(UIColor.systemGray5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color(UIColor.systemGray3), lineWidth: 0.5)
                            )
                    )
            }
            Button(action: onReturn) {
                Text("Return")
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 14) // adds a bit of space around text
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(UIColor.systemGray5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color(UIColor.systemGray3), lineWidth: 0.5)
                            )
                    )
            }
        }
    }
}

struct KeyButton: View {
    let label: String
    let fontType: String
    let action: () -> Void

    // Add dotted circle to matras for display purposes
    var displayLabel: String {
        let matras = ["w", "y", "u", "i", "o", "W", "R", "Y", "U", "I", "O", "H", "N", "M"] // Matras that need a base character
        if matras.contains(label) {
            return "◌" + label
        }
        return label
    }

    var body: some View {
        Button(action: action) {
            Text(displayLabel)
                .font(resolveFont(size: 20, fontType: fontType == "Unicode" ? "AnmolLipiSG" : fontType))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(UIColor.systemGray5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color(UIColor.systemGray3), lineWidth: 0.5)
                        )
                )
        }
    }
}

struct MyTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let fontType: String
    let placeholder: String

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.font = resolveFont(size: 16, fontType: fontType == "Unicode" ? "AnmolLipiSG" : fontType)
        tf.textColor = .label
        tf.backgroundColor = .systemGray6
        tf.layer.cornerRadius = 10
        tf.clearButtonMode = .whileEditing
        tf.tintColor = .systemBlue // cursor color
        tf.inputView = UIView() // disable system keyboard
        tf.inputAccessoryView = UIView()

        // left search icon
        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        icon.tintColor = .gray
        tf.leftView = icon
        tf.leftViewMode = .always

        tf.delegate = context.coordinator

        // tap recognizer to set SwiftUI focus
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.didTap))
        tf.addGestureRecognizer(tap)
        return tf
    }

    func updateUIView(_ tf: UITextField, context _: Context) {
        tf.text = text
        if isFocused {
            tf.becomeFirstResponder()
        } else {
            tf.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: $isFocused)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        @Binding var isFocused: Bool

        init(text: Binding<String>, isFocused: Binding<Bool>) {
            _text = text
            _isFocused = isFocused
        }

        func textFieldDidChangeSelection(_ tf: UITextField) {
            text = tf.text ?? ""
        }

        @objc func didTap() {
            withAnimation(.spring()) {
                isFocused = true
            }
        }
    }
}
