//
//  GroceryViewModel.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation
import Combine

@MainActor
class GroceryViewModel: ObservableObject {
    @Published var groceryList: GroceryList?
    @Published var items: [GroceryItem] = []
    @Published var previousItems: [PreviousGroceryItem] = []
    @Published var ingredientPreferences: [IngredientPreference] = []
    @Published var isLoading = false
    @Published var isGenerating = false
    @Published var error: String?

    // Date range for grocery generation
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var useCustomDateRange = false

    let groceryService = GroceryService.shared
    private let mealPlanService = MealPlanService.shared
    private let recipeService = RecipeService.shared
    private let ingredientPreferenceService = IngredientPreferenceService.shared
    private let houseStapleService = HouseStapleService.shared
    private let authService = AuthService.shared

    init() {
        // Default to current week
        let weekStart = Calendar.current.startOfWeek(for: Date())
        let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? Date()
        self.startDate = weekStart
        self.endDate = weekEnd
    }

    var householdId: UUID? {
        authService.currentUser?.householdId
    }

    // Group items by source first, then by category
    var groupedBySource: [(source: GroceryItem.Source, categories: [(category: GroceryItem.Category, items: [GroceryItem])])] {
        var result: [(source: GroceryItem.Source, categories: [(category: GroceryItem.Category, items: [GroceryItem])])] = []

        for source in [GroceryItem.Source.mealPlan, .staple, .manual] {
            let sourceItems = items.filter { $0.source == source }
            if sourceItems.isEmpty { continue }

            let grouped = Dictionary(grouping: sourceItems, by: { $0.category })
            let categories = GroceryItem.Category.allCases.compactMap { category -> (category: GroceryItem.Category, items: [GroceryItem])? in
                guard let items = grouped[category], !items.isEmpty else { return nil }
                return (category: category, items: items.sorted { $0.sortOrder < $1.sortOrder })
            }

            if !categories.isEmpty {
                result.append((source: source, categories: categories))
            }
        }

        return result
    }

    // Traditional grouping by category only
    var groupedItems: [(category: GroceryItem.Category, items: [GroceryItem])] {
        let grouped = Dictionary(grouping: items, by: { $0.category })
        return GroceryItem.Category.allCases
            .compactMap { category in
                guard let items = grouped[category], !items.isEmpty else { return nil }
                return (category: category, items: items.sorted { $0.sortOrder < $1.sortOrder })
            }
    }

    var mealPlanItems: [GroceryItem] {
        items.filter { $0.source == .mealPlan }
    }

    var manualItems: [GroceryItem] {
        items.filter { $0.source == .manual }
    }

    var stapleItems: [GroceryItem] {
        items.filter { $0.source == .staple }
    }

    var checkedCount: Int {
        items.filter { $0.isChecked }.count
    }

