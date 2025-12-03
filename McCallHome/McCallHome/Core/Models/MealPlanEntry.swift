//
//  MealPlanEntry.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation

struct MealPlanEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    let recipeId: UUID?  // Nullable for eat out/leftovers entries
    var scheduledDate: Date
    var mealType: MealType
    var servingsOverride: Int?
    var isEatOut: Bool
    var eatOutLocation: String?
    var restaurantId: UUID?  // Reference to restaurant for eat-out entries
    var orderIds: [UUID]  // Selected order IDs for this eat-out meal
    var isLeftovers: Bool  // Indicates meal is leftovers from previous cooking
    var leftoversNote: String?  // Optional note about what leftovers
    var isIngredientOnly: Bool  // Standalone ingredient (not a full recipe/dish)
    var ingredientId: UUID?  // Reference to ingredient from ingredients table
    var ingredientName: String?  // Name of ingredient (for display and quick entry)
    var ingredientQuantity: String?  // Quantity needed (e.g., "2 boxes", "1 lb")
    var assignedTo: UUID?  // Household member responsible for cooking this meal
    var hasIngredients: Bool  // User already has ingredients - skip in grocery generation
    var shoppedAt: Date?  // When this meal was shopped for (nil = needs groceries)
    let createdAt: Date

    enum MealType: String, Codable, CaseIterable {
        case breakfast
        case lunch
        case dinner

        var displayName: String {
            rawValue.capitalized
        }

        var sortOrder: Int {
            switch self {
            case .breakfast: return 0
            case .lunch: return 1
            case .dinner: return 2
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case recipeId = "recipe_id"
        case scheduledDate = "date"  // DB column is 'date'
        case mealType = "meal_type"
        case servingsOverride = "servings_override"
        case isEatOut = "is_eat_out"
        case eatOutLocation = "eat_out_location"
        case restaurantId = "restaurant_id"
        case orderIds = "order_ids"
        case isLeftovers = "is_leftovers"
        case leftoversNote = "leftovers_note"
        case isIngredientOnly = "is_ingredient_only"
        case ingredientId = "ingredient_id"
        case ingredientName = "ingredient_name"
        case ingredientQuantity = "ingredient_quantity"
        case assignedTo = "assigned_to"
        case hasIngredients = "has_ingredients"
        case shoppedAt = "shopped_at"
        case createdAt = "created_at"
    }

    init(id: UUID, householdId: UUID, recipeId: UUID?, scheduledDate: Date, mealType: MealType = .dinner, servingsOverride: Int? = nil, isEatOut: Bool = false, eatOutLocation: String? = nil, restaurantId: UUID? = nil, orderIds: [UUID] = [], isLeftovers: Bool = false, leftoversNote: String? = nil, isIngredientOnly: Bool = false, ingredientId: UUID? = nil, ingredientName: String? = nil, ingredientQuantity: String? = nil, assignedTo: UUID? = nil, hasIngredients: Bool = false, shoppedAt: Date? = nil, createdAt: Date) {
        self.id = id
        self.householdId = householdId
        self.recipeId = recipeId
        self.scheduledDate = scheduledDate
        self.mealType = mealType
        self.servingsOverride = servingsOverride
        self.isEatOut = isEatOut
        self.eatOutLocation = eatOutLocation
        self.restaurantId = restaurantId
        self.orderIds = orderIds
        self.isLeftovers = isLeftovers
        self.leftoversNote = leftoversNote
        self.isIngredientOnly = isIngredientOnly
        self.ingredientId = ingredientId
        self.ingredientName = ingredientName
        self.ingredientQuantity = ingredientQuantity
        self.assignedTo = assignedTo
        self.hasIngredients = hasIngredients
        self.shoppedAt = shoppedAt
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        householdId = try container.decode(UUID.self, forKey: .householdId)
        recipeId = try container.decodeIfPresent(UUID.self, forKey: .recipeId)

        // Handle date - could be ISO8601 full format or just date string
        // IMPORTANT: Use local timezone and set to noon to avoid off-by-one errors
        if let dateString = try? container.decode(String.self, forKey: .scheduledDate) {
            if let date = ISO8601DateFormatter().date(from: dateString) {
                // Set to noon local time to avoid timezone edge cases
                scheduledDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
            } else if let date = Self.dateOnlyFormatter.date(from: dateString) {
                // Set to noon local time to avoid timezone edge cases
                scheduledDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .scheduledDate, in: container, debugDescription: "Invalid date format: \(dateString)")
            }
        } else {
            scheduledDate = try container.decode(Date.self, forKey: .scheduledDate)
        }

        // Handle meal type with default
        mealType = try container.decodeIfPresent(MealType.self, forKey: .mealType) ?? .dinner

        servingsOverride = try container.decodeIfPresent(Int.self, forKey: .servingsOverride)
        isEatOut = try container.decodeIfPresent(Bool.self, forKey: .isEatOut) ?? false
        eatOutLocation = try container.decodeIfPresent(String.self, forKey: .eatOutLocation)
        restaurantId = try container.decodeIfPresent(UUID.self, forKey: .restaurantId)
        orderIds = try container.decodeIfPresent([UUID].self, forKey: .orderIds) ?? []
        isLeftovers = try container.decodeIfPresent(Bool.self, forKey: .isLeftovers) ?? false
        leftoversNote = try container.decodeIfPresent(String.self, forKey: .leftoversNote)
        isIngredientOnly = try container.decodeIfPresent(Bool.self, forKey: .isIngredientOnly) ?? false
        ingredientId = try container.decodeIfPresent(UUID.self, forKey: .ingredientId)
        ingredientName = try container.decodeIfPresent(String.self, forKey: .ingredientName)
        ingredientQuantity = try container.decodeIfPresent(String.self, forKey: .ingredientQuantity)
        assignedTo = try container.decodeIfPresent(UUID.self, forKey: .assignedTo)
        hasIngredients = try container.decodeIfPresent(Bool.self, forKey: .hasIngredients) ?? false

        // Handle shoppedAt date - ISO8601 timestamp
        if let dateString = try? container.decode(String.self, forKey: .shoppedAt) {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                shoppedAt = date
            } else {
                shoppedAt = ISO8601DateFormatter().date(from: dateString)
            }
        } else {
            shoppedAt = try container.decodeIfPresent(Date.self, forKey: .shoppedAt)
        }

        // Handle createdAt date - may have fractional seconds
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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(householdId, forKey: .householdId)
        try container.encodeIfPresent(recipeId, forKey: .recipeId)

        // Encode date as date-only string for Supabase DATE column
        // Use local timezone to ensure the correct date is saved
        let normalizedDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: scheduledDate) ?? scheduledDate
        try container.encode(Self.dateOnlyFormatter.string(from: normalizedDate), forKey: .scheduledDate)

        try container.encode(mealType, forKey: .mealType)
        try container.encodeIfPresent(servingsOverride, forKey: .servingsOverride)
        try container.encode(isEatOut, forKey: .isEatOut)
        try container.encodeIfPresent(eatOutLocation, forKey: .eatOutLocation)
        try container.encodeIfPresent(restaurantId, forKey: .restaurantId)
        try container.encode(orderIds, forKey: .orderIds)
        try container.encode(isLeftovers, forKey: .isLeftovers)
        try container.encodeIfPresent(leftoversNote, forKey: .leftoversNote)
        try container.encode(isIngredientOnly, forKey: .isIngredientOnly)
        try container.encodeIfPresent(ingredientId, forKey: .ingredientId)
        try container.encodeIfPresent(ingredientName, forKey: .ingredientName)
        try container.encodeIfPresent(ingredientQuantity, forKey: .ingredientQuantity)
        try container.encodeIfPresent(assignedTo, forKey: .assignedTo)
        try container.encode(hasIngredients, forKey: .hasIngredients)
        if let shoppedAt = shoppedAt {
            try container.encode(ISO8601DateFormatter().string(from: shoppedAt), forKey: .shoppedAt)
        }
        try container.encode(ISO8601DateFormatter().string(from: createdAt), forKey: .createdAt)
    }

    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        // Use local timezone to avoid off-by-one date errors
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    // MARK: - Computed Properties

    /// Whether this entry needs grocery shopping (not yet shopped for and not marked as having ingredients)
    var needsGroceries: Bool {
        // Skip eat out, leftovers, and entries already marked as having ingredients
        if isEatOut || isLeftovers || hasIngredients {
            return false
        }
        // If shopped_at is set, they've already shopped for this
        return shoppedAt == nil
    }

    /// Whether this entry has been shopped for
    var hasBeenShoppedFor: Bool {
        shoppedAt != nil || hasIngredients
    }
}
