//
//  MealPlanTemplate.swift
//  McCallHome
//
//  Created by Claude on 12/3/25.
//

import Foundation

/// A saved week template that can be applied to any future week
struct MealPlanTemplate: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    var name: String
    var entries: [TemplateEntry]
    var isRotating: Bool  // If true, this template is part of a rotating schedule
    var rotationOrder: Int?  // Order in the rotation (1, 2, 3, etc.)
    var notes: String?
    let createdAt: Date
    var updatedAt: Date

    struct TemplateEntry: Codable, Identifiable, Equatable {
        var id: UUID
        var dayOfWeek: Int  // 0 = Sunday, 6 = Saturday
        var mealType: MealPlanEntry.MealType
        var recipeId: UUID?  // For recipe-based entries
        var servingsOverride: Int?  // Custom servings for recipes
        var isEatOut: Bool
        var eatOutLocation: String?
        var restaurantId: UUID?
        var isLeftovers: Bool
        var leftoversNote: String?
        var isIngredientOnly: Bool
        var ingredientName: String?
        var ingredientQuantity: String?

        init(
            id: UUID = UUID(),
            dayOfWeek: Int,
            mealType: MealPlanEntry.MealType,
            recipeId: UUID? = nil,
            servingsOverride: Int? = nil,
            isEatOut: Bool = false,
            eatOutLocation: String? = nil,
            restaurantId: UUID? = nil,
            isLeftovers: Bool = false,
            leftoversNote: String? = nil,
            isIngredientOnly: Bool = false,
            ingredientName: String? = nil,
            ingredientQuantity: String? = nil
        ) {
            self.id = id
            self.dayOfWeek = dayOfWeek
            self.mealType = mealType
            self.recipeId = recipeId
            self.servingsOverride = servingsOverride
            self.isEatOut = isEatOut
            self.eatOutLocation = eatOutLocation
            self.restaurantId = restaurantId
            self.isLeftovers = isLeftovers
            self.leftoversNote = leftoversNote
            self.isIngredientOnly = isIngredientOnly
            self.ingredientName = ingredientName
            self.ingredientQuantity = ingredientQuantity
        }

        /// Create a template entry from an existing meal plan entry
        static func from(_ entry: MealPlanEntry, dayOfWeek: Int) -> TemplateEntry {
            TemplateEntry(
                id: UUID(),
                dayOfWeek: dayOfWeek,
                mealType: entry.mealType,
                recipeId: entry.recipeId,
                servingsOverride: entry.servingsOverride,
                isEatOut: entry.isEatOut,
                eatOutLocation: entry.eatOutLocation,
                restaurantId: entry.restaurantId,
                isLeftovers: entry.isLeftovers,
                leftoversNote: entry.leftoversNote,
                isIngredientOnly: entry.isIngredientOnly,
                ingredientName: entry.ingredientName,
                ingredientQuantity: entry.ingredientQuantity
            )
        }

        /// Convert template entry to meal plan entry for a specific date
        func toMealPlanEntry(for date: Date, householdId: UUID) -> MealPlanEntry {
            MealPlanEntry(
                id: UUID(),
                householdId: householdId,
                recipeId: recipeId,
                scheduledDate: date,
                mealType: mealType,
                servingsOverride: servingsOverride,
                isEatOut: isEatOut,
                eatOutLocation: eatOutLocation,
                restaurantId: restaurantId,
                orderIds: [],
                isLeftovers: isLeftovers,
                leftoversNote: leftoversNote,
                isIngredientOnly: isIngredientOnly,
                ingredientId: nil,
                ingredientName: ingredientName,
                ingredientQuantity: ingredientQuantity,
                createdAt: Date()
            )
        }

        enum CodingKeys: String, CodingKey {
            case id
            case dayOfWeek = "day_of_week"
            case mealType = "meal_type"
            case recipeId = "recipe_id"
            case servingsOverride = "servings_override"
            case isEatOut = "is_eat_out"
            case eatOutLocation = "eat_out_location"
            case restaurantId = "restaurant_id"
            case isLeftovers = "is_leftovers"
            case leftoversNote = "leftovers_note"
            case isIngredientOnly = "is_ingredient_only"
            case ingredientName = "ingredient_name"
            case ingredientQuantity = "ingredient_quantity"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case name
        case entries
        case isRotating = "is_rotating"
        case rotationOrder = "rotation_order"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        householdId: UUID,
        name: String,
        entries: [TemplateEntry] = [],
        isRotating: Bool = false,
        rotationOrder: Int? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.householdId = householdId
        self.name = name
        self.entries = entries
        self.isRotating = isRotating
        self.rotationOrder = rotationOrder
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        householdId = try container.decode(UUID.self, forKey: .householdId)
        name = try container.decode(String.self, forKey: .name)
        entries = try container.decodeIfPresent([TemplateEntry].self, forKey: .entries) ?? []
        isRotating = try container.decodeIfPresent(Bool.self, forKey: .isRotating) ?? false
        rotationOrder = try container.decodeIfPresent(Int.self, forKey: .rotationOrder)
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

    /// Get entries for a specific day of the week
    func entries(for dayOfWeek: Int) -> [TemplateEntry] {
        entries.filter { $0.dayOfWeek == dayOfWeek }
    }

    /// Get entries for a specific day and meal type
    func entries(for dayOfWeek: Int, mealType: MealPlanEntry.MealType) -> [TemplateEntry] {
        entries.filter { $0.dayOfWeek == dayOfWeek && $0.mealType == mealType }
    }

    /// Create a template from an existing week of meal plan entries
    static func from(entries: [MealPlanEntry], weekStart: Date, name: String, householdId: UUID) -> MealPlanTemplate {
        let calendar = Calendar.current

        let templateEntries = entries.compactMap { entry -> TemplateEntry? in
            let dayOfWeek = calendar.component(.weekday, from: entry.scheduledDate) - 1  // Convert to 0-indexed
            return TemplateEntry.from(entry, dayOfWeek: dayOfWeek)
        }

        return MealPlanTemplate(
            householdId: householdId,
            name: name,
            entries: templateEntries
        )
    }

    /// Apply this template to a specific week
    func apply(to weekStart: Date, householdId: UUID) -> [MealPlanEntry] {
        let calendar = Calendar.current

        return entries.compactMap { entry -> MealPlanEntry? in
            // Calculate the date for this day of the week
            // weekStart should be Sunday (dayOfWeek 0)
            let weekday = calendar.component(.weekday, from: weekStart) - 1
            let daysToAdd = entry.dayOfWeek - weekday
            guard let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: weekStart) else {
                return nil
            }

            return entry.toMealPlanEntry(for: targetDate, householdId: householdId)
        }
    }
}

