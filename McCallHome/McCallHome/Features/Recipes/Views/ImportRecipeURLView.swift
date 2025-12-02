//
//  ImportRecipeURLView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct ImportRecipeURLView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: RecipesViewModel

    @State private var url = ""
    @State private var selectedDishCategory: Recipe.DishCategory = .entree
    @State private var selectedProtein: Recipe.ProteinType = .other

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isScraping {
                    scrapingView
                } else if let scraped = viewModel.scrapedRecipe {
                    previewView(scraped)
                } else {
                    inputView
                }
            }
            .navigationTitle("Import Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        viewModel.clearScrapedRecipe()
                        dismiss()
                    }
                }
            }
        }
    }

    private var inputView: some View {
        Form {
            Section {
                TextField("Recipe URL", text: $url)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            } header: {
                Text("Enter URL")
            } footer: {
                Text("Paste a URL from a recipe website. We'll try to extract the recipe details automatically.")
            }

            if let error = viewModel.scraperError {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            Section {
                Button {
                    Task {
                        await viewModel.scrapeRecipe(from: url)
                    }
                } label: {
                    HStack {
                        Spacer()
                        Label("Import Recipe", systemImage: "arrow.down.doc")
                        Spacer()
                    }
                }
                .disabled(url.isEmpty || !url.contains("http"))
            }
        }
    }

    private var scrapingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Importing recipe...")
                .font(.headline)

            Text("This may take a few seconds")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func previewView(_ scraped: RecipeService.ScrapedRecipeData) -> some View {
        Form {
            Section("Recipe Found") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(scraped.title)
                        .font(.headline)

                    HStack(spacing: 16) {
                        if let prepTime = scraped.prepTime {
                            Label("\(prepTime)m prep", systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let cookTime = scraped.cookTime {
                            Label("\(cookTime)m cook", systemImage: "flame")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Label("\(scraped.baseServings) servings", systemImage: "person.2")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Ingredients (\(scraped.ingredients.count))") {
                ForEach(scraped.ingredients.prefix(5), id: \.name) { ingredient in
                    Text(formatIngredient(ingredient))
                        .font(.caption)
                }
                if scraped.ingredients.count > 5 {
                    Text("... and \(scraped.ingredients.count - 5) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Instructions (\(scraped.steps.count) steps)") {
                ForEach(scraped.steps.prefix(3), id: \.stepNumber) { step in
                    Text(step.instruction)
                        .font(.caption)
                        .lineLimit(2)
                }
                if scraped.steps.count > 3 {
                    Text("... and \(scraped.steps.count - 3) more steps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Dish Category") {
                Picker("Select dish category", selection: $selectedDishCategory) {
                    ForEach(Recipe.DishCategory.allCases, id: \.self) { category in
                        Label(category.displayName, systemImage: category.iconName).tag(category)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Protein Type") {
                Picker("Select protein type", selection: $selectedProtein) {
                    ForEach(Recipe.ProteinType.allCases, id: \.self) { protein in
                        Text(protein.displayName).tag(protein)
                    }
                }
                .pickerStyle(.menu)
            }

            Section {
                Button {
                    Task {
                        if await viewModel.createRecipeFromScraped(dishCategory: selectedDishCategory, proteinType: selectedProtein) != nil {
                            dismiss()
                        }
                    }
                } label: {
                    HStack {
                        Spacer()
                        Label("Save Recipe", systemImage: "checkmark.circle")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }

                Button(role: .destructive) {
                    viewModel.clearScrapedRecipe()
                } label: {
                    HStack {
                        Spacer()
                        Text("Try Different URL")
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            // Pre-populate from scraped data if available
            if let scrapedCategory = scraped.dishCategory,
               let category = Recipe.DishCategory(rawValue: scrapedCategory) {
                selectedDishCategory = category
            }
            if let scrapedProtein = scraped.proteinType,
               let protein = Recipe.ProteinType(rawValue: scrapedProtein) {
                selectedProtein = protein
            }
        }
    }

    private func formatIngredient(_ ingredient: RecipeService.ScrapedRecipeData.ScrapedIngredient) -> String {
        var parts: [String] = []

        if let quantity = ingredient.quantity {
            let formatted = quantity.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", quantity)
                : String(format: "%.1f", quantity)
            parts.append(formatted)
        }

        if let unit = ingredient.unit, !unit.isEmpty {
            parts.append(unit)
        }

        parts.append(ingredient.name)

        return parts.joined(separator: " ")
    }
}

#Preview {
    ImportRecipeURLView(viewModel: RecipesViewModel())
}
