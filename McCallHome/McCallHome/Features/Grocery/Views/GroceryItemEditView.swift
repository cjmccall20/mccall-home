//
//  GroceryItemEditView.swift
//  McCallHome
//
//  Created by Claude on 12/3/25.
//

import SwiftUI

/// View for editing a grocery item's details and ingredient preferences
struct GroceryItemEditView: View {
    @Environment(\.dismiss) private var dismiss

    let item: GroceryItem
    let ingredientPreference: IngredientPreference?
    let onSave: (GroceryItemUpdate, IngredientPreferenceUpdate?) -> Void
    var onSubstitute: ((String) -> Void)?

    // Item state (local to current list)
    @State private var quantity: String
    @State private var unit: String

    // Substitution state
    @State private var showSubstitution = false
    @State private var substituteName: String = ""

    // Preference state (persists across lists)
    @State private var displayName: String
    @State private var brand: String
    @State private var preferredStore: Store?
    @State private var isInPerson: Bool
    @State private var isHouseStaple: Bool
    @State private var isPantryStaple: Bool
    @State private var isOrganic: Bool
    @State private var selectedLabels: Set<String>
    @State private var customLabels: [String]
    @State private var notes: String

    init(
        item: GroceryItem,
        ingredientPreference: IngredientPreference?,
        onSave: @escaping (GroceryItemUpdate, IngredientPreferenceUpdate?) -> Void,
        onSubstitute: ((String) -> Void)? = nil
    ) {
        self.item = item
        self.ingredientPreference = ingredientPreference
        self.onSave = onSave
        self.onSubstitute = onSubstitute

        // Initialize item state
        _quantity = State(initialValue: item.quantity.map { String($0) } ?? "")
        _unit = State(initialValue: item.unit ?? "")

        // Initialize preference state
        _displayName = State(initialValue: ingredientPreference?.displayName ?? item.name)
        _brand = State(initialValue: ingredientPreference?.brand ?? "")
        _preferredStore = State(initialValue: ingredientPreference?.preferredStore)
        _isInPerson = State(initialValue: ingredientPreference?.isInPerson ?? false)
        _isHouseStaple = State(initialValue: ingredientPreference?.isHouseStaple ?? false)
        _isPantryStaple = State(initialValue: ingredientPreference?.isPantryStaple ?? false)
        _isOrganic = State(initialValue: ingredientPreference?.isOrganic ?? false)
        _selectedLabels = State(initialValue: Set(ingredientPreference?.labels ?? []))
        _customLabels = State(initialValue: ingredientPreference?.customLabels ?? [])
        _notes = State(initialValue: ingredientPreference?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                // Current list section (quantity/unit)
                Section {
                    HStack {
                        TextField("Quantity", text: $quantity)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)

                        Picker("Unit", selection: $unit) {
                            Text("—").tag("")
                            ForEach(commonUnits, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                    }
                } header: {
                    Text("For This List")
                } footer: {
                    Text("Quantity changes apply only to this grocery list.")
                }

                // Preference section (persists)
                Section {
                    TextField("Display Name", text: $displayName)

                    TextField("Brand for Instacart", text: $brand)

                    Picker("Preferred Store", selection: $preferredStore) {
                        Text("Any Store").tag(Store?.none)
                        ForEach(Store.allCases) { store in
                            HStack {
                                StoreIconView(store: store, size: 16)
                                Text(store.displayName)
                            }
                            .tag(Store?.some(store))
                        }
                    }

                    Toggle("Purchase in Person", isOn: $isInPerson)

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Ingredient Preferences")
                } footer: {
                    Text("These preferences will be remembered for future lists. Brand is used for Instacart orders.")
                }

                // Staples section
                Section {
                    Toggle(isOn: $isHouseStaple) {
                        Label("House Staple", systemImage: "basket.fill")
                    }

                    Toggle(isOn: $isPantryStaple) {
                        Label("Pantry Staple", systemImage: "archivebox")
                    }
                } header: {
                    Text("Add to Staples")
                } footer: {
                    Text("Add to your staples lists for automatic inclusion in future grocery lists")
                }

                // Organic toggle (simplified - full labels in More > Ingredients)
                Section {
                    Toggle(isOn: $isOrganic) {
                        Label("Prefer Organic", systemImage: "leaf.circle.fill")
                    }
                } header: {
                    Text("Quality Preference")
                } footer: {
                    Text("For more label options (grass-fed, kosher, etc.) edit this ingredient in More > Ingredients")
                }

                // Store info section
                if let store = preferredStore {
                    Section {
                        HStack {
                            StoreIconView(store: store, size: 24)
                            VStack(alignment: .leading) {
                                Text(store.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(store.isOnInstacart ? "Available on Instacart" : "Not on Instacart")
                                    .font(.caption)
                                    .foregroundStyle(store.isOnInstacart ? .green : .orange)
                            }
                        }
                    } header: {
                        Text("Store Info")
                    }
                }

                // Substitution section
                if onSubstitute != nil {
                    Section {
                        if showSubstitution {
                            TextField("Substitute ingredient name", text: $substituteName)
                                .autocorrectionDisabled()

                            HStack {
                                Button("Cancel") {
                                    showSubstitution = false
                                    substituteName = ""
                                }

                                Spacer()

                                Button("Replace") {
                                    if !substituteName.isEmpty {
                                        onSubstitute?(substituteName)
                                        dismiss()
                                    }
                                }
                                .fontWeight(.semibold)
                                .disabled(substituteName.isEmpty)
                            }
                        } else {
                            Button {
                                showSubstitution = true
                            } label: {
                                Label("Substitute Ingredient", systemImage: "arrow.triangle.2.circlepath")
                            }
                        }
                    } header: {
                        Text("Substitution")
                    } footer: {
                        Text("Replace this ingredient with something else on your grocery list.")
                    }
                }
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var commonUnits: [String] {
        ["each", "lb", "lbs", "oz", "g", "kg", "cup", "cups", "tbsp", "tsp",
         "gallon", "quart", "pint", "ml", "L", "bunch", "can", "box", "bag", "package"]
    }

    private func save() {
        // Build item update
        let itemUpdate = GroceryItemUpdate(
            quantity: Double(quantity),
            unit: unit.isEmpty ? nil : unit
        )

        // Build preference update only if preference exists or we have changes
        var preferenceUpdate: IngredientPreferenceUpdate?

        let hasPreferenceChanges = displayName != (ingredientPreference?.displayName ?? item.name) ||
            brand != (ingredientPreference?.brand ?? "") ||
            preferredStore != ingredientPreference?.preferredStore ||
            isInPerson != (ingredientPreference?.isInPerson ?? false) ||
            isHouseStaple != (ingredientPreference?.isHouseStaple ?? false) ||
            isPantryStaple != (ingredientPreference?.isPantryStaple ?? false) ||
            isOrganic != (ingredientPreference?.isOrganic ?? false) ||
            Set(selectedLabels) != Set(ingredientPreference?.labels ?? []) ||
            customLabels != (ingredientPreference?.customLabels ?? []) ||
            notes != (ingredientPreference?.notes ?? "")

        if hasPreferenceChanges {
            preferenceUpdate = IngredientPreferenceUpdate(
                displayName: displayName.isEmpty ? nil : displayName,
                brand: brand.isEmpty ? nil : brand,
                preferredStore: preferredStore,
                isInPerson: isInPerson,
                isHouseStaple: isHouseStaple,
                isPantryStaple: isPantryStaple,
                isOrganic: isOrganic,
                labels: Array(selectedLabels),
                customLabels: customLabels,
                notes: notes.isEmpty ? nil : notes
            )
        }

        onSave(itemUpdate, preferenceUpdate)
        dismiss()
    }
}

// MARK: - Update Models

struct GroceryItemUpdate {
    let quantity: Double?
    let unit: String?
}

struct IngredientPreferenceUpdate {
    let displayName: String?
    let brand: String?
    let preferredStore: Store?
    let isInPerson: Bool
    let isHouseStaple: Bool
    let isPantryStaple: Bool
    let isOrganic: Bool
    let labels: [String]
    let customLabels: [String]
    let notes: String?
}

#Preview {
    GroceryItemEditView(
        item: GroceryItem(
            id: UUID(),
            groceryListId: UUID(),
            name: "Chicken breast",
            quantity: 2,
            unit: "lbs",
            category: .meat,
            isChecked: false,
            sortOrder: 0,
            createdAt: Date()
        ),
        ingredientPreference: nil,
        onSave: { _, _ in }
    )
}