/// Rotation schedule that manages multiple templates
struct MealPlanRotation: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    var name: String
    var templateIds: [UUID]  // Ordered list of template IDs in the rotation
    var currentIndex: Int  // Which template is currently active (0-indexed)
    var startDate: Date?  // When the rotation started
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case name
        case templateIds = "template_ids"
        case currentIndex = "current_index"
        case startDate = "start_date"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        householdId: UUID,
        name: String,
        templateIds: [UUID] = [],
        currentIndex: Int = 0,
        startDate: Date? = nil,
        isActive: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.householdId = householdId
        self.name = name
        self.templateIds = templateIds
        self.currentIndex = currentIndex
        self.startDate = startDate
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Get the current template ID in the rotation
    var currentTemplateId: UUID? {
        guard currentIndex >= 0 && currentIndex < templateIds.count else { return nil }
        return templateIds[currentIndex]
    }

    /// Get the next template ID after rotating
    var nextTemplateId: UUID? {
        guard !templateIds.isEmpty else { return nil }
        let nextIndex = (currentIndex + 1) % templateIds.count
        return templateIds[nextIndex]
    }

    /// Advance to the next template in the rotation
    mutating func advance() {
        guard !templateIds.isEmpty else { return }
        currentIndex = (currentIndex + 1) % templateIds.count
    }
}
