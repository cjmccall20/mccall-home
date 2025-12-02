//
//  GroceryItem.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation
import Combine

struct GroceryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let groceryListId: UUID
    var name: String
    var quantity: Double?
    var unit: String?
    var category: Category
    var isChecked: Bool
    var sortOrder: Int
    var source: Source
    var fromRecipeId: UUID?
    let createdAt: Date

    enum Source: String, Codable, CaseIterable {
        case mealPlan = "meal_plan"
        case manual
        case staple

        var displayName: String {
            switch self {
            case .mealPlan: return "From Meal Plan"
            case .manual: return "Manual"
            case .staple: return "Staple"
            }
        }
    }

    enum Category: String, Codable, CaseIterable {
        case verifyPantry = "verify_pantry"
        case produce
        case dairy
        case meat
        case bakery
        case pantry
        case frozen
        case beverages
        case other

        var displayName: String {
            switch self {
            case .verifyPantry: return "Pantry Check"
            case .produce: return "Produce"
            case .dairy: return "Dairy & Eggs"
            case .meat: return "Meat & Seafood"
            case .bakery: return "Bakery"
            case .pantry: return "Pantry"
            case .frozen: return "Frozen"
            case .beverages: return "Beverages"
            case .other: return "Other"
            }
        }

        var sortOrder: Int {
            switch self {
            case .verifyPantry: return 0
            case .produce: return 1
            case .bakery: return 2
            case .dairy: return 3
            case .meat: return 4
            case .pantry: return 5
            case .frozen: return 6
            case .beverages: return 7
            case .other: return 8
            }
        }

        var iconName: String {
            switch self {
            case .verifyPantry: return "checklist"
            case .produce: return "leaf"
            case .dairy: return "drop"
            case .meat: return "fork.knife"
            case .bakery: return "birthday.cake"
            case .pantry: return "cabinet"
            case .frozen: return "snowflake"
            case .beverages: return "cup.and.saucer"
            case .other: return "bag"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case groceryListId = "grocery_list_id"
        case name
        case quantity
        case unit
        case category
        case isChecked = "is_checked"
        case sortOrder = "sort_order"
        case source
        case fromRecipeId = "from_recipe_id"
        case createdAt = "created_at"
    }

    init(id: UUID = UUID(), groceryListId: UUID, name: String, quantity: Double? = nil, unit: String? = nil, category: Category = .other, isChecked: Bool = false, sortOrder: Int = 0, source: Source = .manual, fromRecipeId: UUID? = nil, createdAt: Date = Date()) {
        self.id = id
        self.groceryListId = groceryListId
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.isChecked = isChecked
        self.sortOrder = sortOrder
        self.source = source
        self.fromRecipeId = fromRecipeId
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        groceryListId = try container.decode(UUID.self, forKey: .groceryListId)
        name = try container.decode(String.self, forKey: .name)
        quantity = try container.decodeIfPresent(Double.self, forKey: .quantity)
        unit = try container.decodeIfPresent(String.self, forKey: .unit)
        category = try container.decodeIfPresent(Category.self, forKey: .category) ?? .other
        isChecked = try container.decodeIfPresent(Bool.self, forKey: .isChecked) ?? false
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        source = try container.decodeIfPresent(Source.self, forKey: .source) ?? .manual
        fromRecipeId = try container.decodeIfPresent(UUID.self, forKey: .fromRecipeId)

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

    var quantityDisplay: String {
        guard let qty = quantity else { return "" }

        let formatted = qty.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", qty)
            : String(format: "%.1f", qty)

        if let unit = unit, !unit.isEmpty {
            return "\(formatted) \(unit)"
        }
        return formatted
    }
}

// MARK: - Previous Grocery Item (for quick re-add)

struct PreviousGroceryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    var name: String
    var category: GroceryItem.Category
    var timesUsed: Int
    var lastUsedAt: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case name
        case category
        case timesUsed = "times_used"
        case lastUsedAt = "last_used_at"
        case createdAt = "created_at"
    }

    init(id: UUID = UUID(), householdId: UUID, name: String, category: GroceryItem.Category = .other, timesUsed: Int = 1, lastUsedAt: Date = Date(), createdAt: Date = Date()) {
        self.id = id
        self.householdId = householdId
        self.name = name
        self.category = category
        self.timesUsed = timesUsed
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        householdId = try container.decode(UUID.self, forKey: .householdId)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decodeIfPresent(GroceryItem.Category.self, forKey: .category) ?? .other
        timesUsed = try container.decodeIfPresent(Int.self, forKey: .timesUsed) ?? 1

        // Handle dates - may have fractional seconds
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let dateString = try? container.decode(String.self, forKey: .lastUsedAt) {
            if let date = isoFormatter.date(from: dateString) {
                lastUsedAt = date
            } else if let date = ISO8601DateFormatter().date(from: dateString) {
                lastUsedAt = date
            } else {
                lastUsedAt = Date()
            }
        } else {
            lastUsedAt = try container.decodeIfPresent(Date.self, forKey: .lastUsedAt) ?? Date()
        }

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
    }
}
