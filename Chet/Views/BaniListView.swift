//
//  BaniListView.swift
//  Chet
//
//  Created by gian singh on 11/10/25.
//

import SwiftUI

struct BaniListView: View {
    @State private var expandedCategories: Set<String> = []
    @AppStorage("favoriteBanis") private var favoriteBanisData: String = "[]"
    @AppStorage("fontType") private var fontType: String = "Unicode"
    @Environment(\.editMode) private var editMode

    private var favoriteBanis: [String] {
        if let data = favoriteBanisData.data(using: .utf8),
           let array = try? JSONDecoder().decode([String].self, from: data)
        {
            return array
        }
        return []
    }

    private func toggleFavorite(_ baniTitle: String) {
        var favorites = favoriteBanis
        if let index = favorites.firstIndex(of: baniTitle) {
            favorites.remove(at: index)
        } else {
            favorites.append(baniTitle)
        }
        saveFavorites(favorites)
    }

    private func moveFavorite(from source: IndexSet, to destination: Int) {
        var favorites = favoriteBanis
        favorites.move(fromOffsets: source, toOffset: destination)
        saveFavorites(favorites)
    }

    private func saveFavorites(_ favorites: [String]) {
        if let data = try? JSONEncoder().encode(favorites),
           let string = String(data: data, encoding: .utf8)
        {
            favoriteBanisData = string
        }
    }

