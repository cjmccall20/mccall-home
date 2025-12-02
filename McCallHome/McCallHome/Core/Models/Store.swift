//
//  Store.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import SwiftUI

/// Represents grocery stores for ingredient preferences
enum Store: String, Codable, CaseIterable, Identifiable {
    case walmart
    case costco
    case publix
    case wholeFoods = "whole_foods"
    case harrisTeeter = "harris_teeter"
    case farmersMarket = "farmers_market"
    case healthFoodStore = "health_food_store"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .walmart: return "Walmart"
        case .costco: return "Costco"
        case .publix: return "Publix"
        case .wholeFoods: return "Whole Foods"
        case .harrisTeeter: return "Harris Teeter"
        case .farmersMarket: return "Farmers Market"
        case .healthFoodStore: return "Health Food Store"
        }
    }

    /// SF Symbol icon name for each store
    var iconName: String {
        switch self {
        case .walmart: return "cart.fill"
        case .costco: return "shippingbox.fill"
        case .publix: return "basket.fill"
        case .wholeFoods: return "leaf.fill"
        case .harrisTeeter: return "storefront.fill"
        case .farmersMarket: return "carrot.fill"
        case .healthFoodStore: return "heart.circle.fill"
        }
    }

    /// Color associated with store branding
    var brandColor: Color {
        switch self {
        case .walmart: return Color(red: 0.0, green: 0.44, blue: 0.75)  // Walmart blue
        case .costco: return Color(red: 0.89, green: 0.09, blue: 0.18)  // Costco red
        case .publix: return Color(red: 0.22, green: 0.55, blue: 0.24)  // Publix green
        case .wholeFoods: return Color(red: 0.0, green: 0.35, blue: 0.18)  // Whole Foods green
        case .harrisTeeter: return Color(red: 0.8, green: 0.0, blue: 0.0)  // Harris Teeter red
        case .farmersMarket: return Color(red: 0.55, green: 0.35, blue: 0.17)  // Earthy brown
        case .healthFoodStore: return Color(red: 0.13, green: 0.55, blue: 0.13)  // Health green
        }
    }

    /// Short initial/letter for compact display
    var shortLabel: String {
        switch self {
        case .walmart: return "W"
        case .costco: return "C"
        case .publix: return "P"
        case .wholeFoods: return "WF"
        case .harrisTeeter: return "HT"
        case .farmersMarket: return "FM"
        case .healthFoodStore: return "HF"
        }
    }
}

// MARK: - Store Icon View

struct StoreIconView: View {
    let store: Store
    var size: CGFloat = 20

    var body: some View {
        ZStack {
            Circle()
                .fill(store.brandColor)
                .frame(width: size, height: size)

            Image(systemName: store.iconName)
                .font(.system(size: size * 0.5))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(Store.allCases) { store in
            HStack {
                StoreIconView(store: store)
                Text(store.displayName)
                Spacer()
            }
        }
    }
    .padding()
}
