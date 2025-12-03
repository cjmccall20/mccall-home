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
    @State private var brand: String
    @State private var selectedStore: Store?
    @State private var isInPerson: Bool
    @State private var isHouseStaple: Bool
    @State private var isPantryStaple: Bool
    @State private var isOrganic: Bool
    @State private var selectedLabels: Set<String>
    @State private var customLabels: [String]
    @State private var newCustomLabel: String = ""
    @State private var notes: String
    @State private var isSaving = false
    @State private var hasChanges = false

    init(ingredient: IngredientPreference, viewModel: IngredientsViewModel) {
        self.ingredient = ingredient
        self.viewModel = viewModel
        _displayName = State(initialValue: ingredient.displayName ?? "")
        _brand = State(initialValue: ingredient.brand ?? "")
        _selectedStore = State(initialValue: ingredient.preferredStore)
        _isInPerson = State(initialValue: ingredient.isInPerson)
        _isHouseStaple = State(initialValue: ingredient.isHouseStaple)
        _isPantryStaple = State(initialValue: ingredient.isPantryStaple)
        _isOrganic = State(initialValue: ingredient.isOrganic)
        _selectedLabels = State(initialValue: Set(ingredient.labels))
        _customLabels = State(initialValue: ingredient.customLabels)
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

            // Display Name
            Section {
                TextField("Display name for grocery list", text: $displayName)
                    .onChange(of: displayName) { _, _ in hasChanges = true }
            } header: {
                Text("Display Name")
            } footer: {
                Text("How this ingredient appears on your grocery list")
            }

            // Brand for Instacart
            Section {
                TextField("Brand name for Instacart", text: $brand)
                    .onChange(of: brand) { _, _ in hasChanges = true }
            } header: {
                Text("Brand / Specific Name")
            } footer: {
                Text("Enter the specific brand for Instacart orders (e.g., \"Kikkoman Organic\" for soy sauce)")
            }

            // Food Quality Labels
            Section {
                // Organic toggle (most common)
                Toggle(isOn: $isOrganic) {
                    HStack {
                        Image(systemName: "leaf.circle.fill")
                            .foregroundStyle(isOrganic ? .green : .secondary)
                        Text("Organic")
                    }
                }
                .onChange(of: isOrganic) { _, _ in hasChanges = true }

                // Standard labels by category
                DisclosureGroup("Quality & Sourcing Labels") {
                    ForEach(FoodLabel.LabelCategory.allCases, id: \.self) { category in
                        let labelsInCategory = FoodLabel.allCases.filter { $0.category == category }
                        if !labelsInCategory.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(category.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)

                                FlowLayout(spacing: 8) {
                                    ForEach(labelsInCategory) { label in
                                        LabelChip(
                                            label: label.displayName,
                                            isSelected: selectedLabels.contains(label.rawValue),
                                            onTap: {
                                                if selectedLabels.contains(label.rawValue) {
                                                    selectedLabels.remove(label.rawValue)
                                                } else {
                                                    selectedLabels.insert(label.rawValue)
                                                }
                                                hasChanges = true
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }

                // Custom labels
                if !customLabels.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Custom Labels")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        FlowLayout(spacing: 8) {
                            ForEach(customLabels, id: \.self) { label in
                                HStack(spacing: 4) {
                                    Text(label)
                                        .font(.caption)
                                    Button {
                                        customLabels.removeAll { $0 == label }
                                        hasChanges = true
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.purple.opacity(0.2))
                                .foregroundStyle(.purple)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Add custom label
                HStack {
                    TextField("Add custom label", text: $newCustomLabel)
                        .textInputAutocapitalization(.words)

                    Button {
                        let trimmed = newCustomLabel.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty && !customLabels.contains(trimmed) {
                            customLabels.append(trimmed)
                            newCustomLabel = ""
                            hasChanges = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                    .disabled(newCustomLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } header: {
                Text("Food Labels")
            } footer: {
                Text("Labels are included when searching Instacart (e.g., \"grass-fed ground beef\")")
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

            // Shopping Preferences
            Section {
                Toggle(isOn: $isInPerson) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundStyle(isInPerson ? .orange : .secondary)
                        Text("Purchase in Person")
                    }
                }
                .onChange(of: isInPerson) { _, _ in hasChanges = true }
            } header: {
                Text("Shopping Preference")
            } footer: {
                Text("Enable for items you prefer to pick out yourself (like produce or meat)")
            }

            // Staples Lists
            Section {
                Toggle(isOn: $isHouseStaple) {
                    HStack {
                        Image(systemName: "basket.fill")
                            .foregroundStyle(isHouseStaple ? .orange : .secondary)
                        Text("House Staple")
                    }
                }
                .onChange(of: isHouseStaple) { _, _ in hasChanges = true }

                Toggle(isOn: $isPantryStaple) {
                    HStack {
                        Image(systemName: "archivebox")
                            .foregroundStyle(isPantryStaple ? .brown : .secondary)
                        Text("Pantry Staple")
                    }
                }
                .onChange(of: isPantryStaple) { _, _ in hasChanges = true }
            } header: {
                Text("Staples Lists")
            } footer: {
                Text("Add this ingredient to your staples lists. House staples are everyday items, pantry staples are longer-lasting supplies. Items on these lists are automatically added to grocery lists.")
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
        updated.brand = brand.isEmpty ? nil : brand
        updated.preferredStore = selectedStore
        updated.isInPerson = isInPerson
        updated.isHouseStaple = isHouseStaple
        updated.isPantryStaple = isPantryStaple
        updated.isOrganic = isOrganic
        updated.labels = Array(selectedLabels)
        updated.customLabels = customLabels
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
