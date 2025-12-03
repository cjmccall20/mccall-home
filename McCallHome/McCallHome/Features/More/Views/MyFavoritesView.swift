//
//  MyFavoritesView.swift
//  McCallHome
//
//  Created by Claude on 12/3/25.
//

import SwiftUI

struct MyFavoritesView: View {
    @StateObject private var viewModel = RecipesViewModel()

    var favoriteRecipes: [Recipe] {
        guard let memberId = viewModel.currentMemberId else { return [] }
        let favoriteIds = Set(viewModel.ratings.filter { $0.memberId == memberId && $0.isFavorite }.map { $0.recipeId })
        return viewModel.recipes.filter { favoriteIds.contains($0.id) }
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.recipes.isEmpty {
                ProgressView("Loading favorites...")
            } else if favoriteRecipes.isEmpty {
                ContentUnavailableView(
                    "No Favorites Yet",
                    systemImage: "heart",
                    description: Text("Recipes you favorite will appear here. Tap the heart icon on any recipe to add it to your favorites.")
                )
            } else {
                recipeList
            }
        }
        .navigationTitle("My Favorites")
        .task {
            await viewModel.fetchRecipes()
        }
        .refreshable {
            await viewModel.fetchRecipes()
        }
    }

    private var recipeList: some View {
        List {
            ForEach(favoriteRecipes) { recipe in
                NavigationLink {
                    RecipeDetailView(recipe: recipe, viewModel: viewModel)
                } label: {
                    RecipeRowView(
                        recipe: recipe,
                        isFavorite: true,
                        aggregate: viewModel.getAggregate(for: recipe.id)
                    )
                }
                .swipeActions(edge: .leading) {
                    if let memberId = viewModel.currentMemberId {
                        Button {
                            Task {
                                await viewModel.toggleFavorite(recipeId: recipe.id, memberId: memberId)
                            }
                        } label: {
                            Label("Unfavorite", systemImage: "heart.slash")
                        }
                        .tint(.pink)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    NavigationStack {
        MyFavoritesView()
    }
}
