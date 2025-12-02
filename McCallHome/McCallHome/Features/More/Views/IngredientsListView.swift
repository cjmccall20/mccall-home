//
//  IngredientsListView.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import SwiftUI

struct IngredientsListView: View {
    @StateObject private var viewModel = IngredientsViewModel()
    @State private var searchText = ""

    var filteredIngredients: [IngredientPreference] {
        if searchText.isEmpty {
            return viewModel.ingredients
        }
        return viewModel.ingredients.filter {
            $0.canonicalName.localizedCaseInsensitiveContains(searchText) ||
            ($0.displayName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    // Group by first letter
    var groupedIngredients: [(letter: String, ingredients: [IngredientPreference])] {
        let grouped = Dictionary(grouping: filteredIngredients) { ingredient in
            String(ingredient.canonicalName.prefix(1)).uppercased()
        }
        return grouped.sorted { $0.key < $1.key }.map { (letter: $0.key, ingredients: $0.value) }
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.ingredients.isEmpty {
                ProgressView("Loading ingredients...")
            } else if viewModel.ingredients.isEmpty {
                ContentUnavailableView(
                    "No Ingredients Yet",
                    systemImage: "carrot",
                    description: Text("Ingredients will appear here as you use recipes. You can then customize brands, stores, and preferences.")
                )
            } else if filteredIngredients.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                ingredientList
            }
        }
        .navigationTitle("Ingredients")
        .searchable(text: $searchText, prompt: "Search ingredients")
        .task {
            await viewModel.fetchIngredients()
        }
        .refreshable {
            await viewModel.fetchIngredients()
        }
    }

    private var ingredientList: some View {
        List {
            // Summary stats
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(viewModel.ingredients.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Total Ingredients")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .leading) {
                        Text("\(viewModel.ingredients.filter { $0.displayName != nil }.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                        Text("Customized")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .leading) {
                        Text("\(viewModel.ingredients.filter { $0.isInPerson }.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                        Text("In-Person")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            // Ingredients by letter
            ForEach(groupedIngredients, id: \.letter) { group in
                Section(group.letter) {
                    ForEach(group.ingredients) { ingredient in
                        NavigationLink {
                            IngredientDetailView(ingredient: ingredient, viewModel: viewModel)
                        } label: {
                            IngredientRowView(ingredient: ingredient)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Ingredient Row View

struct IngredientRowView: View {
    let ingredient: IngredientPreference

    var body: some View {
        HStack(spacing: 12) {
            // Store icon or generic icon
            if let store = ingredient.preferredStore {
                StoreIconView(store: store, size: 28)
            } else {
                Image(systemName: "basket")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 28)
            }

            VStack(alignment: .leading, spacing: 2) {
                // Display name (if customized) or canonical name
                if let displayName = ingredient.displayName {
                    Text(displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(ingredient.canonicalName.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(ingredient.canonicalName.capitalized)
                        .font(.subheadline)
                }
            }

            Spacer()

            // In-person indicator
            if ingredient.isInPerson {
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }
}

#Preview {
    NavigationStack {
        IngredientsListView()
    }
}
