//
//  IngredientDetailView.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import SwiftUI

struct IngredientDetailView: View {
    let ingredient: IngredientPreference
    @ObservedObject var viewModel: IngredientsViewModel

    @State private var displayName: String
    @State private var selectedStore: Store?
    @State private var isInPerson: Bool
    @State private var notes: String
    @State private var isSaving = false
    @State private var hasChanges = false

    init(ingredient: IngredientPreference, viewModel: IngredientsViewModel) {
        self.ingredient = ingredient
        self.viewModel = viewModel
        _displayName = State(initialValue: ingredient.displayName ?? "")
        _selectedStore = State(initialValue: ingredient.preferredStore)
        _isInPerson = State(initialValue: ingredient.isInPerson)
        _notes = State(initialValue: ingredient.notes ?? "")
    }

    var body: some View {
        Form {
            // Header section showing the canonical name
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Original Ingredient")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(ingredient.canonicalName.capitalized)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.vertical, 4)
            }

            // Display Name (brand/replacement)
            Section {
                TextField("Brand or specific name", text: $displayName)
                    .onChange(of: displayName) { _, _ in hasChanges = true }
            } header: {
                Text("Display Name")
            } footer: {
                Text("Enter the specific brand or product you buy (e.g., \"Kikkoman Organic Soy Sauce\" for soy sauce)")
            }

            // Store Selection
            Section {
                Picker("Preferred Store", selection: $selectedStore) {
                    Text("No specific store").tag(nil as Store?)
                    ForEach(Store.allCases) { store in
                        HStack {
                            StoreIconView(store: store, size: 20)
                            Text(store.displayName)
                        }
                        .tag(store as Store?)
                    }
                }
                .onChange(of: selectedStore) { _, _ in hasChanges = true }

                if let store = selectedStore {
                    HStack {
                        Text("Selected:")
                        Spacer()
                        StoreIconView(store: store, size: 24)
                        Text(store.displayName)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Store")
            } footer: {
                Text("Items with a store selected will show the store icon on your grocery list")
            }

            // In-Person Preference
            Section {
                Toggle(isOn: $isInPerson) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundStyle(isInPerson ? .orange : .secondary)
                        Text("Select in person")
                    }
                }
                .onChange(of: isInPerson) { _, _ in hasChanges = true }
            } header: {
                Text("Shopping Preference")
            } footer: {
                Text("Enable for items you prefer to pick out yourself (like produce or meat). These will be highlighted differently on your grocery list.")
            }

            // Notes
            Section {
                TextEditor(text: $notes)
                    .frame(minHeight: 60)
                    .onChange(of: notes) { _, _ in hasChanges = true }
            } header: {
                Text("Notes")
            } footer: {
                Text("Any additional notes about this ingredient")
            }

            // Preview section
            if !displayName.isEmpty || selectedStore != nil {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grocery List Preview")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            if let store = selectedStore {
                                StoreIconView(store: store, size: 24)
                            } else {
                                Image(systemName: "circle")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }

                            Text(displayName.isEmpty ? ingredient.canonicalName.capitalized : displayName)
                                .fontWeight(.medium)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(isInPerson ? Color.orange.opacity(0.1) : Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .navigationTitle("Edit Ingredient")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(!hasChanges || isSaving)
                .fontWeight(.semibold)
            }
        }
    }

    private func saveChanges() {
        isSaving = true

        var updated = ingredient
        updated.displayName = displayName.isEmpty ? nil : displayName
        updated.preferredStore = selectedStore
        updated.isInPerson = isInPerson
        updated.notes = notes.isEmpty ? nil : notes
        updated.updatedAt = Date()

        Task {
            await viewModel.updateIngredient(updated)
            hasChanges = false
            isSaving = false
        }
    }
}

#Preview {
    NavigationStack {
        IngredientDetailView(
            ingredient: IngredientPreference(
                householdId: UUID(),
                canonicalName: "soy sauce",
                displayName: "Kikkoman Organic Soy Sauce",
                preferredStore: .costco,
                isInPerson: false
            ),
            viewModel: IngredientsViewModel()
        )
    }
}
