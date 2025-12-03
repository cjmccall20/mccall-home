//
//  RecipeDetailView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct RecipeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: RecipesViewModel

    let recipe: Recipe

    @State private var servings: Int
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false
    @State private var showNotesEditor = false
    @State private var editableNotes: String = ""

    init(recipe: Recipe, viewModel: RecipesViewModel) {
        self.recipe = recipe
        self.viewModel = viewModel
        _servings = State(initialValue: recipe.baseServings)
    }

    var servingMultiplier: Double {
        Double(servings) / Double(recipe.baseServings)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    HStack(spacing: 16) {
                        if let prepTime = recipe.formattedPrepTime {
                            Label(prepTime, systemImage: "clock")
                        }
                        if let cookTime = recipe.formattedCookTime {
                            Label(cookTime, systemImage: "flame")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    if let tags = recipe.tags, !tags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                Divider()

                // Serving Adjuster
                VStack(alignment: .leading, spacing: 8) {
                    Text("Servings")
                        .font(.headline)

                    Stepper(value: $servings, in: 1...20) {
                        HStack {
                            Text("\(servings)")
                                .font(.title2)
                                .fontWeight(.semibold)
                            if servings != recipe.baseServings {
                                Text("(base: \(recipe.baseServings))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Divider()

                // Ingredients
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ingredients")
                        .font(.headline)

                    ForEach(recipe.ingredients) { ingredient in
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(.secondary)

                            if let quantity = ingredient.quantity {
                                let adjusted = adjustedQuantity(quantity)
                                Text(formatQuantity(adjusted))
                                    .fontWeight(.medium)
                            }

                            if let unit = ingredient.unit {
                                Text(unit)
                            }

                            Text(ingredient.name)

                            if let notes = ingredient.notes {
                                Text("(\(notes))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.body)
                    }
                }

                if !recipe.steps.isEmpty {
                    Divider()

                    // Steps
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Instructions")
                            .font(.headline)

                        ForEach(recipe.steps.sorted(by: { $0.stepNumber < $1.stepNumber })) { step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(step.stepNumber)")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(.blue)
                                    .clipShape(Circle())

                                Text(step.instruction)
                                    .font(.body)
                            }
                        }
                    }
                }

                Divider()

                // Notes section (always shown)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Notes")
                            .font(.headline)
                        Spacer()
                        Button {
                            editableNotes = recipe.notes ?? ""
                            showNotesEditor = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.subheadline)
                        }
                    }

                    if let notes = recipe.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Add cooking tips, variations, or personal notes...")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .italic()
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    // Favorite button
                    if let memberId = viewModel.currentMemberId {
                        Button {
                            Task {
                                await viewModel.toggleFavorite(recipeId: recipe.id, memberId: memberId)
                            }
                        } label: {
                            Image(systemName: viewModel.isFavorite(recipeId: recipe.id, memberId: memberId) ? "heart.fill" : "heart")
                                .foregroundStyle(viewModel.isFavorite(recipeId: recipe.id, memberId: memberId) ? .pink : .secondary)
                        }
                    }

                    Menu {
                        Button {
                            showEditSheet = true
                        } label: {
                            Label("Edit Recipe", systemImage: "pencil")
                        }

                        if let url = recipe.sourceUrl, let sourceUrl = URL(string: url) {
                            Link(destination: sourceUrl) {
                                Label("View Source", systemImage: "safari")
                            }
                        }

                        Divider()

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Recipe", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            RecipeEditView(recipe: recipe, viewModel: viewModel)
        }
        .sheet(isPresented: $showNotesEditor) {
            NotesEditorView(notes: $editableNotes) {
                saveNotes()
            }
        }
        .confirmationDialog("Delete Recipe", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteRecipe(recipe)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this recipe?")
        }
    }

    private func adjustedQuantity(_ quantity: Double) -> Double {
        quantity * servingMultiplier
    }

    private func formatQuantity(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else if value.truncatingRemainder(dividingBy: 0.5) == 0 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }

    private func saveNotes() {
        var updated = recipe
        updated.notes = editableNotes.isEmpty ? nil : editableNotes
        updated.updatedAt = Date()

        Task {
            await viewModel.updateRecipe(updated)
        }
    }
}

// MARK: - Notes Editor View

struct NotesEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var notes: String
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $notes)
                    .padding()
            }
            .navigationTitle("Recipe Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// FlowLayout moved to Shared/Components/FlowLayout.swift

#Preview {
    NavigationStack {
        RecipeDetailView(
            recipe: Recipe(
                id: UUID(),
                householdId: UUID(),
                title: "Chicken Parmesan",
                sourceUrl: nil,
                sourceType: .manual,
                baseServings: 4,
                ingredients: [
                    Recipe.Ingredient(name: "chicken breasts", quantity: 4, unit: nil),
                    Recipe.Ingredient(name: "breadcrumbs", quantity: 1, unit: "cup"),
                    Recipe.Ingredient(name: "parmesan", quantity: 0.5, unit: "cup", notes: "grated")
                ],
                steps: [
                    Recipe.RecipeStep(stepNumber: 1, instruction: "Pound chicken to even thickness"),
                    Recipe.RecipeStep(stepNumber: 2, instruction: "Coat in breadcrumbs"),
                    Recipe.RecipeStep(stepNumber: 3, instruction: "Bake at 400F for 25 minutes")
                ],
                tags: ["Italian", "Chicken", "Dinner", "Quick"],
                prepTime: 20,
                cookTime: 30,
                notes: "Great with pasta!",
                createdAt: Date(),
                updatedAt: Date()
            ),
            viewModel: RecipesViewModel()
        )
    }
}
