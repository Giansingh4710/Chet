import SwiftData
import SwiftUI
import WidgetKit

struct SettingsView: View {
    @AppStorage("CompactRowViewSetting") private var compactRowViewSetting = false
    @AppStorage("colorScheme") private var colorScheme: String = "system"

    @AppStorage("randSbdRefreshInterval", store: UserDefaults.appGroup) var randSbdRefreshInterval: Int = 3 // default: every 3 hours
    @AppStorage("favSbdRefreshInterval", store: UserDefaults.appGroup) private var favSbdRefreshInterval: Int = 3
    @Query private var allFolders: [Folder]

    @AppStorage("settings.larivaarOn") private var larivaarOn: Bool = true
    @AppStorage("settings.larivaarAssist") private var larivaarAssist: Bool = false
    @AppStorage("swipeToGoToNextShabadSetting") private var swipeToGoToNextShabadSetting = true
    @AppStorage("fontType") private var fontType: String = "Unicode"

    @State private var randSbdLst: [RandSbdForWidget] = []
    @State private var widgetShabads: [SavedShabad] = []
    @Environment(\.modelContext) private var context

    @State private var infoType: InfoType?
    @State private var isBackingUp = false
    @AppStorage("lastBackupTime") private var lastBackupTime: Double = 0
    @State private var selectedWidgetTab: WidgetTab = .random
    @State private var backupMessage: String?
    @State private var showBackupToast = false

    var body: some View {
        VStack(spacing: 0) {
            List {
                // Display Settings Section
                Section("Display") {
                    HStack {
                        Label("Compact View", systemImage: "rectangle.compress.vertical")
                        Spacer()
                        Toggle("", isOn: $compactRowViewSetting)
                        infoButton(.compactRow)
                    }

                    HStack {
                        Label("Larivaar", systemImage: "textformat")
                        Spacer()
                        Toggle("", isOn: $larivaarOn)
                            .onChange(of: larivaarOn) { setting in
                                if !setting {
                                    larivaarAssist = false
                                }
                                UserDefaults.appGroup.set(setting, forKey: "settings.larivaarOn")
                                UserDefaults.appGroup.synchronize()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    WidgetCenter.shared.reloadTimelines(ofKind: "HukamnamaWidget")
                                    WidgetCenter.shared.reloadTimelines(ofKind: "RandomShabadWidget")
                                    WidgetCenter.shared.reloadTimelines(ofKind: "FavShabadsWidget")
                                }
                            }
                    }
                    if larivaarOn {
                        HStack {
                            Label("Larivaar Assist", systemImage: "textformat")
                            Spacer()
                            Toggle("", isOn: $larivaarAssist)
                                .onChange(of: larivaarAssist) { setting in
                                    UserDefaults.appGroup.set(setting, forKey: "settings.larivaarAssist")
                                    UserDefaults.appGroup.synchronize()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        WidgetCenter.shared.reloadTimelines(ofKind: "HukamnamaWidget")
                                        WidgetCenter.shared.reloadTimelines(ofKind: "RandomShabadWidget")
                                        WidgetCenter.shared.reloadTimelines(ofKind: "FavShabadsWidget")
                                    }
                                }
                        }
                    }

                    HStack {
                        Label("Swipe to Next Shabad", systemImage: "hand.draw")
                        Spacer()
                        Toggle("", isOn: $swipeToGoToNextShabadSetting)
                    }

                    FontPicker()
                }

                // Appearance Section
                Section("Appearance") {
                    HStack {
                        Label("Theme", systemImage: "circle.lefthalf.filled")
                        Spacer()
                        Picker("", selection: $colorScheme) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                        infoButton(.appearance)
                    }
                }

                // Combined Widget Section
                Section("Widgets") {
                    VStack(spacing: 12) {
                        // Tab Picker
                        Picker("Widget Type", selection: $selectedWidgetTab) {
                            Label("Random", systemImage: "shuffle").tag(WidgetTab.random)
                            Label("Favorites", systemImage: "star.fill").tag(WidgetTab.favorites)
                        }
                        .pickerStyle(.segmented)

                        // Content based on selected tab
                        if selectedWidgetTab == .random {
                            RandomWidgetContent(
                                randSbdLst: $randSbdLst,
                                randSbdRefreshInterval: $randSbdRefreshInterval,
                                infoButton: infoButton(.randSbdRefreshInterval),
                                onRefresh: {
                                    Task { await updateRandWidgetSbds(interval: randSbdRefreshInterval) }
                                }
                            )
                        } else {
                            FavoriteWidgetContent(
                                widgetShabads: widgetShabads,
                                favSbdRefreshInterval: $favSbdRefreshInterval,
                                infoButton: infoButton(.favSbdRefreshInterval)
                            )
                        }
                    }
                }

                // Backup & Sync Section
                Section {
                    HStack {
                        Text("Auto-Backup")
                        Spacer()
                        Text("Every 5 changes")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }

                    HStack {
                        Text("Last Backup")
                        Spacer()
                        if lastBackupTime > 0 {
                            Text(Date(timeIntervalSince1970: lastBackupTime), style: .relative)
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        } else {
                            Text("Never")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                    }

                    Button(action: {
                        Task {
                            isBackingUp = true
                            do {
                                let data = try await BackupManager.shared.exportToJSON(modelContext: context)
                                let url = try await BackupManager.shared.saveToiCloud(data: data)
                                lastBackupTime = Date().timeIntervalSince1970
                                backupMessage = "Backup saved successfully"
                                showBackupToast = true
                            } catch {
                                print("Manual backup failed: \(error.localizedDescription)")
                                backupMessage = "Backup failed: \(error.localizedDescription)"
                                showBackupToast = true
                            }
                            isBackingUp = false
                        }
                    }) {
                        HStack {
                            if isBackingUp {
                                ProgressView()
                            } else {
                                Image(systemName: "icloud.and.arrow.up")
                            }
                            Text("Backup Now")
                        }
                    }
                    .disabled(isBackingUp)

                    NavigationLink(destination: BackupsListView()) {
                        Label("View Backups", systemImage: "folder")
                    }
                } header: {
                    Text("Backup")
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            loadRandSbds()
            loadWidgetShabads()
        }
        .alert(item: $infoType) { type in
            Alert(title: Text("Info"), message: Text(type.message), dismissButton: .default(Text("OK")))
        }
        .overlay(alignment: .top) {
            if showBackupToast, let message = backupMessage {
                HStack(spacing: 12) {
                    Image(systemName: message.contains("failed") ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundColor(.white)
                    Text(message)
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
                .padding()
                .background(message.contains("failed") ? Color.red : Color.green)
                .cornerRadius(10)
                .shadow(radius: 10)
                .padding(.top, 50)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showBackupToast = false
                        }
                    }
                }
            }
        }
    }