    var totalCount: Int {
        items.count
    }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(checkedCount) / Double(totalCount)
    }

    var uncheckedCount: Int {
        items.filter { !$0.isChecked }.count
    }

    func fetchCurrentList() async {
        guard let householdId = householdId else { return }

        isLoading = true
        error = nil

        do {
            async let listTask = groceryService.fetchCurrentList(for: householdId)
            async let preferencesTask = ingredientPreferenceService.fetchAllPreferences(for: householdId)

            let (list, fetchedItems) = try await listTask
            ingredientPreferences = try await preferencesTask

            groceryList = list
            items = fetchedItems

            // Ensure ingredient preferences exist for all items (for future customization)
            let itemNames = fetchedItems.map { $0.name }
            try await ingredientPreferenceService.ensurePreferencesExist(for: itemNames, householdId: householdId)

            // Refresh preferences after ensuring they exist
            ingredientPreferences = try await ingredientPreferenceService.fetchAllPreferences(for: householdId)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func fetchPreviousItems() async {
        guard let householdId = householdId else { return }

        do {
            previousItems = try await groceryService.fetchPreviousItems(for: householdId)
        } catch {
            // Silent fail - previous items are a convenience feature
            print("Failed to fetch previous items: \(error)")
        }
    }

    func generateFromMealPlan() async {
        guard let householdId = householdId else { return }

        isGenerating = true
        error = nil

        do {
            // Use custom date range if enabled, otherwise use current week
            let rangeStart: Date
            let rangeEnd: Date

            if useCustomDateRange {
                rangeStart = startDate
                rangeEnd = endDate
            } else {
                rangeStart = Calendar.current.startOfWeek(for: Date())
                rangeEnd = Calendar.current.date(byAdding: .day, value: 6, to: rangeStart) ?? Date()
            }

            // Fetch all data needed for smart generation
            async let entriesTask = mealPlanService.fetchMealPlanForDateRange(
                for: householdId,
                startDate: rangeStart,
                endDate: rangeEnd
            )
            async let recipesTask = recipeService.fetchRecipes(for: householdId)
            async let staplesTask = groceryService.fetchPantryStaples(for: householdId)
            async let houseStaplesTask = houseStapleService.fetchActiveStaples(for: householdId)

            let entries = try await entriesTask
            let recipes = try await recipesTask
            let staples = try await staplesTask
            let houseStaples = try await houseStaplesTask

            // Use smart generation with Claude
            groceryList = try await groceryService.generateSmartGroceryList(
                mealPlanEntries: entries,
                recipes: recipes,
                pantryStaples: staples,
                householdId: householdId,
                preserveManualItems: true,
                dateRange: (rangeStart, rangeEnd)
            )

            // Fetch the newly created list items to check for existing staples
            await fetchCurrentList()

            // Add house staples to the grocery list (only if not already present)
            if let listId = groceryList?.id {
                // Get names of existing staple items (case-insensitive)
                let existingStapleNames = Set(items.filter { $0.source == .staple }.map { $0.name.lowercased() })

                for houseStaple in houseStaples {
                    // Skip if this staple already exists in the list
                    if existingStapleNames.contains(houseStaple.name.lowercased()) {
                        continue
                    }

                    try await groceryService.addHouseStapleItem(
                        name: houseStaple.name,
                        quantity: houseStaple.quantity,
                        category: mapHouseStapleCategory(houseStaple.category),
                        to: listId
                    )
                }
            }

            // Refresh again to get any newly added staples
            await fetchCurrentList()
        } catch {
            self.error = error.localizedDescription
        }

        isGenerating = false
    }

    private func mapHouseStapleCategory(_ category: String) -> GroceryItem.Category {
        switch category.lowercased() {
        case "produce": return .produce
        case "dairy": return .dairy
        case "meat & seafood", "meat": return .meat
        case "bakery": return .bakery
        case "frozen": return .frozen
        case "beverages": return .beverages
        case "pantry": return .pantry
        default: return .other
        }
    }

    var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    func resetToCurrentWeek() {
        let weekStart = Calendar.current.startOfWeek(for: Date())
        let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? Date()
        startDate = weekStart
        endDate = weekEnd
        useCustomDateRange = false
    }

    func toggleItem(_ item: GroceryItem) async {
        do {
            try await groceryService.toggleItem(item)
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index].isChecked.toggle()
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func addManualItem(name: String, category: GroceryItem.Category) async {
        guard let listId = groceryList?.id,
              let householdId = householdId else { return }

        do {
            try await groceryService.addManualItem(name: name, category: category, to: listId, householdId: householdId)
            await fetchCurrentList()
            await fetchPreviousItems()  // Refresh previous items since we just added one
        } catch {
            self.error = error.localizedDescription
        }
    }

    func addFromPreviousItem(_ previousItem: PreviousGroceryItem) async {
        guard let listId = groceryList?.id else { return }

        do {
            try await groceryService.addFromPreviousItem(previousItem, to: listId)
            await fetchCurrentList()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteItem(_ item: GroceryItem) async {
        do {
            try await groceryService.deleteItem(item)
            items.removeAll { $0.id == item.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateItem(_ item: GroceryItem, itemUpdate: GroceryItemUpdate, preferenceUpdate: IngredientPreferenceUpdate?) async {
        do {
            // Update the item quantity/unit in the grocery list
            try await groceryService.updateItemQuantity(item, quantity: itemUpdate.quantity, unit: itemUpdate.unit)

            // Update local state
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index].quantity = itemUpdate.quantity
                items[index].unit = itemUpdate.unit
            }

            // Update ingredient preference if provided
            if let prefUpdate = preferenceUpdate {
                guard let householdId = householdId else { return }

                // Find or create the preference
                if let existingPref = ingredientPreferenceService.findMatchingPreference(for: item.name, in: ingredientPreferences) {
                    // Update existing preference
                    var updated = existingPref
                    updated.displayName = prefUpdate.displayName
                    updated.brand = prefUpdate.brand
                    updated.preferredStore = prefUpdate.preferredStore
                    updated.isInPerson = prefUpdate.isInPerson
                    updated.isHouseStaple = prefUpdate.isHouseStaple
                    updated.isPantryStaple = prefUpdate.isPantryStaple
                    updated.isOrganic = prefUpdate.isOrganic
                    updated.labels = prefUpdate.labels
                    updated.customLabels = prefUpdate.customLabels
                    updated.notes = prefUpdate.notes
                    try await ingredientPreferenceService.updatePreference(updated)

                    // Update local state
                    if let index = ingredientPreferences.firstIndex(where: { $0.id == existingPref.id }) {
                        ingredientPreferences[index] = updated
                    }
                } else {
                    // Create new preference
                    let normalizedName = ingredientPreferenceService.normalizeIngredientName(item.name)
                    let newPref = IngredientPreference(
                        householdId: householdId,
                        canonicalName: normalizedName,
                        displayName: prefUpdate.displayName,
                        brand: prefUpdate.brand,
                        preferredStore: prefUpdate.preferredStore,
                        isInPerson: prefUpdate.isInPerson,
                        isHouseStaple: prefUpdate.isHouseStaple,
                        isPantryStaple: prefUpdate.isPantryStaple,
                        isOrganic: prefUpdate.isOrganic,
                        labels: prefUpdate.labels,
                        customLabels: prefUpdate.customLabels,
                        notes: prefUpdate.notes
                    )
                    try await ingredientPreferenceService.createPreference(newPref)
                    ingredientPreferences.append(newPref)
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Substitute an ingredient with a different one
    func substituteItem(_ item: GroceryItem, with newName: String) async {
        do {
            try await groceryService.updateItemName(item, name: newName)

            // Update local state
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index].name = newName
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func clearCheckedItems() async {
        guard let listId = groceryList?.id else { return }

        do {
            try await groceryService.clearCheckedItems(from: listId)
            items.removeAll { $0.isChecked }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func clearAllItems() async {
        guard let listId = groceryList?.id else { return }

        do {
            try await groceryService.clearAllItems(from: listId)
            items.removeAll()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func searchPreviousItems(query: String) async -> [PreviousGroceryItem] {
        guard let householdId = householdId else { return [] }

        do {
            return try await groceryService.searchPreviousItems(query: query, householdId: householdId)
        } catch {
            return []
        }
    }

    // MARK: - Staples Management

    /// Remove all staple items from the current list
    func removeAllStaples() async {
        guard groceryList != nil else { return }

        do {
            let staplesToRemove = items.filter { $0.source == .staple }
            for item in staplesToRemove {
                try await groceryService.deleteItem(item)
            }
            items.removeAll { $0.source == .staple }
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Add all house staples to the current list
    func addAllStaples() async {
        guard let listId = groceryList?.id, let householdId = householdId else { return }

        do {
            let houseStaples = try await houseStapleService.fetchActiveStaples(for: householdId)

            // Get names of existing items (any source) to avoid duplicates
            let existingNames = Set(items.map { $0.name.lowercased() })

            for houseStaple in houseStaples {
                // Skip if this item already exists in the list
                if existingNames.contains(houseStaple.name.lowercased()) {
                    continue
                }

                try await groceryService.addHouseStapleItem(
                    name: houseStaple.name,
                    quantity: houseStaple.quantity,
                    category: mapHouseStapleCategory(houseStaple.category),
                    to: listId
                )
            }

            await fetchCurrentList()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Empty List Creation

    /// Create an empty grocery list (without generating from meal plan)
    func createEmptyList(weekStart: Date) async {
        guard let householdId = householdId else { return }

        isGenerating = true
        error = nil

        do {
            groceryList = try await groceryService.createEmptyList(householdId: householdId, weekStart: weekStart)
            await fetchCurrentList()
        } catch {
            self.error = error.localizedDescription
        }

        isGenerating = false
    }

    // MARK: - Week Helpers

    var thisWeekDateRange: (start: Date, end: Date) {
        let weekStart = Calendar.current.startOfWeek(for: Date())
        let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? Date()
        return (weekStart, weekEnd)
    }

    var nextWeekDateRange: (start: Date, end: Date) {
        let thisWeekStart = Calendar.current.startOfWeek(for: Date())
        let nextWeekStart = Calendar.current.date(byAdding: .day, value: 7, to: thisWeekStart) ?? Date()
        let nextWeekEnd = Calendar.current.date(byAdding: .day, value: 6, to: nextWeekStart) ?? Date()
        return (nextWeekStart, nextWeekEnd)
    }

    func formatDateRange(_ range: (start: Date, end: Date)) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: range.start)) - \(formatter.string(from: range.end))"
    }

    func generateForDateRange(_ range: (start: Date, end: Date)) async {
        startDate = range.start
        endDate = range.end
        useCustomDateRange = true
        await generateFromMealPlan()
    }

    // MARK: - List Completion

    /// Complete the current shopping session
    func completeShopping() async {
        guard let list = groceryList, let householdId = householdId else { return }

        do {
            // Mark the grocery list as completed
            try await groceryService.completeList(list)

            // Mark all meals in the date range as shopped
            let startDate = list.dateRangeStart ?? list.weekStart
            let endDate = list.dateRangeEnd ?? Calendar.current.date(byAdding: .day, value: 6, to: startDate) ?? Date()

            try await mealPlanService.markMealsAsShoppedFor(
                householdId: householdId,
                startDate: startDate,
                endDate: endDate
            )

            // Clear local state
            groceryList = nil
            items = []
        } catch {
            self.error = error.localizedDescription
        }
    }
}
