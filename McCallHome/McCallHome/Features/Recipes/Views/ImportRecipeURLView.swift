//
//  ImportRecipeURLView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI
import UIKit

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
                HStack {
                    TextField("Recipe URL", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    if UIPasteboard.general.hasStrings || UIPasteboard.general.hasURLs {
                        Button {
                            if let pasted = UIPasteboard.general.string {
                                url = pasted.trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                        } label: {
                            Image(systemName: "doc.on.clipboard")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Paste link")
                    }
                }
            } header: {
                Text("Enter URL")
            } footer: {
                Text("Paste a link from a recipe website or TikTok. We'll extract the recipe details automatically. For TikTok, the recipe needs to be written in the video's caption.")
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
                        await viewModel.scrapeRecipe(from: trimmedURL)
                    }
                } label: {
                    HStack {
                        Spacer()
                        Label("Import Recipe", systemImage: "arrow.down.doc")
                        Spacer()
                    }
                }
                .disabled(!isValidURL)
            }
        }
    }

    private var trimmedURL: String {
        url.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValidURL: Bool {
        guard let components = URLComponents(string: trimmedURL),
              let scheme = components.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = components.host, !host.isEmpty else {
            return false
        }
        return true
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
                            Label("\(Recipe.formatTime(prepTime)) prep", systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let cookTime = scraped.cookTime {
                            Label("\(Recipe.formatTime(cookTime)) cook", systemImage: "flame")
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
                ForEach(Array(scraped.ingredients.enumerated()), id: \.offset) { _, ingredient in
                    Text(formatIngredient(ingredient))
                        .font(.subheadline)
                }
            }

            Section("Instructions (\(scraped.steps.count) steps)") {
                ForEach(scraped.steps, id: \.stepNumber) { step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(step.stepNumber)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        Text(step.instruction)
                            .font(.subheadline)
                    }
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
            parts.append(Self.formatQuantity(quantity))
        }

        if let unit = ingredient.unit, !unit.isEmpty {
            parts.append(unit)
        }

        parts.append(ingredient.name)

        var result = parts.joined(separator: " ")

        if let notes = ingredient.notes, !notes.isEmpty {
            result += ", \(notes)"
        }

        return result
    }

    /// Render scraped quantities the way a cook writes them (1¼, ⅓, 0.4)
    static func formatQuantity(_ quantity: Double) -> String {
        let whole = Int(quantity)
        let fraction = quantity - Double(whole)

        let vulgarFractions: [(value: Double, symbol: String)] = [
            (0.25, "¼"), (0.33, "⅓"), (0.5, "½"), (0.67, "⅔"), (0.75, "¾")
        ]

        if fraction < 0.01 {
            return "\(whole)"
        }

        if let match = vulgarFractions.first(where: { abs($0.value - fraction) < 0.02 }) {
            return whole > 0 ? "\(whole)\(match.symbol)" : match.symbol
        }

        // No clean fraction; show the number with up to two decimals
        return quantity.formatted(.number.precision(.fractionLength(0...2)))
    }
}

#Preview {
    ImportRecipeURLView(viewModel: RecipesViewModel())
}
