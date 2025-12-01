//
//  MealPlanView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct MealPlanView: View {
    var body: some View {
        NavigationStack {
            Text("Meal Plan")
                .font(.title)
                .foregroundStyle(.secondary)
                .navigationTitle("Meal Plan")
        }
    }
}

#Preview {
    MealPlanView()
}
