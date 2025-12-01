//
//  RecipesViewModel.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation
import Combine

@MainActor
class RecipesViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var error: String?

    private let recipeService = RecipeService.shared
    private let authService = AuthService.shared

    var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return recipes
        }
        return recipes.filter { recipe in
            recipe.title.localizedCaseInsensitiveContains(searchText) ||
            (recipe.tags?.contains { $0.localizedCaseInsensitiveContains(searchText) } ?? false)
        }
    }

    var householdId: UUID? {
        authService.currentUser?.householdId
    }

    func fetchRecipes() async {
        guard let householdId = householdId else { return }

        isLoading = true
        error = nil

        do {
            recipes = try await recipeService.fetchRecipes(for: householdId)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func createRecipe(_ recipe: Recipe) async {
        do {
            try await recipeService.createRecipe(recipe)
            await fetchRecipes()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateRecipe(_ recipe: Recipe) async {
        do {
            try await recipeService.updateRecipe(recipe)
            await fetchRecipes()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteRecipe(_ recipe: Recipe) async {
        do {
            try await recipeService.deleteRecipe(recipe)
            await fetchRecipes()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
