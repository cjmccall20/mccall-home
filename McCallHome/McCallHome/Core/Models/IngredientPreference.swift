//
//  IngredientPreference.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import Foundation

/// User preferences for a specific ingredient (brand, store, in-person preference)
struct IngredientPreference: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    var canonicalName: String  // Normalized ingredient name (e.g., "soy sauce")
    var displayName: String?   // User's preferred brand/name (e.g., "Kikkoman Organic Soy Sauce")
    var preferredStore: Store?
    var isInPerson: Bool       // True if user prefers to select this item in person
    var notes: String?         // Any additional notes
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case canonicalName = "canonical_name"
        case displayName = "display_name"
        case preferredStore = "preferred_store"
        case isInPerson = "is_in_person"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        householdId: UUID,
        canonicalName: String,
        displayName: String? = nil,
        preferredStore: Store? = nil,
        isInPerson: Bool = false,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.householdId = householdId
        self.canonicalName = canonicalName
        self.displayName = displayName
        self.preferredStore = preferredStore
        self.isInPerson = isInPerson
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        householdId = try container.decode(UUID.self, forKey: .householdId)
        canonicalName = try container.decode(String.self, forKey: .canonicalName)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)

        // Handle store as string from DB
        if let storeString = try container.decodeIfPresent(String.self, forKey: .preferredStore) {
            preferredStore = Store(rawValue: storeString)
        } else {
            preferredStore = nil
        }

        isInPerson = try container.decodeIfPresent(Bool.self, forKey: .isInPerson) ?? false
        notes = try container.decodeIfPresent(String.self, forKey: .notes)

        // Handle dates with fractional seconds
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
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

        if let dateString = try? container.decode(String.self, forKey: .updatedAt) {
            if let date = isoFormatter.date(from: dateString) {
                updatedAt = date
            } else if let date = ISO8601DateFormatter().date(from: dateString) {
                updatedAt = date
            } else {
                updatedAt = Date()
            }
        } else {
            updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        }
    }

    /// The name to display (uses displayName if set, otherwise canonicalName)
    var effectiveDisplayName: String {
        displayName ?? canonicalName.capitalized
    }
}
