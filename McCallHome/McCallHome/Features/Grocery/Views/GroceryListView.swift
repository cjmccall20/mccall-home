//
//  GroceryListView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct GroceryListView: View {
    var body: some View {
        NavigationStack {
            Text("Grocery List")
                .font(.title)
                .foregroundStyle(.secondary)
                .navigationTitle("Grocery")
        }
    }
}

#Preview {
    GroceryListView()
}
