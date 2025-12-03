//
//  GroceryService.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation
import Supabase

@MainActor
class GroceryService {
    static let shared = GroceryService()
    private init() {}

    func fetchCurrentList(for householdId: UUID) async throws -> (GroceryList?, [GroceryItem]) {
        let lists: [GroceryList] = try await supabase
            .from("grocery_lists")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .eq("is_current", value: true)
            .limit(1)
            .execute()
            .value

        guard let list = lists.first else {
            return (nil, [])
        }

        let items: [GroceryItem] = try await supabase
            .from("grocery_items")
            .select()
            .eq("grocery_list_id", value: list.id.uuidString)
            .order("sort_order", ascending: true)
            .execute()
            .value

        return (list, items)
    }

    // MARK: - Smart Grocery List Generation

    struct SmartGroceryItem: Codable {
        let name: String
        let quantity: Double?
        let unit: String?
        let category: String
        let isPantryCheck: Bool
        let notes: String?

        enum CodingKeys: String, CodingKey {
            case name
            case quantity
            case unit
            case category
            case isPantryCheck = "is_pantry_check"
            case notes
        }
    }

    struct SmartGroceryResponse: Codable {
        let success: Bool
        let groceryList: SmartGroceryList?
        let error: String?

        enum CodingKeys: String, CodingKey {
            case success
            case groceryList = "grocery_list"
            case error
        }
    }

    struct SmartGroceryList: Codable {
        let items: [SmartGroceryItem]
    }

    /// Generate a smart grocery list using Claude AI
    func generateSmartGroceryList(
        mealPlanEntries: [MealPlanEntry],
        recipes: [Recipe],
        pantryStaples: [PantryStaple],
        householdId: UUID,
        preserveManualItems: Bool = true,
        preserveCheckedItems: Bool = true,
        dateRange: (start: Date, end: Date)? = nil
    ) async throws -> GroceryList {
        // Get current list's items to preserve (manual items and checked items)
        var manualItemsToPreserve: [GroceryItem] = []
        var checkedItemsToPreserve: [GroceryItem] = []

        let (existingList, existingItems) = try await fetchCurrentList(for: householdId)
        if existingList != nil {
            if preserveManualItems {
                manualItemsToPreserve = existingItems.filter { $0.source == .manual || $0.source == .staple }
            }
            if preserveCheckedItems {
                // Preserve checked meal plan items (already purchased)
                checkedItemsToPreserve = existingItems.filter { $0.isChecked && $0.source == .mealPlan }
            }
        }

        // Create a set of already-purchased item names for deduplication
        let checkedItemNames = Set(checkedItemsToPreserve.map { $0.name.lowercased() })

        // Build recipe entries for the API
        var recipeEntries: [[String: Any]] = []
        for entry in mealPlanEntries where !entry.isEatOut && !entry.isLeftovers {
            guard let recipeId = entry.recipeId,
                  let recipe = recipes.first(where: { $0.id == recipeId }) else { continue }

            let servings = entry.servingsOverride ?? recipe.baseServings

            let ingredients: [[String: Any]] = recipe.ingredients.map { ing in
                var dict: [String: Any] = ["name": ing.name]
                if let qty = ing.quantity { dict["quantity"] = qty }
                if let unit = ing.unit { dict["unit"] = unit }
                if let notes = ing.notes { dict["notes"] = notes }
                return dict
            }

            recipeEntries.append([
                "title": recipe.title,
                "servings": servings,
                "ingredients": ingredients
            ])
        }

        // If no recipes, fall back to regular generation
        if recipeEntries.isEmpty {
            return try await generateFromMealPlan(
                mealPlanEntries: mealPlanEntries,
                recipes: recipes,
                householdId: householdId,
                preserveManualItems: preserveManualItems,
                dateRange: dateRange
            )
        }

        // Build pantry staples list
        let staplesData: [[String: String]] = pantryStaples.map { staple in
            ["name": staple.name, "category": "pantry"]
        }

        // Call the Edge Function
        let functionUrl = Config.supabaseURL.appendingPathComponent("functions/v1/generate-grocery-list")

        var request = URLRequest(url: functionUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")

        let body: [String: Any] = [
            "recipes": recipeEntries,
            "pantry_staples": staplesData
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("🛒 Calling smart grocery list generator...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(responseString)")
            }
            throw GroceryError.smartGenerationFailed
        }

        let smartResponse = try JSONDecoder().decode(SmartGroceryResponse.self, from: data)

        guard smartResponse.success, let smartList = smartResponse.groceryList else {
            throw GroceryError.smartGenerationFailed
        }

        print("✅ Generated \(smartList.items.count) smart grocery items")

        // Create the grocery list in the database
        return try await createListFromSmartItems(
            smartList.items,
            householdId: householdId,
            manualItemsToPreserve: manualItemsToPreserve,
            checkedItemsToPreserve: checkedItemsToPreserve,
            checkedItemNames: checkedItemNames,
            dateRange: dateRange
        )
    }