    // Info button factory
    private func infoButton(_ type: InfoType) -> some View {
        Button {
            infoType = type
        } label: {
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
        }
        .buttonStyle(.plain)
    }

    private func updateRandWidgetSbds(interval: Int) async {
        let newList: [RandSbdForWidget] = await getRandShabads(interval: interval)
        randSbdLst = newList
        WidgetCenter.shared.reloadTimelines(ofKind: "xyz.gians.Chet.RandomShabadWidget") // Ask widget to refresh
    }

    private func loadRandSbds() {
        if let historyData = UserDefaults.appGroup.array(forKey: "randShabadList") as? [Data] {
            randSbdLst = historyData.compactMap { try? JSONDecoder().decode(RandSbdForWidget.self, from: $0) }
            print("Loaded \(randSbdLst.count) Random Shabad Widget")
        }
    }

    private func loadWidgetShabads() {
        if let folder = allFolders.first(where: { $0.name == "Favorites" }) {
            let folderID = folder.id // <-- capture as plain UUID
            let descriptor = FetchDescriptor<SavedShabad>(
                predicate: #Predicate { $0.folder?.id == folderID },
                sortBy: [SortDescriptor(\.sortIndex)]
            )
            widgetShabads = (try? context.fetch(descriptor)) ?? []
        } else {
            widgetShabads = []
        }
    }
}

struct FontPicker: View {
    @AppStorage("fontType") private var fontType: String = "Unicode"

    var body: some View {
        HStack {
            Label("Font", systemImage: "textformat.size")
            Text("( cyq )").font(resolveFont(size: 20, fontType: fontType))
            Spacer()
            Picker("", selection: $fontType) {
                Text("Unicode").tag("Unicode")
                Text("Anmol Lipi SG").tag("AnmolLipiSG")
                Text("Anmol Lipi Bold").tag("AnmolLipiBoldTrue")
                Text("Gurbani Akhar").tag("GurbaniAkharTrue")
                Text("Gurbani Akhar Heavy").tag("GurbaniAkharHeavyTrue")
                Text("Gurbani Akhar Thick").tag("GurbaniAkharThickTrue")
                Text("Noto Sans Gurmukhi Bold").tag("NotoSansGurmukhiBoldTrue")
                Text("Noto Sans Gurmukhi").tag("NotoSansGurmukhiTrue")
                Text("Prabhki").tag("Prabhki")
                Text("The Actual Characters").tag("The Actual Characters")
            }
            .pickerStyle(.menu)
            .onChange(of: fontType) { setting in
                print("Font changed to \(setting)")
                UserDefaults.appGroup.set(setting, forKey: "fontType")
                UserDefaults.appGroup.synchronize()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    WidgetCenter.shared.reloadTimelines(ofKind: "HukamnamaWidget")
                    WidgetCenter.shared.reloadTimelines(ofKind: "RandomShabadWidget")
                    WidgetCenter.shared.reloadTimelines(ofKind: "FavShabadsWidget")
                }
            }
        }
    }
}

