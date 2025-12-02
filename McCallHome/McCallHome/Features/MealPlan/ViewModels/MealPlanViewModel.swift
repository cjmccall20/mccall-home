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
    @Published var restaurants: [Restaurant] = []
    @Published var householdMembers: [HouseholdMember] = []
    @Published var isLoading = false
    @Published var error: String?

    private let mealPlanService = MealPlanService.shared
    private let recipeService = RecipeService.shared
    private let restaurantService = RestaurantService.shared
    private let householdMemberService = HouseholdMemberService.shared
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
            async let restaurantsTask = restaurantService.fetchRestaurants(for: householdId)
            async let membersTask = householdMemberService.fetchMembers(for: householdId)

            entries = try await entriesTask
            recipes = try await recipesTask
            restaurants = try await restaurantsTask
            householdMembers = try await membersTask
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // Get restaurant for an entry
    func restaurant(for entry: MealPlanEntry) -> Restaurant? {
        guard let restaurantId = entry.restaurantId else { return nil }
        return restaurants.first { $0.id == restaurantId }
    }

    // Get assigned member for an entry
    func assignedMember(for entry: MealPlanEntry) -> HouseholdMember? {
        guard let assignedTo = entry.assignedTo else { return nil }
        return householdMembers.first { $0.id == assignedTo }
    }

    // Update cooking assignment for an entry
    func updateAssignment(for entry: MealPlanEntry, memberId: UUID?) async {
        do {
            try await mealPlanService.updateAssignment(entryId: entry.id, assignedTo: memberId)
            // Update local state
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[index].assignedTo = memberId
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // Cycle through members for quick assignment (tap to cycle)
    func cycleAssignment(for entry: MealPlanEntry) async {
        let activeMembers = householdMembers.filter { $0.isActive }
        guard !activeMembers.isEmpty else { return }

        let currentIndex = entry.assignedTo.flatMap { assignedId in
            activeMembers.firstIndex { $0.id == assignedId }
        }

        let nextMemberId: UUID?
        if let current = currentIndex {
            // If at last member, go to nil (unassigned)
            if current == activeMembers.count - 1 {
                nextMemberId = nil
            } else {
                nextMemberId = activeMembers[current + 1].id
            }
        } else {
            // Currently unassigned, assign to first member
            nextMemberId = activeMembers.first?.id
        }

        await updateAssignment(for: entry, memberId: nextMemberId)
    }

    // Fetch orders for a specific restaurant
    func fetchOrders(for restaurantId: UUID) async -> [RestaurantOrder] {
        do {
            return try await restaurantService.fetchOrders(for: restaurantId)
        } catch {
            self.error = error.localizedDescription
            return []
        }
    }

    // Get all entries for a specific date
    func entriesForDate(_ date: Date) -> [MealPlanEntry] {
        mealPlanService.entriesForDate(date, in: entries)
    }

    // Get entry for specific date and meal type (returns first if multiple)
    func entry(for date: Date, mealType: MealPlanEntry.MealType) -> MealPlanEntry? {
        mealPlanService.entry(for: date, mealType: mealType, in: entries)
    }

    // Get all entries for a specific date and meal type (supports multiple dishes)
    func entries(for date: Date, mealType: MealPlanEntry.MealType) -> [MealPlanEntry] {
        mealPlanService.entries(for: date, mealType: mealType, in: entries)
    }

    // Get recipe for a specific entry
    func recipe(for entry: MealPlanEntry) -> Recipe? {
        guard let recipeId = entry.recipeId else { return nil }
        return recipes.first(where: { $0.id == recipeId })
    }

    // Legacy: Get first recipe for date (for backward compatibility)
    func recipe(for date: Date) -> Recipe? {
        guard let entry = entriesForDate(date).first,
              let recipeId = entry.recipeId else {
            return nil
        }
        return recipes.first(where: { $0.id == recipeId })
    }

    func assignRecipe(_ recipe: Recipe, to date: Date, mealType: MealPlanEntry.MealType, servings: Int? = nil) async {
        guard let householdId = householdId else { return }

        do {
            try await mealPlanService.assignRecipe(
                recipeId: recipe.id,
                to: date,
                mealType: mealType,
                householdId: householdId,
                servingsOverride: servings
            )
            await fetchMealPlan()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func addEatOut(to date: Date, mealType: MealPlanEntry.MealType, location: String?) async {
        guard let householdId = householdId else { return }

        do {
            try await mealPlanService.addEatOut(
                to: date,
                mealType: mealType,
                location: location,
                householdId: householdId
            )
            await fetchMealPlan()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func addEatOutWithRestaurant(to date: Date, mealType: MealPlanEntry.MealType, restaurantId: UUID, orderIds: [UUID], note: String?) async {
        guard let householdId = householdId else { return }

        do {
            try await mealPlanService.addEatOutWithRestaurant(
                to: date,
                mealType: mealType,
                restaurantId: restaurantId,
                orderIds: orderIds,
                note: note,
                householdId: householdId
            )
            await fetchMealPlan()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func addLeftovers(to date: Date, mealType: MealPlanEntry.MealType, note: String?) async {
        guard let householdId = householdId else { return }

        do {
            try await mealPlanService.addLeftovers(
                to: date,
                mealType: mealType,
                note: note,
                householdId: householdId
            )
            await fetchMealPlan()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func removeFromPlan(entry: MealPlanEntry) async {
        do {
            try await mealPlanService.removeFromPlan(entryId: entry.id)
            await fetchMealPlan()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func removeFromPlan(date: Date, mealType: MealPlanEntry.MealType) async {
        guard let entry = entry(for: date, mealType: mealType) else { return }
        await removeFromPlan(entry: entry)
    }

    func updateServings(for entry: MealPlanEntry, servings: Int?) async {
        do {
            try await mealPlanService.updateServings(entryId: entry.id, servings: servings)
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

    // Get display text for a meal entry
    func displayText(for entry: MealPlanEntry) -> String {
        if entry.isEatOut {
            // If we have a restaurant linked, show its name
            if let restaurant = restaurant(for: entry) {
                return restaurant.name
            }
            // Fall back to location text
            if let location = entry.eatOutLocation, !location.isEmpty {
                return "Eat Out - \(location)"
            }
            return "Eat Out"
        } else if entry.isLeftovers {
            if let note = entry.leftoversNote, !note.isEmpty {
                return "Leftovers - \(note)"
            }
            return "Leftovers"
        } else if let recipe = recipe(for: entry) {
            return recipe.title
        }
        return "Unknown"
    }
}