    private func createListFromSmartItems(
        _ items: [SmartGroceryItem],
        householdId: UUID,
        manualItemsToPreserve: [GroceryItem],
        checkedItemsToPreserve: [GroceryItem] = [],
        checkedItemNames: Set<String> = [],
        dateRange: (start: Date, end: Date)?
    ) async throws -> GroceryList {
        // Mark any existing current list as not current
        let existingLists: [GroceryList] = try await supabase
            .from("grocery_lists")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .eq("is_current", value: true)
            .execute()
            .value

        for list in existingLists {
            try await supabase
                .from("grocery_lists")
                .update(["is_current": false])
                .eq("id", value: list.id.uuidString)
                .execute()
        }

        // Create new grocery list
        let listStartDate = dateRange?.start ?? Calendar.current.startOfWeek(for: Date())
        let newList = GroceryList(
            id: UUID(),
            householdId: householdId,
            weekStart: listStartDate,
            isCurrent: true,
            mealPlanHash: nil,
            generatedAt: Date()
        )

        try await supabase
            .from("grocery_lists")
            .insert(newList)
            .execute()

        var sortOrder = 0

        // First, add back the checked/purchased items (at the top)
        for item in checkedItemsToPreserve {
            let newItem = GroceryItem(
                id: UUID(),
                groceryListId: newList.id,
                name: item.name,
                quantity: item.quantity,
                unit: item.unit,
                category: item.category,
                isChecked: true,  // Keep them checked
                sortOrder: sortOrder,
                source: item.source,
                fromRecipeId: item.fromRecipeId,
                createdAt: Date()
            )

            try await supabase
                .from("grocery_items")
                .insert(newItem)
                .execute()

            sortOrder += 1
        }

        // Create grocery items from smart list (skipping already-purchased items)
        for smartItem in items {
            // Skip items that were already purchased
            if checkedItemNames.contains(smartItem.name.lowercased()) {
                continue
            }

            let category = mapCategory(smartItem.category)
            let item = GroceryItem(
                id: UUID(),
                groceryListId: newList.id,
                name: smartItem.name,
                quantity: smartItem.quantity,
                unit: smartItem.unit,
                category: smartItem.isPantryCheck ? .verifyPantry : category,
                isChecked: false,
                sortOrder: sortOrder,
                source: .mealPlan,
                fromRecipeId: nil,
                createdAt: Date()
            )

            try await supabase
                .from("grocery_items")
                .insert(item)
                .execute()

            sortOrder += 1
        }

        // Re-add preserved manual items
        for item in manualItemsToPreserve {
            let newItem = GroceryItem(
                id: UUID(),
                groceryListId: newList.id,
                name: item.name,
                quantity: item.quantity,
                unit: item.unit,
                category: item.category,
                isChecked: item.isChecked,
                sortOrder: sortOrder,
                source: item.source,
                fromRecipeId: nil,
                createdAt: Date()
            )

            try await supabase
                .from("grocery_items")
                .insert(newItem)
                .execute()

            sortOrder += 1
        }

        return newList
    }

    private func mapCategory(_ categoryString: String) -> GroceryItem.Category {
        switch categoryString.lowercased() {
        case "produce": return .produce
        case "dairy": return .dairy
        case "meat": return .meat
        case "bakery": return .bakery
        case "pantry": return .pantry
        case "frozen": return .frozen
        case "beverages": return .beverages
        default: return .other
        }
    }

    enum GroceryError: LocalizedError {
        case smartGenerationFailed

        var errorDescription: String? {
            switch self {
            case .smartGenerationFailed:
                return "Failed to generate smart grocery list"
            }
        }
    }

    // MARK: - Legacy Generation (fallback)

