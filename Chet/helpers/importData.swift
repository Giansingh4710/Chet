import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let igb = UTType(filenameExtension: "igb")!
    static let gkhoj = UTType(filenameExtension: "gkhoj")!
    static let chetBackup = UTType(filenameExtension: "chet")!
}

func parseArrayForGKImports(
    _ array: [Any],
    modelContext: ModelContext,
    folderName: String = "Gurbani Khoj Imports",
    onShabadImported: @escaping () async -> Void
) async -> Folder {
    let folder = Folder(name: folderName)
    modelContext.insert(folder)

    var count = 0

    var sortCounter = array.count // start from total count
    for element in array {
        count += 1
        // if count > 20 { break }
        guard let sub = element as? [Any] else {
            continue
        }

        do {
            // Case 1: [text, id] leaf
            if sub.count == 2,
               let text = sub[0] as? String,
               let id = (sub[1] as? Int) ?? Int((sub[1] as? String) ?? "")
            {
                if let savedShadab = try await getSavedSbdObj(sbdID: id, savedLine: text, folder: folder) {
                    savedShadab.sortIndex = sortCounter
                    sortCounter -= 1
                    modelContext.insert(savedShadab)
                    folder.savedShabads.append(savedShadab)
                    await onShabadImported()
                }
            }
            // Case 2: duplicate leaf [text, page, text, page]
            else if sub.count == 4,
                    let text = sub[0] as? String,
                    let id = (sub[1] as? Int) ?? Int((sub[1] as? String) ?? "")
            {
                if let savedShadab = try await getSavedSbdObj(sbdID: id, savedLine: text, folder: folder) {
                    modelContext.insert(savedShadab)
                    folder.savedShabads.append(savedShadab)
                    await onShabadImported()
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
    let igurbaniids = loadiGurbaniids()
    for favorite in favorites {
        count += 1
        // if count > 50 { break }
        guard let shabadUid = favorite["shabadUid"] as? String else {
            print("shabadUid not found")
            continue
        }
        guard let gurmukhi = favorite["gurmukhi"] as? String else {
            print("gurmukhi not found")
            continue
        }
        do {
            guard let banidb_shabadid = igurbaniids[shabadUid] else {
                print("banidb shabadid not found")
                continue
            }

            if let savedShadab = try await getSavedSbdObj(sbdID: banidb_shabadid, savedLine: gurmukhi, folder: folder) {
                savedShadab.sortIndex = sortCounter
                sortCounter -= 1
                modelContext.insert(savedShadab)
                folder.savedShabads.append(savedShadab)
                await onShabadImported()
            }
        } catch {
            print("❌ Error processing '\(gurmukhi)': \(error)")
        }
    }
    return folder
}

func parseArrayForKeertanPothi(
    _ array: [[String: Any]],
    modelContext: ModelContext,
    onShabadImported: @escaping () async -> Void
) async -> Folder {
    // Create parent folder for all pothis
    let parentFolder = Folder(name: "Keertan Pothi Imports")
    modelContext.insert(parentFolder)

    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    for pothiData in array {
        // Extract pothi metadata
        guard let pothiInfo = pothiData["pothi"] as? [String: Any],
              let pothiName = pothiInfo["Name"] as? String,
              let shabadList = pothiData["shabadList"] as? [[String: Any]]
        else {
            print("Failed to parse pothi structure")
            continue
        }

        // Create subfolder for this pothi
        let folder = Folder(name: pothiName, parentFolder: parentFolder)
        modelContext.insert(folder)
        parentFolder.subfolders.append(folder)

        // Process shabads in this pothi
        var sortCounter = shabadList.count
        for shabadData in shabadList {
            guard let shabadId = shabadData["ShabadId"] as? Int else {
                print("ShabadId not found in shabad data")
                continue
            }

            do {
                // Try to fetch the shabad using the ID directly
                // (Assuming Keertan Pothi uses BaniDB IDs)
                let sbdRes = try await fetchShabadResponse(from: shabadId)

                // Find the saved line using VerseId
                var lineIndex = 0
                if let verseId = shabadData["VerseId"] as? Int {
                    // Find the verse with matching ID
                    if let foundIndex = sbdRes.verses.firstIndex(where: { $0.id == verseId }) {
                        lineIndex = foundIndex
                    } else {
                        print("⚠️ VerseId \(verseId) not found in shabad \(shabadId), using first line")
                    }
                }

                let savedShabad = SavedShabad(folder: folder, sbdRes: sbdRes, indexOfSelectedLine: lineIndex)

                // Preserve sort order from Keertan Pothi
                if let sortOrder = shabadData["SortOrder"] as? Int {
                    savedShabad.sortIndex = sortOrder
                } else {
                    savedShabad.sortIndex = sortCounter
                    sortCounter -= 1
                }

                modelContext.insert(savedShabad)
                folder.savedShabads.append(savedShabad)
                await onShabadImported()
            } catch {
                print("❌ Error fetching shabad ID \(shabadId): \(error)")
                continue
            }
        }
    }

    return parentFolder
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

func loadiGurbaniids() -> [String: Int] {
    guard let url = Bundle.main.url(forResource: "igurbaniuid_to_id", withExtension: "json") else {
        return [:]
    }

    do {
        let data = try Data(contentsOf: url)
        let codes = try JSONDecoder().decode([String: Int].self, from: data)
        return codes
    } catch {
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

    return bestIndex
}
