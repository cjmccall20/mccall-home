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

    init(id: UUID = UUID(), householdId: UUID, name: String, category: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.householdId = householdId
        self.name = name
        self.category = category
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        householdId = try container.decode(UUID.self, forKey: .householdId)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decodeIfPresent(String.self, forKey: .category)

        // Handle date - may have fractional seconds
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                createdAt = date
            } else if let date = ISO8601DateFormatter().date(from: dateString) {
                createdAt = date
            } else {
                createdAt = Date()
            }
        } else {
            createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        }
    }
}
