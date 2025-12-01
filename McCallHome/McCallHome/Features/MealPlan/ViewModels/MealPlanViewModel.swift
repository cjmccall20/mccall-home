//
//  MealPlanViewModel.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation
import Combine

@MainActor
class MealPlanViewModel: ObservableObject {
    @Published var currentWeekStart: Date
    @Published var entries: [MealPlanEntry] = []
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var error: String?

    private let mealPlanService = MealPlanService.shared
    private let recipeService = RecipeService.shared
    private let authService = AuthService.shared

    var householdId: UUID? {
        authService.currentUser?.householdId
    }

    var weekDays: [Date] {
        (0..<7).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: offset, to: currentWeekStart)
        }
    }

    var weekRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: currentWeekStart)
        let end = formatter.string(from: Calendar.current.date(byAdding: .day, value: 6, to: currentWeekStart) ?? currentWeekStart)
        return "\(start) - \(end)"
    }

    init() {
        currentWeekStart = Calendar.current.startOfWeek(for: Date())
    }

    func fetchMealPlan() async {
        guard let householdId = householdId else { return }

        isLoading = true
        error = nil

        do {
            async let entriesTask = mealPlanService.fetchMealPlan(for: householdId, weekStart: currentWeekStart)
            async let recipesTask = recipeService.fetchRecipes(for: householdId)

            entries = try await entriesTask
            recipes = try await recipesTask
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func recipe(for date: Date) -> Recipe? {
        guard let entry = entries.first(where: { Calendar.current.isDate($0.scheduledDate, inSameDayAs: date) }) else {
            return nil
        }
        return recipes.first(where: { $0.id == entry.recipeId })
    }

    func entry(for date: Date) -> MealPlanEntry? {
        entries.first(where: { Calendar.current.isDate($0.scheduledDate, inSameDayAs: date) })
    }

    func assignRecipe(_ recipe: Recipe, to date: Date) async {
        guard let householdId = householdId else { return }

        do {
            try await mealPlanService.assignRecipe(recipeId: recipe.id, to: date, householdId: householdId)
            await fetchMealPlan()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func removeFromPlan(date: Date) async {
        guard let entry = entry(for: date) else { return }

        do {
            try await mealPlanService.removeFromPlan(entryId: entry.id)
            await fetchMealPlan()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func goToNextWeek() {
        currentWeekStart = currentWeekStart.adding(weeks: 1)
        Task {
            await fetchMealPlan()
        }
    }

    func goToPreviousWeek() {
        currentWeekStart = currentWeekStart.adding(weeks: -1)
        Task {
            await fetchMealPlan()
        }
    }

    func goToCurrentWeek() {
        currentWeekStart = Calendar.current.startOfWeek(for: Date())
        Task {
            await fetchMealPlan()
        }
    }
}
