//
//  RecipeRowView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct RecipeRowView: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recipe.title)
                .font(.headline)

            HStack(spacing: 16) {
                if let prepTime = recipe.prepTime {
                    Label("\(prepTime)m prep", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let cookTime = recipe.cookTime {
                    Label("\(cookTime)m cook", systemImage: "flame")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Label("\(recipe.baseServings) servings", systemImage: "person.2")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let tags = recipe.tags, !tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                    if tags.count > 3 {
                        Text("+\(tags.count - 3)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        RecipeRowView(recipe: Recipe(
            id: UUID(),
            householdId: UUID(),
            title: "Chicken Parmesan",
            sourceUrl: nil,
            sourceType: .manual,
            baseServings: 4,
            ingredients: [],
            steps: [],
            tags: ["Italian", "Chicken", "Dinner"],
            prepTime: 20,
            cookTime: 30,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}
