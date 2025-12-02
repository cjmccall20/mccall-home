//
//  Recipe.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation

struct Recipe: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    var title: String
    var sourceUrl: String?
    var sourceType: SourceType?
    var dishCategory: DishCategory  // New: categorize as entree, side, appetizer, etc.
    var mealCategory: MealCategory  // Which meal of the day (breakfast, lunch, dinner, any)
    var proteinType: ProteinType
    var baseServings: Int
    var ingredients: [Ingredient]
    var steps: [RecipeStep]
    var tags: [String]?
    var prepTime: Int?
    var cookTime: Int?
    var notes: String?
    let createdAt: Date
    var updatedAt: Date

    enum SourceType: String, Codable, CaseIterable {
        case url, manual, imported
    }

    enum DishCategory: String, Codable, CaseIterable {
        case entree
        case side
        case appetizer
        case dessert
        case drink
        case breakfast
        case snack
        case other

        var displayName: String {
            switch self {
            case .entree: return "Entrée"
            case .side: return "Side Dish"
            case .appetizer: return "Appetizer"
            case .dessert: return "Dessert"
            case .drink: return "Drink"
            case .breakfast: return "Breakfast"
            case .snack: return "Snack"
            case .other: return "Other"
            }
        }

        var iconName: String {
            switch self {
            case .entree: return "fork.knife"
            case .side: return "leaf"
            case .appetizer: return "sparkles"
            case .dessert: return "birthday.cake"
            case .drink: return "cup.and.saucer"
            case .breakfast: return "sunrise"
            case .snack: return "popcorn"
            case .other: return "square.grid.2x2"
            }
        }

        var sortOrder: Int {
            switch self {
            case .entree: return 0
            case .side: return 1
            case .appetizer: return 2
            case .dessert: return 3
            case .drink: return 4
            case .breakfast: return 5
            case .snack: return 6
            case .other: return 7
            }
        }
    }

    enum ProteinType: String, Codable, CaseIterable {
        case beef
        case chicken
        case pork
        case lamb
        case turkey
        case shrimp
        case salmon
        case fish
        case vegetarian
        case other

        var displayName: String {
            switch self {
            case .fish: return "Fish (Other)"
            case .vegetarian: return "Vegetarian/Vegan"
            case .other: return "Other"
            default: return rawValue.capitalized
            }
        }

        var sortOrder: Int {
            switch self {
            case .chicken: return 0
            case .beef: return 1
            case .pork: return 2
            case .salmon: return 3
            case .shrimp: return 4
            case .fish: return 5
            case .turkey: return 6
            case .lamb: return 7
            case .vegetarian: return 8
            case .other: return 9
            }
        }
    }

    /// Meal category - which meal of the day this recipe is suitable for
    enum MealCategory: String, Codable, CaseIterable {
        case breakfast
        case lunch
        case dinner
        case any  // Suitable for any meal

        var displayName: String {
            switch self {
            case .any: return "Any Meal"
            default: return rawValue.capitalized
            }
        }

        var iconName: String {
            switch self {
            case .breakfast: return "sunrise"
            case .lunch: return "sun.max"
            case .dinner: return "moon.stars"
            case .any: return "clock"
            }
        }

        /// Check if this category matches a meal type
        func matches(_ mealType: MealPlanEntry.MealType) -> Bool {
            switch self {
            case .any: return true
            case .breakfast: return mealType == .breakfast
            case .lunch: return mealType == .lunch
            case .dinner: return mealType == .dinner
            }
        }
    }

    struct Ingredient: Codable, Equatable, Identifiable {
        var id: UUID = UUID()
        var name: String
        var quantity: Double?
        var unit: String?
        var notes: String?

        enum CodingKeys: String, CodingKey {
            case name, quantity, unit, notes
        }

        init(id: UUID = UUID(), name: String, quantity: Double? = nil, unit: String? = nil, notes: String? = nil) {
            self.id = id
            self.name = name
            self.quantity = quantity
            self.unit = unit
            self.notes = notes
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = UUID()
            self.name = try container.decode(String.self, forKey: .name)
            self.quantity = try container.decodeIfPresent(Double.self, forKey: .quantity)
            self.unit = try container.decodeIfPresent(String.self, forKey: .unit)
            self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
        }
    }

    struct RecipeStep: Codable, Equatable, Identifiable {
        var id: UUID = UUID()
        var stepNumber: Int
        var instruction: String

        enum CodingKeys: String, CodingKey {
            case stepNumber = "step_number"
            case instruction
        }

        init(id: UUID = UUID(), stepNumber: Int, instruction: String) {
            self.id = id
            self.stepNumber = stepNumber
            self.instruction = instruction
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = UUID()
            self.stepNumber = try container.decode(Int.self, forKey: .stepNumber)
            self.instruction = try container.decode(String.self, forKey: .instruction)
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case title
        case sourceUrl = "source_url"
        case sourceType = "source_type"
        case dishCategory = "dish_category"
        case mealCategory = "meal_category"
        case proteinType = "protein_type"
        case baseServings = "base_servings"
        case ingredients
        case steps
        case tags
        case prepTime = "prep_time"
        case cookTime = "cook_time"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(id: UUID, householdId: UUID, title: String, sourceUrl: String? = nil, sourceType: SourceType? = nil, dishCategory: DishCategory = .entree, mealCategory: MealCategory = .dinner, proteinType: ProteinType = .other, baseServings: Int = 4, ingredients: [Ingredient] = [], steps: [RecipeStep] = [], tags: [String]? = nil, prepTime: Int? = nil, cookTime: Int? = nil, notes: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.householdId = householdId
        self.title = title
        self.sourceUrl = sourceUrl
        self.sourceType = sourceType
        self.dishCategory = dishCategory
        self.mealCategory = mealCategory
        self.proteinType = proteinType
        self.baseServings = baseServings
        self.ingredients = ingredients
        self.steps = steps
        self.tags = tags
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        householdId = try container.decode(UUID.self, forKey: .householdId)
        title = try container.decode(String.self, forKey: .title)
        sourceUrl = try container.decodeIfPresent(String.self, forKey: .sourceUrl)
        sourceType = try container.decodeIfPresent(SourceType.self, forKey: .sourceType)

        // Handle dish category with default
        dishCategory = try container.decodeIfPresent(DishCategory.self, forKey: .dishCategory) ?? .entree

        // Handle meal category with default (dinner for existing recipes)
        mealCategory = try container.decodeIfPresent(MealCategory.self, forKey: .mealCategory) ?? .dinner

        // Handle protein type with default
        proteinType = try container.decodeIfPresent(ProteinType.self, forKey: .proteinType) ?? .other

        baseServings = try container.decodeIfPresent(Int.self, forKey: .baseServings) ?? 4
        ingredients = try container.decodeIfPresent([Ingredient].self, forKey: .ingredients) ?? []
        steps = try container.decodeIfPresent([RecipeStep].self, forKey: .steps) ?? []
        tags = try container.decodeIfPresent([String].self, forKey: .tags)

        // Handle prep_time - can be Int or interval string from PostgreSQL
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: .prepTime) {
            prepTime = intValue
        } else if let stringValue = try? container.decodeIfPresent(String.self, forKey: .prepTime) {
            prepTime = Recipe.parseInterval(stringValue)
        } else {
            prepTime = nil
        }

        // Handle cook_time - can be Int or interval string from PostgreSQL
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: .cookTime) {
            cookTime = intValue
        } else if let stringValue = try? container.decodeIfPresent(String.self, forKey: .cookTime) {
            cookTime = Recipe.parseInterval(stringValue)
        } else {
            cookTime = nil
        }

        notes = try container.decodeIfPresent(String.self, forKey: .notes)

        // Handle dates - may have fractional seconds
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

    /// Parse PostgreSQL interval string (HH:MM:SS) to minutes
    private static func parseInterval(_ intervalString: String) -> Int? {
        // Format: "HH:MM:SS" or "00:00:05" for 5 seconds
        let parts = intervalString.split(separator: ":")
        guard parts.count == 3,
              let hours = Int(parts[0]),
              let minutes = Int(parts[1]),
              let seconds = Int(parts[2]) else {
            return nil
        }
        // Convert to total minutes (round seconds to nearest minute)
        let totalMinutes = hours * 60 + minutes + (seconds >= 30 ? 1 : 0)
        // If total is 0 but we had seconds, return the seconds as the value
        // (handles case where prep_time was stored as seconds instead of minutes)
        if totalMinutes == 0 && seconds > 0 {
            return seconds
        }
        return totalMinutes > 0 ? totalMinutes : nil
    }
}
