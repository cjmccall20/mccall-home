//
//  HoneydewListView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct HoneydewListView: View {
    var body: some View {
        NavigationStack {
            Text("Honeydew Tasks")
                .font(.title)
                .foregroundStyle(.secondary)
                .navigationTitle("Honeydew")
        }
    }
}

#Preview {
    HoneydewListView()
}