    func generateFromMealPlan(mealPlanEntries: [MealPlanEntry], recipes: [Recipe], householdId: UUID, preserveManualItems: Bool = true, dateRange: (start: Date, end: Date)? = nil) async throws -> GroceryList {
        // Get current list's manual items if we need to preserve them
        var manualItemsToPreserve: [GroceryItem] = []

        if preserveManualItems {
            let (existingList, existingItems) = try await fetchCurrentList(for: householdId)
            if existingList != nil {
                manualItemsToPreserve = existingItems.filter { $0.source == .manual || $0.source == .staple }
            }
        }

        // Mark any existing current list as not current
        let existingLists: [GroceryList] = try await supabase
            .from("grocery_lists")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .eq("is_current", value: true)
            .execute()
            .value

        for list in existingLists {
            try await supabase
                .from("grocery_lists")
                .update(["is_current": false])
                .eq("id", value: list.id.uuidString)
                .execute()
        }

        // Create new grocery list using provided date range or current week
        let listStartDate = dateRange?.start ?? Calendar.current.startOfWeek(for: Date())
        let newList = GroceryList(
            id: UUID(),
            householdId: householdId,
            weekStart: listStartDate,
            isCurrent: true,
            mealPlanHash: nil,
            generatedAt: Date()
        )

        try await supabase
            .from("grocery_lists")
            .insert(newList)
            .execute()

        // Aggregate ingredients from all recipes in the meal plan (only entries with recipes)
        var ingredientMap: [String: (quantity: Double?, unit: String?, category: GroceryItem.Category, recipeId: UUID?)] = [:]

        for entry in mealPlanEntries where !entry.isEatOut && !entry.isLeftovers {
            guard let recipeId = entry.recipeId,
                  let recipe = recipes.first(where: { $0.id == recipeId }) else { continue }

            let servingMultiplier = entry.servingsOverride != nil
                ? Double(entry.servingsOverride!) / Double(recipe.baseServings)
                : 1.0

            for ingredient in recipe.ingredients {
                let key = ingredient.name.lowercased()
                let adjustedQuantity = ingredient.quantity.map { $0 * servingMultiplier }

                if let existing = ingredientMap[key] {
                    // Combine quantities if same unit
                    if existing.unit == ingredient.unit, let existingQty = existing.quantity, let newQty = adjustedQuantity {
                        ingredientMap[key] = (existingQty + newQty, existing.unit, existing.category, existing.recipeId)
                    }
                } else {
                    ingredientMap[key] = (adjustedQuantity, ingredient.unit, categorize(ingredient.name), recipeId)
                }
            }
        }

        // Create grocery items from meal plan
        var sortOrder = 0
        for (name, info) in ingredientMap.sorted(by: { $0.value.category.sortOrder < $1.value.category.sortOrder }) {
            let item = GroceryItem(
                id: UUID(),
                groceryListId: newList.id,
                name: name.capitalized,
                quantity: info.quantity,
                unit: info.unit,
                category: info.category,
                isChecked: false,
                sortOrder: sortOrder,
                source: .mealPlan,
                fromRecipeId: info.recipeId,
                createdAt: Date()
            )

            try await supabase
                .from("grocery_items")
                .insert(item)
                .execute()

            sortOrder += 1
        }

        // Re-add preserved manual items
        for item in manualItemsToPreserve {
            let newItem = GroceryItem(
                id: UUID(),
                groceryListId: newList.id,
                name: item.name,
                quantity: item.quantity,
                unit: item.unit,
                category: item.category,
                isChecked: item.isChecked,
                sortOrder: sortOrder,
                source: item.source,
                fromRecipeId: nil,
                createdAt: Date()
            )

            try await supabase
                .from("grocery_items")
                .insert(newItem)
                .execute()

            sortOrder += 1
        }

        return newList
    }

    func toggleItem(_ item: GroceryItem) async throws {
        try await supabase
            .from("grocery_items")
            .update(["is_checked": !item.isChecked])
            .eq("id", value: item.id.uuidString)
            .execute()
    }

    func addManualItem(name: String, category: GroceryItem.Category, to listId: UUID, householdId: UUID) async throws {
        let items: [GroceryItem] = try await supabase
            .from("grocery_items")
            .select()
            .eq("grocery_list_id", value: listId.uuidString)
            .order("sort_order", ascending: false)
            .limit(1)
            .execute()
            .value

        let maxSortOrder = items.first?.sortOrder ?? 0

        let item = GroceryItem(
            id: UUID(),
            groceryListId: listId,
            name: name,
            quantity: nil,
            unit: nil,
            category: category,
            isChecked: false,
            sortOrder: maxSortOrder + 1,
            source: .manual,
            fromRecipeId: nil,
            createdAt: Date()
        )

        try await supabase
            .from("grocery_items")
            .insert(item)
            .execute()

        // Track in previous items for quick re-add
        try await trackPreviousItem(name: name, category: category, householdId: householdId)
    }

    func deleteItem(_ item: GroceryItem) async throws {
        try await supabase
            .from("grocery_items")
            .delete()
            .eq("id", value: item.id.uuidString)
            .execute()
    }

