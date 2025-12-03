//
//  HouseStaple.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import Foundation

struct HouseStaple: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    var name: String
    var quantity: String?
    var category: String
    var notes: String?
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case name
        case quantity
        case category
        case notes
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        householdId: UUID,
        name: String,
        quantity: String? = nil,
        category: String = "Other",
        notes: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.householdId = householdId
        self.name = name
        self.quantity = quantity
        self.category = category
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        householdId = try container.decode(UUID.self, forKey: .householdId)
        name = try container.decode(String.self, forKey: .name)
        quantity = try container.decodeIfPresent(String.self, forKey: .quantity)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "Other"
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true

        // Handle dates
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            createdAt = Self.parseDate(dateString) ?? Date()
        } else {
            createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        }

        if let dateString = try? container.decode(String.self, forKey: .updatedAt) {
            updatedAt = Self.parseDate(dateString) ?? Date()
        } else {
            updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        }
    }

    private static func parseDate(_ string: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: string) {
            return date
        }
        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.date(from: string)
    }

    // Common grocery categories
    static let categories = [
        "Produce",
        "Dairy",
        "Meat & Seafood",
        "Bakery",
        "Frozen",
        "Pantry",
        "Beverages",
        "Snacks",
        "Household",
        "Personal Care",
        "Other"
    ]

    var displayText: String {
        if let qty = quantity, !qty.isEmpty {
            return "\(name) (\(qty))"
        }
        return name
    }
}
