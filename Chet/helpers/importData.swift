import Foundation
import SwiftData
import UniformTypeIdentifiers

extension UTType {
    static let igb = UTType(filenameExtension: "igb")!
    static let gkhoj = UTType(filenameExtension: "gkhoj")!
}

func parseArrayForGKImports(
    _ array: [Any],
    modelContext: ModelContext,
    folderName: String = "Gurbani Khoj Imports",
    onShabadImported: @escaping () async -> Void
) async -> Folder {
    let sttmids = loadSttmids()
    // let sttmids = loadJSON(from: "sttmid_to_id")
    let folder = Folder(name: folderName)
    modelContext.insert(folder)

    var count = 0

    var sortCounter = array.count // start from total count
    for element in array {
        count += 1
        // if count > 20 { break }
        guard let sub = element as? [Any] else {
            print("Unexpected element:", element)
            continue
        }

        do {
            // Case 1: [text, id] leaf
            if sub.count == 2,
               let text = sub[0] as? String,
               let id = (sub[1] as? Int) ?? Int((sub[1] as? String) ?? "")
            {
                if let gurbaninowIDString = sttmids[id],
                    let gurbaninowID = Int(gurbaninowIDString) {
                    if let savedShadab = try await getSavedSbdObj(sbdID: gurbaninowID, savedLine: text, folder: folder) {
                        savedShadab.sortIndex = sortCounter
                        sortCounter -= 1
                        modelContext.insert(savedShadab)
                        folder.savedShabads.append(savedShadab)
                        await onShabadImported()
                    }
                }
            }
            // Case 2: duplicate leaf [text, page, text, page]
            else if sub.count == 4,
                    let text = sub[0] as? String,
                    let id = (sub[1] as? Int) ?? Int((sub[1] as? String) ?? "")
            {
                if let gurbaninowIDString = sttmids[id],
                    let gurbaninowID = Int(gurbaninowIDString) {

                    if let savedShadab = try await getSavedSbdObj(sbdID: gurbaninowID, savedLine: text, folder: folder) {
                        modelContext.insert(savedShadab)
                        folder.savedShabads.append(savedShadab)
                        await onShabadImported()
                    }
                }
            }

            // Case 2: [name, [children]]
            else if sub.count == 2,
                    let name = sub[0] as? String,
                    let children = sub[1] as? [Any]
            {
                let subfolder = await parseArrayForGKImports(children, modelContext: modelContext, folderName: name, onShabadImported: onShabadImported)
                subfolder.parentFolder = folder
                folder.subfolders.append(subfolder)
            }
            // Case 3: fallback (nested arrays)
            else {
                // result.append(contentsOf: parseArray(sub))
                print("Unexpected element:", sub)
            }
        } catch {
            print("Error: \(error)")
        }
    }

    return folder
}

func parseArrayForiGurbani(
    _ json: [String: Any],
    modelContext: ModelContext,
    folderName: String = "iGurbani Imports",
    onShabadImported: @escaping () async -> Void
) async -> Folder {
    let folder = Folder(name: folderName)
    let igurbani_ids = loadiGurbaniids()

    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    guard
        let shabadFavorites = json["shabadFavorites"] as? [String: Any],
        let favorites = shabadFavorites["favorites"] as? [[String: Any]]
    else {
        print("Favorites not found")
        return folder
    }

    var sortCounter = favorites.count // start from total count
    var count = 1
    for favorite in favorites {
        count += 1
        // if count > 50 { break }
        guard let gurmukhi = favorite["gurmukhi"] as? String else {
            print("Gurmukhi not found")
            continue
        }
        do {
            guard let uid = favorite["shabadUid"] as? String else {
                print("UID not found for \(gurmukhi)")
                continue
            }
                
            if let gurbaninowIDString = igurbani_ids[uid],
               let gurbaninowID = Int(gurbaninowIDString) {
                if let savedShadab = try await getSavedSbdObj(sbdID: gurbaninowID, savedLine: gurmukhi, folder: folder) {
                    if let createdDateString = favorite["createdDate"] as? String {
                        if let parsedDate = isoFormatter.date(from: createdDateString) {
                            savedShadab.addedAt = parsedDate
                        } else {
                            print("⚠️ Could not parse date: \(createdDateString)")
                        }
                    }
                    // savedShadab.sortIndex = count * -1
                    savedShadab.sortIndex = sortCounter
                    sortCounter -= 1
                    modelContext.insert(savedShadab)
                    folder.savedShabads.append(savedShadab)
                    await onShabadImported()
                }
            }
        } catch {
            print("Error: \(error)")
        }
    }
    return folder
}

func getSavedSbdObj(sbdID: Int, savedLine: String, folder: Folder) async throws -> SavedShabad? {
    do {
        let sbdRes = try await fetchShabadResponse(from: sbdID)
        let indexOfLine = fuzzyBestMatchIndex(lines: sbdRes.verses, savedLine: savedLine)
        return SavedShabad(folder: folder, sbdRes: sbdRes, indexOfSelectedLine: indexOfLine)
    } catch {
        throw URLError(.badServerResponse)
    }
}

func loadiGurbaniids() -> [String: String] {
    guard let url = Bundle.main.url(forResource: "igurbaniuid_to_id", withExtension: "json") else {
        print("JSON file not found")
        return [:]
    }

    do {
        let data = try Data(contentsOf: url)
        let codes = try JSONDecoder().decode([String: String].self, from: data)
        return codes
    } catch {
        print("Error decoding JSON: \(error)")
        return [:]
    }
}

func loadSttmids() -> [Int: String] {
    guard let url = Bundle.main.url(forResource: "sttmid_to_id", withExtension: "json") else {
        print("JSON file not found")
        return [:]
    }

    do {
        let data = try Data(contentsOf: url)
        // let codes = try JSONDecoder().decode([String: String].self, from: data)
        let codes = try JSONDecoder().decode([Int: String].self, from: data)
        return codes
    } catch {
        print("Error decoding JSON: \(error)")
        return [:]
    }
}

func fuzzyBestMatchIndex(lines: [Verse], savedLine: String) -> Int {
    func levenshtein(_ a: String, _ b: String) -> Int {
        let aChars = Array(a)
        let bChars = Array(b)
        let aCount = aChars.count
        let bCount = bChars.count

        var dist = Array(repeating: Array(repeating: 0, count: bCount + 1), count: aCount + 1)

        for i in 0 ... aCount {
            dist[i][0] = i
        }
        for j in 0 ... bCount {
            dist[0][j] = j
        }

        for i in 1 ... aCount {
            for j in 1 ... bCount {
                if aChars[i - 1] == bChars[j - 1] {
                    dist[i][j] = dist[i - 1][j - 1]
                } else {
                    dist[i][j] = min(
                        dist[i - 1][j] + 1, // deletion
                        dist[i][j - 1] + 1, // insertion
                        dist[i - 1][j - 1] + 1 // substitution
                    )
                }
            }
        }

        return dist[aCount][bCount]
    }

    var bestIndex = 0
    var bestScore = Int.max

    for (index, line) in lines.enumerated() {
        let distance = levenshtein(line.verse.gurmukhi, savedLine)
        if distance < bestScore {
            bestScore = distance
            bestIndex = index
        }
    }

    print("Best match index: \(bestIndex) with score: \(bestScore)")
    return bestIndex
}
