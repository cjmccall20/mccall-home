//
//  GrocerySectionView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct GrocerySectionView: View {
    let category: GroceryItem.Category
    let items: [GroceryItem]
    var ingredientPreferences: [IngredientPreference]
    let onToggle: (GroceryItem) -> Void
    let onDelete: (GroceryItem) -> Void

    @State private var isExpanded = true

    private let preferenceService = IngredientPreferenceService.shared

    var checkedCount: Int {
        items.filter { $0.isChecked }.count
    }

    /// Find the matching ingredient preference for an item
    func preferenceForItem(_ item: GroceryItem) -> IngredientPreference? {
        preferenceService.findMatchingPreference(for: item.name, in: ingredientPreferences)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)

                    Text(category.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("\(checkedCount)/\(items.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal)
                .background(.bar)
            }
            .buttonStyle(.plain)

            // Items
            if isExpanded {
                ForEach(items) { item in
                    GroceryItemRow(
                        item: item,
                        ingredientPreference: preferenceForItem(item),
                        onToggle: { onToggle(item) },
                        onDelete: { onDelete(item) }
                    )
                    .padding(.horizontal)

                    if item.id != items.last?.id {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
        }
    }
}

#Preview {
    GrocerySectionView(
        category: .produce,
        items: [
            GroceryItem(
                id: UUID(),
                groceryListId: UUID(),
                name: "Tomatoes",
                quantity: 4,
                unit: nil,
                category: .produce,
                isChecked: false,
                sortOrder: 0,
                createdAt: Date()
            ),
            GroceryItem(
                id: UUID(),
                groceryListId: UUID(),
                name: "Onions",
                quantity: 2,
                unit: nil,
                category: .produce,
                isChecked: true,
                sortOrder: 1,
                createdAt: Date()
            )
        ],
        ingredientPreferences: [],
        onToggle: { _ in },
        onDelete: { _ in }
    )
}