    func updateItemQuantity(_ item: GroceryItem, quantity: Double?, unit: String?) async throws {
        struct ItemUpdate: Encodable {
            let quantity: Double?
            let unit: String?
        }

        try await supabase
            .from("grocery_items")
            .update(ItemUpdate(quantity: quantity, unit: unit))
            .eq("id", value: item.id.uuidString)
            .execute()
    }

    func updateItemName(_ item: GroceryItem, name: String) async throws {
        struct ItemUpdate: Encodable {
            let name: String
        }

        try await supabase
            .from("grocery_items")
            .update(ItemUpdate(name: name))
            .eq("id", value: item.id.uuidString)
            .execute()
    }

    func clearCheckedItems(from listId: UUID) async throws {
        try await supabase
            .from("grocery_items")
            .delete()
            .eq("grocery_list_id", value: listId.uuidString)
            .eq("is_checked", value: true)
            .execute()
    }

    func clearAllItems(from listId: UUID) async throws {
        try await supabase
            .from("grocery_items")
            .delete()
            .eq("grocery_list_id", value: listId.uuidString)
            .execute()
    }

    // MARK: - List Completion

    /// Complete the grocery list and mark it as no longer current
    func completeList(_ list: GroceryList) async throws {
        struct ListCompletion: Encodable {
            let is_completed: Bool
            let completed_at: String
            let is_current: Bool
        }

        try await supabase
            .from("grocery_lists")
            .update(ListCompletion(
                is_completed: true,
                completed_at: ISO8601DateFormatter().string(from: Date()),
                is_current: false
            ))
            .eq("id", value: list.id.uuidString)
            .execute()
    }