enum WidgetTab {
    case random
    case favorites
}

enum InfoType: Identifiable {
    case compactRow
    case appearance
    case randSbdRefreshInterval
    case favSbdRefreshInterval

    var id: Int {
        hashValue
    }

    var message: String {
        switch self {
        case .compactRow:
            return "Compact Row View shows less spacing between rows so more can fit on the screen."
        case .appearance:
            return "Appearance lets you choose between following the system theme, light mode, or dark mode."
        case .randSbdRefreshInterval:
            return "This determines how often new random Shabads are generated for the widget."
        case .favSbdRefreshInterval:
            return "This determines how often the shabads in your chosen folder switch in your widget."
        }
    }
}

// MARK: - Random Widget Content

struct RandomWidgetContent<InfoButton: View>: View {
    @Binding var randSbdLst: [RandSbdForWidget]
    @Binding var randSbdRefreshInterval: Int
    let infoButton: InfoButton
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if randSbdLst.isEmpty {
                HStack {
                    Image(systemName: "shuffle.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No Random Shabads Yet")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Text("Tap refresh to generate")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(randSbdLst, id: \.index) { item in
                        NavigationLink(destination: ShabadViewDisplayWrapper(sbdRes: item.sbd, indexOfLine: 0)) {
                            HStack(spacing: 10) {
                                Image(systemName: "quote.bubble")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.sbd.verses[0].verse.unicode)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    Text(item.date, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())

                        if item.index < randSbdLst.count - 1 {
                            Divider()
                        }
                    }
                }
            }

            Divider()

            HStack {
                Label("Refresh Interval", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Picker("", selection: $randSbdRefreshInterval) {
                    Text("1h").tag(1)
                    Text("3h").tag(3)
                    Text("6h").tag(6)
                    Text("12h").tag(12)
                    Text("24h").tag(24)
                }
                .pickerStyle(.menu)
                .onChange(of: randSbdRefreshInterval) { _ in
                    Task {
                        // Auto-refresh when interval changes
                        onRefresh()
                    }
                }
                infoButton
            }

            Button(action: onRefresh) {
                Label("Refresh Widgets", systemImage: "arrow.clockwise")
            }
        }
    }
}

// MARK: - Favorite Widget Content

struct FavoriteWidgetContent<InfoButton: View>: View {
    let widgetShabads: [SavedShabad]
    @Binding var favSbdRefreshInterval: Int
    let infoButton: InfoButton

    var body: some View {
        VStack(spacing: 12) {
            if widgetShabads.isEmpty {
                HStack {
                    Image(systemName: "star.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No Favorites Yet")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Text("Add shabads to Favorites folder")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(widgetShabads.prefix(3)) { shabad in
                        NavigationLink(destination: ShabadViewDisplayWrapper(
                            sbdRes: shabad.sbdRes,
                            indexOfLine: shabad.indexOfSelectedLine
                        )) {
                            HStack(spacing: 10) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.yellow)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(shabad.sbdRes.verses[shabad.indexOfSelectedLine < 0 ? 0 : shabad.indexOfSelectedLine].verse.unicode)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    Text(shabad.addedAt, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())

                        if shabad.id != widgetShabads.prefix(3).last?.id {
                            Divider()
                        }
                    }

                    if widgetShabads.count > 3 {
                        Text("+\(widgetShabads.count - 3) more in Favorites")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
            }

            Divider()

            HStack {
                Label("Refresh Interval", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Picker("", selection: $favSbdRefreshInterval) {
                    Text("1h").tag(1)
                    Text("3h").tag(3)
                    Text("6h").tag(6)
                    Text("12h").tag(12)
                    Text("24h").tag(24)
                }
                .pickerStyle(.menu)
                .onChange(of: favSbdRefreshInterval) { _ in
                    WidgetCenter.shared.reloadTimelines(ofKind: "xyz.gians.Chet.FavShabadsWidget")
                }
                infoButton
            }
        }
    }
}
