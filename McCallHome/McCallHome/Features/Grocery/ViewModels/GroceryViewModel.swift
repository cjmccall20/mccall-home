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

    private let groceryService = GroceryService.shared
    private let mealPlanService = MealPlanService.shared
    private let recipeService = RecipeService.shared
    private let ingredientPreferenceService = IngredientPreferenceService.shared
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

            let entries = try await entriesTask
            let recipes = try await recipesTask
            let staples = try await staplesTask

            // Use smart generation with Claude
            groceryList = try await groceryService.generateSmartGroceryList(
                mealPlanEntries: entries,
                recipes: recipes,
                pantryStaples: staples,
                householdId: householdId,
                preserveManualItems: true,
                dateRange: (rangeStart, rangeEnd)
            )

            await fetchCurrentList()
        } catch {
            self.error = error.localizedDescription
        }

        isGenerating = false
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
}