    /// Fetch recent completed lists for history (limited to last 3)
    func fetchRecentCompletedLists(for householdId: UUID, limit: Int = 3) async throws -> [GroceryList] {
        let lists: [GroceryList] = try await supabase
            .from("grocery_lists")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .eq("is_completed", value: true)
            .order("completed_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        return lists
    }

    /// Fetch items for a specific list (for viewing history)
    func fetchItems(for listId: UUID) async throws -> [GroceryItem] {
        let items: [GroceryItem] = try await supabase
            .from("grocery_items")
            .select()
            .eq("grocery_list_id", value: listId.uuidString)
            .order("sort_order", ascending: true)
            .execute()
            .value
        return items
    }

    // MARK: - Smart Merge

    /// Check if the current list has any checked items (mid-shopping)
    func hasCheckedItems(for householdId: UUID) async throws -> Bool {
        let (_, items) = try await fetchCurrentList(for: householdId)
        return items.contains { $0.isChecked }
    }

    /// Get checked items from the current list (for smart merge)
    func getCheckedItems(for householdId: UUID) async throws -> [GroceryItem] {
        let (_, items) = try await fetchCurrentList(for: householdId)
        return items.filter { $0.isChecked }
    }

    // MARK: - House Staples

    func addHouseStapleItem(name: String, quantity: String?, category: GroceryItem.Category, to listId: UUID) async throws {
        // Get current max sort order
        let items: [GroceryItem] = try await supabase
            .from("grocery_items")
            .select()
            .eq("grocery_list_id", value: listId.uuidString)
            .order("sort_order", ascending: false)
            .limit(1)
            .execute()
            .value

        let maxSortOrder = items.first?.sortOrder ?? 0

        // Parse quantity string into number and unit
        let (qty, unit) = parseQuantityString(quantity)

        let item = GroceryItem(
            id: UUID(),
            groceryListId: listId,
            name: name,
            quantity: qty,
            unit: unit,
            category: category,
            isChecked: false,
            sortOrder: maxSortOrder + 1,
            source: .staple,
            fromRecipeId: nil,
            createdAt: Date()
        )

        try await supabase
            .from("grocery_items")
            .insert(item)
            .execute()
    }

    private func parseQuantityString(_ quantityStr: String?) -> (Double?, String?) {
        guard let str = quantityStr, !str.isEmpty else { return (nil, nil) }

        // Try to extract number and unit from string like "2 boxes", "1 lb", "3"
        let components = str.components(separatedBy: CharacterSet.whitespaces)
        guard let firstComponent = components.first else { return (nil, str) }

        if let number = Double(firstComponent) {
            let unit = components.dropFirst().joined(separator: " ")
            return (number, unit.isEmpty ? nil : unit)
        } else {
            // No leading number, treat whole string as unit/description
            return (nil, str)
        }
    }

    // MARK: - Pantry Staples

    func fetchPantryStaples(for householdId: UUID) async throws -> [PantryStaple] {
        let response: [PantryStaple] = try await supabase
            .from("pantry_staples")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .order("name", ascending: true)
            .execute()
            .value
        return response
    }

    // MARK: - Previous Items

    func fetchPreviousItems(for householdId: UUID, limit: Int = 50) async throws -> [PreviousGroceryItem] {
        let items: [PreviousGroceryItem] = try await supabase
            .from("previous_grocery_items")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .order("times_used", ascending: false)
            .order("last_used_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        return items
    }

    func searchPreviousItems(query: String, householdId: UUID) async throws -> [PreviousGroceryItem] {
        let items: [PreviousGroceryItem] = try await supabase
            .from("previous_grocery_items")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .ilike("name", pattern: "%\(query)%")
            .order("times_used", ascending: false)
            .limit(20)
            .execute()
            .value
        return items
    }

    private func trackPreviousItem(name: String, category: GroceryItem.Category, householdId: UUID) async throws {
        // Check if item already exists
        let existing: [PreviousGroceryItem] = try await supabase
            .from("previous_grocery_items")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .ilike("name", pattern: name)
            .limit(1)
            .execute()
            .value

        if let item = existing.first {
            // Update existing
            struct PreviousItemUpdate: Encodable {
                let times_used: Int
                let last_used_at: String
            }
            try await supabase
                .from("previous_grocery_items")
                .update(PreviousItemUpdate(
                    times_used: item.timesUsed + 1,
                    last_used_at: ISO8601DateFormatter().string(from: Date())
                ))
                .eq("id", value: item.id.uuidString)
                .execute()
        } else {
            // Create new
            let newItem = PreviousGroceryItem(
                householdId: householdId,
                name: name,
                category: category
            )
            try await supabase
                .from("previous_grocery_items")
                .insert(newItem)
                .execute()
        }
    }

    func addFromPreviousItem(_ previousItem: PreviousGroceryItem, to listId: UUID) async throws {
        try await addManualItem(
            name: previousItem.name,
            category: previousItem.category,
            to: listId,
            householdId: previousItem.householdId
        )
    }

    // MARK: - Categorization

    private func categorize(_ ingredientName: String) -> GroceryItem.Category {
        let name = ingredientName.lowercased()

        let produceKeywords = ["apple", "banana", "lettuce", "tomato", "onion", "garlic", "pepper", "carrot", "celery", "potato", "lemon", "lime", "orange", "spinach", "kale", "broccoli", "cucumber", "zucchini", "mushroom", "avocado", "cilantro", "parsley", "basil", "ginger", "scallion", "green onion", "jalapeño", "jalapeno", "cabbage", "asparagus", "corn", "peas", "beans", "squash", "eggplant"]
        let dairyKeywords = ["milk", "cheese", "yogurt", "butter", "cream", "egg", "sour cream", "cottage", "ricotta", "mozzarella", "parmesan", "cheddar", "half and half", "whipping cream"]
        let meatKeywords = ["chicken", "beef", "pork", "fish", "salmon", "shrimp", "turkey", "bacon", "sausage", "ground", "steak", "lamb", "ham", "prosciutto", "chorizo", "tilapia", "cod", "tuna", "crab", "lobster", "scallop"]
        let bakeryKeywords = ["bread", "roll", "bun", "bagel", "croissant", "tortilla", "pita", "naan", "baguette"]
        let frozenKeywords = ["frozen", "ice cream"]
        let beverageKeywords = ["juice", "soda", "water", "coffee", "tea", "wine", "beer", "sparkling"]
        let pantryKeywords = ["flour", "sugar", "salt", "oil", "vinegar", "sauce", "pasta", "rice", "beans", "broth", "stock", "spice", "seasoning", "honey", "maple", "syrup", "ketchup", "mustard", "mayo", "mayonnaise", "soy sauce", "olive oil", "vegetable oil", "canola", "coconut", "canned", "dried"]

        if produceKeywords.contains(where: { name.contains($0) }) {
            return .produce
        } else if dairyKeywords.contains(where: { name.contains($0) }) {
            return .dairy
        } else if meatKeywords.contains(where: { name.contains($0) }) {
            return .meat
        } else if bakeryKeywords.contains(where: { name.contains($0) }) {
            return .bakery
        } else if frozenKeywords.contains(where: { name.contains($0) }) {
            return .frozen
        } else if beverageKeywords.contains(where: { name.contains($0) }) {
            return .beverages
        } else if pantryKeywords.contains(where: { name.contains($0) }) {
            return .pantry
        }

        return .other
    }
}
