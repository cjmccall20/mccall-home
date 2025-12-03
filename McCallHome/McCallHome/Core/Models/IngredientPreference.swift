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
    var displayName: String?   // User's preferred display name for grocery list
    var brand: String?         // Specific brand for Instacart (e.g., "Kikkoman Organic")
    var preferredStore: Store?
    var isInPerson: Bool       // True if user prefers to select this item in person
    var isHouseStaple: Bool    // True if this should be on the House Staples list
    var isPantryStaple: Bool   // True if this should be on the Pantry Staples list
    var isOrganic: Bool        // True if user prefers organic version
    var labels: [String]       // Food labels (grass-fed, wild-caught, kosher, etc.)
    var customLabels: [String] // User-defined custom labels
    var notes: String?         // Any additional notes
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case canonicalName = "canonical_name"
        case displayName = "display_name"
        case brand
        case preferredStore = "preferred_store"
        case isInPerson = "is_in_person"
        case isHouseStaple = "is_house_staple"
        case isPantryStaple = "is_pantry_staple"
        case isOrganic = "is_organic"
        case labels
        case customLabels = "custom_labels"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        householdId: UUID,
        canonicalName: String,
        displayName: String? = nil,
        brand: String? = nil,
        preferredStore: Store? = nil,
        isInPerson: Bool = false,
        isHouseStaple: Bool = false,
        isPantryStaple: Bool = false,
        isOrganic: Bool = false,
        labels: [String] = [],
        customLabels: [String] = [],
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.householdId = householdId
        self.canonicalName = canonicalName
        self.displayName = displayName
        self.brand = brand
        self.preferredStore = preferredStore
        self.isInPerson = isInPerson
        self.isHouseStaple = isHouseStaple
        self.isPantryStaple = isPantryStaple
        self.isOrganic = isOrganic
        self.labels = labels
        self.customLabels = customLabels
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
        brand = try container.decodeIfPresent(String.self, forKey: .brand)

        // Handle store as string from DB
        if let storeString = try container.decodeIfPresent(String.self, forKey: .preferredStore) {
            preferredStore = Store(rawValue: storeString)
        } else {
            preferredStore = nil
        }

        isInPerson = try container.decodeIfPresent(Bool.self, forKey: .isInPerson) ?? false
        isHouseStaple = try container.decodeIfPresent(Bool.self, forKey: .isHouseStaple) ?? false
        isPantryStaple = try container.decodeIfPresent(Bool.self, forKey: .isPantryStaple) ?? false
        isOrganic = try container.decodeIfPresent(Bool.self, forKey: .isOrganic) ?? false
        labels = try container.decodeIfPresent([String].self, forKey: .labels) ?? []
        customLabels = try container.decodeIfPresent([String].self, forKey: .customLabels) ?? []
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

    /// All labels combined (standard + custom) as FoodLabel display names
    var allLabelDisplayNames: [String] {
        var result: [String] = []

        // Add organic if set
        if isOrganic {
            result.append("Organic")
        }

        // Add standard labels
        for labelRawValue in labels {
            if let label = FoodLabel(rawValue: labelRawValue) {
                result.append(label.displayName)
            }
        }

        // Add custom labels
        result.append(contentsOf: customLabels)

        return result
    }

    /// Build a search query string for Instacart including all labels
    /// e.g., "grass-fed organic ground beef" or "Kikkoman organic soy sauce"
    func buildInstacartSearchQuery(for ingredientName: String) -> String {
        var parts: [String] = []

        // Add labels first (most specific to least)
        parts.append(contentsOf: allLabelDisplayNames)

        // Add brand if specified
        if let brand = brand, !brand.isEmpty {
            parts.append(brand)
        }

        // Add the ingredient name (use display name if available)
        let name = displayName ?? ingredientName
        parts.append(name)

        return parts.joined(separator: " ")
    }
}