    private let banis: [(title: String, items: [String])] = [
        ("inqnym", [
            "jpujI swihb",
            "jwpu swihb",
            "qÍ pRswid sv`Xy (sRwvg su`D)",
            "bynqI cOpeI swihb",
            "Anµdu swihb",
            "rhrwis swihb",
            "soihlw swihb",
        ]),
        ("5 gRMQI", [
            "bwvn AKrI",
            "suKmnI swihb",
            "Awsw dI vwr",
            "isD gosit",
            "dKxI EAMkwru",
        ]),
        ("byAMq bwxIAwN", [
            "lwvW",
            "kucjI",
            "sucjI",
            "guxvMqI",
            "Punhy mhlw 5",
            "cauboly",
            "rwmklI kI vwr (rwie blvMif qQw sqY)",
            "bsMq kI vwr",
            "Sbd hzwry",
            "Sbd hzwry pwiqSwhI 10",
        ]),
        ("22 vwrw", [
            "isrIrwg kI vwr mhlw 4",
            "vwr mwJ kI",
            "gauVI kI vwr mhlw 4",
            "gauVI kI vwr mhlw 5",
            "Awsw dI vwr",
            "gUjrI kI vwr mhlw 3",
            "rwgu gUjrI vwr mhlw 5",
            "ibhwgVy kI vwr mhlw 4",
            "vfhMs kI vwr mhlw 4",
            "rwgu soriT vwr mhly 4 kI",
            "jYqsrI kI vwr",
            "vwr sUhI kI",
            "iblwvlu kI vwr mhlw 4",
            "rwmklI kI vwr mhlw 3",
            "rwmklI kI vwr mhlw 5",
            "rwmklI kI vwr (rwie blvMif qQw sqY)",
            "mwrU vwr mhlw 3",
            "mwrU vwr mhlw 5 fKxy",
            "bsMq kI vwr",
            "swrMg kI vwr mhlw 4",
            "vwr mlwr kI mhlw 1",
            "kwnVy kI vwr mhlw 4",
        ]),
        ("Bgq bwxI", [
            "rwgu isrIrwgu (kbIr jIau kw)",
            "rwgu gauVI",
            "rwgu Awsw",
            "rwgu gUjrI",
            "rwgu soriT",
            "rwgu DnwsrI",
            "rwgu jYqsrI",
            "rwgu tofI (bwxI BgqW kI)",
            "rwgu iqlMg (bwxI Bgqw kI kbIr jI)",
            "rwgu sUhI",
            "rwgu iblwvlu",
            "rwgu goNf",
            "rwmklI kI vwr mhlw 3",
            "rwgu mwlI gauVw",
            "rwgu mwrU",
            "rwgu kydwrw",
            "rwgu BYrau",
            "rwgu bsMqu",
            "rwgu swrMg",
            "vwr mlwr kI mhlw 1",
            "rwgu kwnVw",
            "rwgu pRBwqI",
            "slok Bgq kbIr jIau ky",
            "slok syK PrId ky",
        ]),
        ("svXy", [
            "svXy sRI muKbwk´ mhlw 5 - 1",
            "svXy sRI muKbwk´ mhlw 5 - 2",
            "sveIey mhly pihly ky",
            "sveIey mhly dUjy ky",
            "sveIey mhly qIjy ky",
            "sveIey mhly cauQy ky",
            "sveIey mhly pMjvy ky",
        ]),
        ("dsm", [
            "jwpu swihb",
            "Akwl ausqq cOpeI",
            "Akwl ausqq",
            "qÍ pRswid sv`Xy (sRwvg su`D)",
            "qÍ pRswid sv`Xy (dInn kI)",
            "AQ cMfIcirqR",
            "cMfI dI vwr",
            "SsqR nwm mwlw",
            "bynqI cOpeI swihb",
            "sRI BgauqI AsqoqR (pMQ pRkwS)",
            "sRI BgauqI AsqoqR (sRI hzUr swihb)",
            "augRdMqI",
            "bwrh mwhw svYXw",
            "Sbd hzwry pwiqSwhI 10",
        ]),
        ("swrIAwN bwxIAwN", [
            "gur mMqR",
            "jpujI swihb",
            "rhrwis swihb",
            "soihlw swihb",
            "vxjwrw",
            "isrIrwg kI vwr mhlw 4",
            "rwgu isrIrwgu (kbIr jIau kw)",
            "bwrh mwhw mWJ",
            "vwr mwJ kI",
            "krhly",
            "bwvn AKrI",
            "suKmnI swihb",
            "iQqI mhlw 5",
            "gauVI kI vwr mhlw 4",
            "gauVI kI vwr mhlw 5",
            "rwgu gauVI",
            "bwvn AKrI kbIr jIau kI",
            "iQqMØI kbIr jI kMØI",
            "gauVI vwr kbIr jIau ky",
            "ibrhVy",
            "ptI ilKI",
            "ptI mhlw 3",
            "Awsw dI vwr",
            "rwgu Awsw",
            "gUjrI kI vwr mhlw 3",
            "rwgu gUjrI vwr mhlw 5",
            "rwgu gUjrI",
            "ibhwgVy kI vwr mhlw 4",
            "GoVIAw",
            "vfhMs kI vwr mhlw 4",
            "rwgu soriT vwr mhly 4 kI",
            "rwgu soriT",
            "rwgu DnwsrI",
            "jYqsrI kI vwr",
            "rwgu jYqsrI",
            "rwgu tofI (bwxI BgqW kI)",
            "rwgu iqlMg (bwxI Bgqw kI kbIr jI)",
            "kucjI",
            "sucjI",
            "guxvMqI",
            "lwvW",
            "vwr sUhI kI",
            "rwgu sUhI",
            "suKmnw swihb",
            "iQqI mhlw 1",
            "iblwvlu mhlw 3 vwr sq",
            "iblwvlu kI vwr mhlw 4",
            "rwgu iblwvlu",
            "rwgu goNf",
            "Anµdu swihb",
            "rwgu rwmklI (sdu)",
            "rwmklI sdu",
            "mhlw 5 ruqI",
            "dKxI EAMkwru",
            "isD gosit",
            "rwmklI kI vwr mhlw 3",
            "rwmklI kI vwr mhlw 5",
            "rwmklI kI vwr (rwie blvMif qQw sqY)",
            "rwgu mwlI gauVw",
            "mwrU vwr mhlw 3",
            "mwrU vwr mhlw 5 fKxy",
            "rwgu mwrU",
            "rwgu kydwrw",
            "rwgu BYrau",
            "rwgu bsMqu",
            "bsMq kI vwr",
            "swrMg kI vwr mhlw 4",
            "rwgu swrMg",
            "vwr mlwr kI mhlw 1",
            "rwgu mlwr",
            "kwnVy kI vwr mhlw 4",
            "rwgu kwnVw",
            "rwgu pRBwqI",
            "Punhy mhlw 5",
            "cauboly",
            "slok Bgq kbIr jIau ky",
            "slok syK PrId ky",
            "svXy sRI muKbwk´ mhlw 5 - 1",
            "svXy sRI muKbwk´ mhlw 5 - 2",
            "sveIey mhly pihly ky",
            "sveIey mhly dUjy ky",
            "sveIey mhly qIjy ky",
            "sveIey mhly cauQy ky",
            "sveIey mhly pMjvy ky",
            "slok mhlw 9",
            "rwg mwlw",
            "AwrqI",
            "Sbd hzwry",
            "duK BMjnI swihb",
            "Ardws",
            "jwpu swihb",
            "Akwl ausqq cOpeI",
            "Akwl ausqq",
            "qÍ pRswid sv`Xy (sRwvg su`D)",
            "qÍ pRswid sv`Xy (dInn kI)",
            "AQ cMfIcirqR",
            "cMfI dI vwr",
            "SsqR nwm mwlw",
            "bynqI cOpeI swihb",
            "sRI BgauqI AsqoqR (pMQ pRkwS)",
            "sRI BgauqI AsqoqR (sRI hzUr swihb)",
            "augRdMqI",
            "bwrh mwhw svYXw",
            "Sbd hzwry pwiqSwhI 10",
        ]),
    ]

