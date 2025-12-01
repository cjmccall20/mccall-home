//
//  PantryStaple.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation

struct PantryStaple: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    var name: String
    var category: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case name
        case category
        case createdAt = "created_at"
    }
}
