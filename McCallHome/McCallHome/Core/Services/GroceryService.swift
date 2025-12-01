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

    func generateFromMealPlan(mealPlanEntries: [MealPlanEntry], recipes: [Recipe], householdId: UUID) async throws -> GroceryList {
        // Mark any existing current list as not current
        let existingLists: [GroceryList] = try await supabase
            .from("grocery_lists")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .eq("is_current", value: true)
            .execute()
            .value

        for var list in existingLists {
            list.isCurrent = false
            try await supabase
                .from("grocery_lists")
                .update(["is_current": false])
                .eq("id", value: list.id.uuidString)
                .execute()
        }

        // Create new grocery list
        let weekStart = Calendar.current.startOfWeek(for: Date())
        let newList = GroceryList(
            id: UUID(),
            householdId: householdId,
            weekStart: weekStart,
            isCurrent: true,
            mealPlanHash: nil,
            generatedAt: Date()
        )

        try await supabase
            .from("grocery_lists")
            .insert(newList)
            .execute()

        // Aggregate ingredients from all recipes in the meal plan
        var ingredientMap: [String: (quantity: Double?, unit: String?, category: GroceryItem.Category)] = [:]

        for entry in mealPlanEntries {
            guard let recipe = recipes.first(where: { $0.id == entry.recipeId }) else { continue }

            let servingMultiplier = entry.servingsOverride != nil
                ? Double(entry.servingsOverride!) / Double(recipe.baseServings)
                : 1.0

            for ingredient in recipe.ingredients {
                let key = ingredient.name.lowercased()
                let adjustedQuantity = ingredient.quantity.map { $0 * servingMultiplier }

                if let existing = ingredientMap[key] {
                    // Combine quantities if same unit
                    if existing.unit == ingredient.unit, let existingQty = existing.quantity, let newQty = adjustedQuantity {
                        ingredientMap[key] = (existingQty + newQty, existing.unit, existing.category)
                    }
                } else {
                    ingredientMap[key] = (adjustedQuantity, ingredient.unit, categorize(ingredient.name))
                }
            }
        }

        // Create grocery items
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
                createdAt: Date()
            )

            try await supabase
                .from("grocery_items")
                .insert(item)
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

    func addManualItem(name: String, category: GroceryItem.Category, to listId: UUID) async throws {
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
            createdAt: Date()
        )

        try await supabase
            .from("grocery_items")
            .insert(item)
            .execute()
    }

    func deleteItem(_ item: GroceryItem) async throws {
        try await supabase
            .from("grocery_items")
            .delete()
            .eq("id", value: item.id.uuidString)
            .execute()
    }

    private func categorize(_ ingredientName: String) -> GroceryItem.Category {
        let name = ingredientName.lowercased()

        let produceKeywords = ["apple", "banana", "lettuce", "tomato", "onion", "garlic", "pepper", "carrot", "celery", "potato", "lemon", "lime", "orange", "spinach", "kale", "broccoli", "cucumber", "zucchini", "mushroom", "avocado", "cilantro", "parsley", "basil", "ginger", "scallion", "green onion"]
        let dairyKeywords = ["milk", "cheese", "yogurt", "butter", "cream", "egg", "sour cream"]
        let meatKeywords = ["chicken", "beef", "pork", "fish", "salmon", "shrimp", "turkey", "bacon", "sausage", "ground"]
        let frozenKeywords = ["frozen", "ice cream"]
        let pantryKeywords = ["flour", "sugar", "salt", "oil", "vinegar", "sauce", "pasta", "rice", "beans", "broth", "stock", "spice", "seasoning", "honey", "maple"]

        if produceKeywords.contains(where: { name.contains($0) }) {
            return .produce
        } else if dairyKeywords.contains(where: { name.contains($0) }) {
            return .dairy
        } else if meatKeywords.contains(where: { name.contains($0) }) {
            return .meat
        } else if frozenKeywords.contains(where: { name.contains($0) }) {
            return .frozen
        } else if pantryKeywords.contains(where: { name.contains($0) }) {
            return .pantry
        }

        return .other
    }
}