    var body: some View {
        List {
            ForEach(banis, id: \.title) { category in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedCategories.contains(category.title) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedCategories.insert(category.title)
                            } else {
                                expandedCategories.remove(category.title)
                            }
                        }
                    )
                ) {
                    ForEach(category.items, id: \.self) { baniTitle in
                        baniRow(baniTitle: baniTitle, isFavorite: favoriteBanis.contains(baniTitle))
                    }
                } label: {
                    HStack {
                        Text(category.title)
                            .font(resolveFont(size: 20, fontType: fontType == "Unicode" ? "AnmolLipiSG" : fontType))
                        Spacer()
                        Text("(\(category.items.count))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if !favoriteBanis.isEmpty {
                Section {
                    ForEach(favoriteBanis, id: \.self) { baniTitle in
                        baniRow(baniTitle: baniTitle, isFavorite: true)
                    }
                    .onMove(perform: moveFavorite)
                } header: {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Favorites")
                        Spacer()
                        Text("(\(favoriteBanis.count))")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Banis")
        .listStyle(.insetGrouped)
        .toolbar {
            if !favoriteBanis.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    private func baniRow(baniTitle: String, isFavorite: Bool) -> some View {
        ZStack {
            NavigationLink(destination: BaniView(baniTitle: baniTitle)) {
                EmptyView()
            }
            .opacity(0)

            HStack {
                Text(baniTitle)
                    .font(resolveFont(size: 18, fontType: fontType == "Unicode" ? "AnmolLipiSG" : fontType))
                    .foregroundColor(.primary)

                Spacer()

                Button(action: {
                    toggleFavorite(baniTitle)
                }) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? .yellow : .gray)
                        .font(.system(size: 18))
                }
                .buttonStyle(.borderless)
            }
            .padding(.vertical, 4)
        }
    }

    private func getCategoryIcon(_ title: String) -> String {
        switch title {
        case "Nitnem": return "sunrise.fill"
        case "Fun Size": return "timer"
        case "5 Granthi": return "book.closed.fill"
        case "22 Vaaran": return "books.vertical.fill"
        case "Svaiye": return "scroll.fill"
        case "Dasam": return "sparkles"
        case "ALL": return "square.grid.3x3.fill"
        default: return "book.fill"
        }
    }
}
