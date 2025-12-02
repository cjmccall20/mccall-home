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
    @State private var showImportURL = false

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

                // FAB with menu
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Menu {
                            Button {
                                showCreateRecipe = true
                            } label: {
                                Label("Create Manually", systemImage: "square.and.pencil")
                            }

                            Button {
                                showImportURL = true
                            } label: {
                                Label("Import from URL", systemImage: "link")
                            }
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    proteinFilterMenu
                }
            }
            .refreshable {
                await viewModel.fetchRecipes()
            }
            .task {
                await viewModel.fetchRecipes()
            }
            .sheet(isPresented: $showCreateRecipe) {
                CreateRecipeView(viewModel: viewModel)
            }
            .sheet(isPresented: $showImportURL) {
                ImportRecipeURLView(viewModel: viewModel)
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

    private var proteinFilterMenu: some View {
        Menu {
            Button {
                viewModel.setProteinFilter(nil)
            } label: {
                HStack {
                    Text("All Proteins")
                    if viewModel.selectedProteinFilter == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Divider()

            ForEach(Recipe.ProteinType.allCases, id: \.self) { protein in
                Button {
                    viewModel.setProteinFilter(protein)
                } label: {
                    HStack {
                        Text(protein.displayName)
                        if viewModel.selectedProteinFilter == protein {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: viewModel.selectedProteinFilter != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }

    private var recipeList: some View {
        List {
            ForEach(viewModel.groupedByProtein, id: \.protein) { group in
                Section(group.protein.displayName) {
                    ForEach(group.recipes) { recipe in
                        NavigationLink {
                            RecipeDetailView(recipe: recipe, viewModel: viewModel)
                        } label: {
                            RecipeRowView(recipe: recipe)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let recipe = group.recipes[index]
                            Task {
                                await viewModel.deleteRecipe(recipe)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    RecipeListView()
}
