//
//  SavedShabadModel.swift
//  Chet
//
//  Created by gian singh on 8/29/25.
//

import Foundation
import SwiftData

@Model
final class FavoriteShabad {
    @Attribute(.unique) var shabadID: String
    @Relationship(deleteRule: .cascade)  var selectedLine: LineOfShabad
    @Relationship(deleteRule: .cascade) var shabad: ShabadAPIResponse
    var dateViewed: Date
    
    init(shabadResponse: ShabadAPIResponse, selectedLine: LineOfShabad) {
        self.shabadID = shabadResponse.shabadinfo.shabadid
        self.selectedLine = selectedLine
        self.shabad = shabadResponse
        self.dateViewed = Date()
    }
}

@Model
final class ShabadHistory {
    @Attribute(.unique) var shabadID: String
    @Relationship(deleteRule: .cascade)  var selectedLine: LineOfShabad
    @Relationship(deleteRule: .cascade) var shabad: ShabadAPIResponse
    var dateViewed: Date
    
    init(shabadResponse: ShabadAPIResponse, selectedLine: LineOfShabad) {
        self.shabadID = shabadResponse.shabadinfo.shabadid
        self.selectedLine = selectedLine
        self.shabad = shabadResponse
        self.dateViewed = Date()
    }
} 

extension ModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([FavoriteShabad.self, ShabadHistory.self])
        let config = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier("group.xyz.gians.Chet") // 👈 must match App Group ID
        )
        return try! ModelContainer(for: schema, configurations: [config])
    }()
}
