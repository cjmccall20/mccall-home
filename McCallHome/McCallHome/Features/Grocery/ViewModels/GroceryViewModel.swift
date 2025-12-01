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
    @Published var isLoading = false
    @Published var isGenerating = false
    @Published var error: String?

    private let groceryService = GroceryService.shared
    private let mealPlanService = MealPlanService.shared
    private let recipeService = RecipeService.shared
    private let authService = AuthService.shared

    var householdId: UUID? {
        authService.currentUser?.householdId
    }

    var groupedItems: [(category: GroceryItem.Category, items: [GroceryItem])] {
        let grouped = Dictionary(grouping: items, by: { $0.category })
        return GroceryItem.Category.allCases
            .compactMap { category in
                guard let items = grouped[category], !items.isEmpty else { return nil }
                return (category: category, items: items.sorted { $0.sortOrder < $1.sortOrder })
            }
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

    func fetchCurrentList() async {
        guard let householdId = householdId else { return }

        isLoading = true
        error = nil

        do {
            let (list, fetchedItems) = try await groceryService.fetchCurrentList(for: householdId)
            groceryList = list
            items = fetchedItems
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func generateFromMealPlan() async {
        guard let householdId = householdId else { return }

        isGenerating = true
        error = nil

        do {
            let weekStart = Calendar.current.startOfWeek(for: Date())
            let entries = try await mealPlanService.fetchMealPlan(for: householdId, weekStart: weekStart)
            let recipes = try await recipeService.fetchRecipes(for: householdId)

            groceryList = try await groceryService.generateFromMealPlan(
                mealPlanEntries: entries,
                recipes: recipes,
                householdId: householdId
            )

            await fetchCurrentList()
        } catch {
            self.error = error.localizedDescription
        }

        isGenerating = false
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
        guard let listId = groceryList?.id else { return }

        do {
            try await groceryService.addManualItem(name: name, category: category, to: listId)
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
}
