//
//  CreateRecipeView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct CreateRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: RecipesViewModel

    @State private var currentStep = 0
    @State private var title = ""
    @State private var sourceUrl = ""
    @State private var baseServings = 4
    @State private var prepTime = ""
    @State private var cookTime = ""
    @State private var tags = ""
    @State private var notes = ""
    @State private var dishCategory: Recipe.DishCategory = .entree
    @State private var mealCategory: Recipe.MealCategory = .dinner
    @State private var proteinType: Recipe.ProteinType = .other

    @State private var ingredients: [Recipe.Ingredient] = []
    @State private var newIngredientName = ""
    @State private var newIngredientQuantity = ""
    @State private var newIngredientUnit = ""

    @State private var steps: [Recipe.RecipeStep] = []
    @State private var newStepInstruction = ""

    var body: some View {
        NavigationStack {
            TabView(selection: $currentStep) {
                // Step 1: Basic Info
                basicInfoStep
                    .tag(0)

                // Step 2: Ingredients
                ingredientsStep
                    .tag(1)

                // Step 3: Instructions
                instructionsStep
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if currentStep < 2 {
                        Button("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .disabled(currentStep == 0 && title.isEmpty)
                    } else {
                        Button("Save") {
                            saveRecipe()
                        }
                        .fontWeight(.semibold)
                        .disabled(title.isEmpty)
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        ForEach(0..<3) { step in
                            Circle()
                                .fill(step == currentStep ? .blue : .secondary.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
        }
    }

    private var stepTitle: String {
        switch currentStep {
        case 0: return "Basic Info"
        case 1: return "Ingredients"
        case 2: return "Instructions"
        default: return "New Recipe"
        }
    }

    private var basicInfoStep: some View {
        Form {
            Section("Recipe Details") {
                TextField("Recipe Title", text: $title)

                TextField("Source URL (optional)", text: $sourceUrl)
                    .keyboardType(.URL)
                    .autocapitalization(.none)

                Stepper("Servings: \(baseServings)", value: $baseServings, in: 1...20)

                Picker("Dish Type", selection: $dishCategory) {
                    ForEach(Recipe.DishCategory.allCases, id: \.self) { category in
                        Label(category.displayName, systemImage: category.iconName).tag(category)
                    }
                }

                Picker("Meal Time", selection: $mealCategory) {
                    ForEach(Recipe.MealCategory.allCases, id: \.self) { category in
                        Label(category.displayName, systemImage: category.iconName).tag(category)
                    }
                }

                Picker("Protein Type", selection: $proteinType) {
                    ForEach(Recipe.ProteinType.allCases, id: \.self) { protein in
                        Text(protein.displayName).tag(protein)
                    }
                }
            }

            Section("Time") {
                TextField("Prep Time (minutes)", text: $prepTime)
                    .keyboardType(.numberPad)

                TextField("Cook Time (minutes)", text: $cookTime)
                    .keyboardType(.numberPad)
            }

            Section("Tags") {
                TextField("Tags (comma separated)", text: $tags)
                Text("e.g., Italian, Quick, Vegetarian")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Notes") {
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
    }

    private var ingredientsStep: some View {
        Form {
            Section("Add Ingredient") {
                TextField("Ingredient name", text: $newIngredientName)

                HStack {
                    TextField("Qty", text: $newIngredientQuantity)
                        .keyboardType(.decimalPad)
                        .frame(width: 60)

                    TextField("Unit (optional)", text: $newIngredientUnit)
                }

                Button("Add Ingredient") {
                    addIngredient()
                }
                .disabled(newIngredientName.isEmpty)
            }

            if !ingredients.isEmpty {
                Section("Ingredients (\(ingredients.count))") {
                    ForEach(ingredients) { ingredient in
                        HStack {
                            if let qty = ingredient.quantity {
                                Text(formatQuantity(qty))
                                    .fontWeight(.medium)
                            }
                            if let unit = ingredient.unit {
                                Text(unit)
                            }
                            Text(ingredient.name)
                        }
                    }
                    .onDelete { indexSet in
                        ingredients.remove(atOffsets: indexSet)
                    }
                }
            }
        }
    }

    private var instructionsStep: some View {
        Form {
            Section("Add Step") {
                TextField("Instruction", text: $newStepInstruction, axis: .vertical)
                    .lineLimit(2...4)

                Button("Add Step") {
                    addStep()
                }
                .disabled(newStepInstruction.isEmpty)
            }

            if !steps.isEmpty {
                Section("Steps (\(steps.count))") {
                    ForEach(steps) { step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(step.stepNumber)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(.blue)
                                .clipShape(Circle())

                            Text(step.instruction)
                                .font(.body)
                        }
                    }
                    .onDelete { indexSet in
                        steps.remove(atOffsets: indexSet)
                        renumberSteps()
                    }
                }
            }
        }
    }

    private func addIngredient() {
        let quantity = Double(newIngredientQuantity)
        let unit = newIngredientUnit.isEmpty ? nil : newIngredientUnit

        let ingredient = Recipe.Ingredient(
            name: newIngredientName,
            quantity: quantity,
            unit: unit
        )

        ingredients.append(ingredient)
        newIngredientName = ""
        newIngredientQuantity = ""
        newIngredientUnit = ""
    }

    private func addStep() {
        let step = Recipe.RecipeStep(
            stepNumber: steps.count + 1,
            instruction: newStepInstruction
        )

        steps.append(step)
        newStepInstruction = ""
    }

    private func renumberSteps() {
        for i in steps.indices {
            steps[i] = Recipe.RecipeStep(
                id: steps[i].id,
                stepNumber: i + 1,
                instruction: steps[i].instruction
            )
        }
    }

    private func saveRecipe() {
        guard let householdId = viewModel.householdId else { return }

        let parsedTags = tags.isEmpty ? nil : tags.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }

        let recipe = Recipe(
            id: UUID(),
            householdId: householdId,
            title: title,
            sourceUrl: sourceUrl.isEmpty ? nil : sourceUrl,
            sourceType: sourceUrl.isEmpty ? .manual : .url,
            dishCategory: dishCategory,
            mealCategory: mealCategory,
            proteinType: proteinType,
            baseServings: baseServings,
            ingredients: ingredients,
            steps: steps,
            tags: parsedTags,
            prepTime: Int(prepTime),
            cookTime: Int(cookTime),
            notes: notes.isEmpty ? nil : notes,
            createdAt: Date(),
            updatedAt: Date()
        )

        Task {
            await viewModel.createRecipe(recipe)
            dismiss()
        }
    }

    private func formatQuantity(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}

#Preview {
    CreateRecipeView(viewModel: RecipesViewModel())
}
