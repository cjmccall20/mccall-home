//
//  IngredientsViewModel.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import Foundation
import Combine

@MainActor
class IngredientsViewModel: ObservableObject {
    @Published var ingredients: [IngredientPreference] = []
    @Published var isLoading = false
    @Published var error: String?

    private let service = IngredientPreferenceService.shared
    private let authService = AuthService.shared

    var householdId: UUID? {
        authService.currentUser?.householdId
    }

    func fetchIngredients() async {
        guard let householdId = householdId else { return }

        isLoading = true
        error = nil

        do {
            ingredients = try await service.fetchAllPreferences(for: householdId)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func updateIngredient(_ ingredient: IngredientPreference) async {
        do {
            try await service.updatePreference(ingredient)
            // Update local state
            if let index = ingredients.firstIndex(where: { $0.id == ingredient.id }) {
                ingredients[index] = ingredient
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteIngredient(_ ingredient: IngredientPreference) async {
        do {
            try await service.deletePreference(ingredient.id)
            ingredients.removeAll { $0.id == ingredient.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
