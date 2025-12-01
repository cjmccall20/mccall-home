//
//  RecipeListView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct RecipeListView: View {
    @StateObject private var viewModel = RecipesViewModel()
    @State private var showCreateRecipe = false

    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    if viewModel.isLoading && viewModel.recipes.isEmpty {
                        ProgressView("Loading recipes...")
                    } else if viewModel.filteredRecipes.isEmpty {
                        ContentUnavailableView(
                            "No Recipes",
                            systemImage: "book",
                            description: Text("Tap + to add your first recipe")
                        )
                    } else {
                        recipeList
                    }
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showCreateRecipe = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Recipes")
            .searchable(text: $viewModel.searchText, prompt: "Search recipes")
            .refreshable {
                await viewModel.fetchRecipes()
            }
            .task {
                await viewModel.fetchRecipes()
            }
            .sheet(isPresented: $showCreateRecipe) {
                CreateRecipeView(viewModel: viewModel)
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
        }
    }

    private var recipeList: some View {
        List {
            ForEach(viewModel.filteredRecipes) { recipe in
                NavigationLink {
                    RecipeDetailView(recipe: recipe, viewModel: viewModel)
                } label: {
                    RecipeRowView(recipe: recipe)
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let recipe = viewModel.filteredRecipes[index]
                    Task {
                        await viewModel.deleteRecipe(recipe)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    RecipeListView()
}
