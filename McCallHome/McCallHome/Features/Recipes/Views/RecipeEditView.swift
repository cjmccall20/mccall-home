//
//  RecipeEditView.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import SwiftUI

struct RecipeEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: RecipesViewModel

    let recipe: Recipe

    @State private var title: String
    @State private var dishCategory: Recipe.DishCategory
    @State private var mealCategory: Recipe.MealCategory
    @State private var proteinType: Recipe.ProteinType
    @State private var baseServings: Int
    @State private var prepTime: String
    @State private var cookTime: String
    @State private var notes: String
    @State private var ingredients: [Recipe.Ingredient]
    @State private var steps: [Recipe.RecipeStep]
    @State private var isSaving = false

    init(recipe: Recipe, viewModel: RecipesViewModel) {
        self.recipe = recipe
        self.viewModel = viewModel
        _title = State(initialValue: recipe.title)
        _dishCategory = State(initialValue: recipe.dishCategory)
        _mealCategory = State(initialValue: recipe.mealCategory)
        _proteinType = State(initialValue: recipe.proteinType)
        _baseServings = State(initialValue: recipe.baseServings)
        _prepTime = State(initialValue: recipe.prepTime.map { String($0) } ?? "")
        _cookTime = State(initialValue: recipe.cookTime.map { String($0) } ?? "")
        _notes = State(initialValue: recipe.notes ?? "")
        _ingredients = State(initialValue: recipe.ingredients)
        _steps = State(initialValue: recipe.steps)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Title", text: $title)

                    Picker("Dish Type", selection: $dishCategory) {
                        ForEach(Recipe.DishCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }

                    Picker("Meal Time", selection: $mealCategory) {
                        ForEach(Recipe.MealCategory.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: category.iconName).tag(category)
                        }
                    }

                    Picker("Protein", selection: $proteinType) {
                        ForEach(Recipe.ProteinType.allCases, id: \.self) { protein in
                            Text(protein.displayName).tag(protein)
                        }
                    }

                    Stepper("Servings: \(baseServings)", value: $baseServings, in: 1...20)
                }

                Section("Timing") {
                    HStack {
                        Text("Prep Time")
                        Spacer()
                        TextField("min", text: $prepTime)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("min")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Cook Time")
                        Spacer()
                        TextField("min", text: $cookTime)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("min")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    NavigationLink {
                        IngredientsEditView(ingredients: $ingredients)
                    } label: {
                        HStack {
                            Text("Ingredients")
                            Spacer()
                            Text("\(ingredients.count)")
                                .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink {
                        StepsEditView(steps: $steps)
                    } label: {
                        HStack {
                            Text("Instructions")
                            Spacer()
                            Text("\(steps.count) steps")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                } header: {
                    Text("Notes")
                } footer: {
                    Text("Add cooking tips, variations, or personal notes about this recipe.")
                }
            }
            .navigationTitle("Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveRecipe()
                    }
                    .disabled(title.isEmpty || isSaving)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveRecipe() {
        isSaving = true

        var updated = recipe
        updated.title = title
        updated.dishCategory = dishCategory
        updated.mealCategory = mealCategory
        updated.proteinType = proteinType
        updated.baseServings = baseServings
        updated.prepTime = Int(prepTime)
        updated.cookTime = Int(cookTime)
        updated.notes = notes.isEmpty ? nil : notes
        updated.ingredients = ingredients
        updated.steps = steps
        updated.updatedAt = Date()

        Task {
            await viewModel.updateRecipe(updated)
            dismiss()
        }
    }
}

// MARK: - Ingredients Edit View

struct IngredientsEditView: View {
    @Binding var ingredients: [Recipe.Ingredient]
    @State private var showAddIngredient = false

    var body: some View {
        List {
            ForEach($ingredients) { $ingredient in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if let quantity = ingredient.quantity {
                            Text(formatQuantity(quantity))
                                .fontWeight(.medium)
                        }
                        if let unit = ingredient.unit {
                            Text(unit)
                        }
                        Text(ingredient.name)
                    }
                    if let notes = ingredient.notes {
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { indexSet in
                ingredients.remove(atOffsets: indexSet)
            }
            .onMove { from, to in
                ingredients.move(fromOffsets: from, toOffset: to)
            }

            Button {
                showAddIngredient = true
            } label: {
                Label("Add Ingredient", systemImage: "plus")
            }
        }
        .navigationTitle("Ingredients")
        .toolbar {
            EditButton()
        }
        .sheet(isPresented: $showAddIngredient) {
            AddIngredientView { newIngredient in
                ingredients.append(newIngredient)
            }
        }
    }

    private func formatQuantity(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

// MARK: - Add Ingredient View

struct AddIngredientView: View {
    @Environment(\.dismiss) private var dismiss

    let onAdd: (Recipe.Ingredient) -> Void

    @State private var name = ""
    @State private var quantity = ""
    @State private var unit = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    HStack {
                        TextField("Quantity", text: $quantity)
                            .keyboardType(.decimalPad)
                        TextField("Unit", text: $unit)
                            .textInputAutocapitalization(.never)
                    }
                    TextField("Notes (optional)", text: $notes)
                }
            }
            .navigationTitle("Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let ingredient = Recipe.Ingredient(
                            name: name,
                            quantity: Double(quantity),
                            unit: unit.isEmpty ? nil : unit,
                            notes: notes.isEmpty ? nil : notes
                        )
                        onAdd(ingredient)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Steps Edit View

struct StepsEditView: View {
    @Binding var steps: [Recipe.RecipeStep]
    @State private var showAddStep = false

    var body: some View {
        List {
            ForEach($steps.sorted(by: { $0.wrappedValue.stepNumber < $1.wrappedValue.stepNumber })) { $step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(step.stepNumber)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(.blue)
                        .clipShape(Circle())

                    Text(step.instruction)
                }
            }
            .onDelete { indexSet in
                steps.remove(atOffsets: indexSet)
                renumberSteps()
            }
            .onMove { from, to in
                steps.move(fromOffsets: from, toOffset: to)
                renumberSteps()
            }

            Button {
                showAddStep = true
            } label: {
                Label("Add Step", systemImage: "plus")
            }
        }
        .navigationTitle("Instructions")
        .toolbar {
            EditButton()
        }
        .sheet(isPresented: $showAddStep) {
            AddStepView(stepNumber: steps.count + 1) { newStep in
                steps.append(newStep)
            }
        }
    }

    private func renumberSteps() {
        for (index, _) in steps.enumerated() {
            steps[index].stepNumber = index + 1
        }
    }
}

// MARK: - Add Step View

struct AddStepView: View {
    @Environment(\.dismiss) private var dismiss

    let stepNumber: Int
    let onAdd: (Recipe.RecipeStep) -> Void

    @State private var instruction = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Step \(stepNumber)")
                        .font(.headline)
                    TextEditor(text: $instruction)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let step = Recipe.RecipeStep(
                            stepNumber: stepNumber,
                            instruction: instruction
                        )
                        onAdd(step)
                        dismiss()
                    }
                    .disabled(instruction.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    RecipeEditView(
        recipe: Recipe(
            id: UUID(),
            householdId: UUID(),
            title: "Chicken Parmesan",
            sourceUrl: nil,
            sourceType: .manual,
            baseServings: 4,
            ingredients: [
                Recipe.Ingredient(name: "chicken breasts", quantity: 4, unit: nil),
                Recipe.Ingredient(name: "breadcrumbs", quantity: 1, unit: "cup")
            ],
            steps: [
                Recipe.RecipeStep(stepNumber: 1, instruction: "Pound chicken"),
                Recipe.RecipeStep(stepNumber: 2, instruction: "Coat in breadcrumbs")
            ],
            prepTime: 20,
            cookTime: 30,
            notes: "Great with pasta!"
        ),
        viewModel: RecipesViewModel()
    )
}
