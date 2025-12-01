//
//  RecipeListView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct RecipeListView: View {
    var body: some View {
        NavigationStack {
            Text("Recipes")
                .font(.title)
                .foregroundStyle(.secondary)
                .navigationTitle("Recipes")
        }
    }
}

#Preview {
    RecipeListView()
}
