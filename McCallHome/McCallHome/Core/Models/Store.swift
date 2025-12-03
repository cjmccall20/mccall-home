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
    case kroger
    case target
    case aldis = "aldis"
    case traderjoes = "trader_joes"
    case farmersMarket = "farmers_market"
    case healthFoodStore = "health_food_store"
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .walmart: return "Walmart"
        case .costco: return "Costco"
        case .publix: return "Publix"
        case .wholeFoods: return "Whole Foods"
        case .harrisTeeter: return "Harris Teeter"
        case .kroger: return "Kroger"
        case .target: return "Target"
        case .aldis: return "Aldi"
        case .traderjoes: return "Trader Joe's"
        case .farmersMarket: return "Farmers Market"
        case .healthFoodStore: return "Health Food Store"
        case .other: return "Other"
        }
    }

    /// Whether this store is available on Instacart
    var isOnInstacart: Bool {
        switch self {
        case .walmart, .publix, .wholeFoods, .harrisTeeter, .kroger, .target, .aldis, .other:
            return true
        case .costco, .farmersMarket, .healthFoodStore, .traderjoes:
            // Costco requires membership, Farmers Market and Trader Joe's not on Instacart
            return false
        }
    }

    /// Stores available on Instacart
    static var instacartStores: [Store] {
        allCases.filter { $0.isOnInstacart }
    }

    /// Stores NOT available on Instacart (require in-person or other shopping)
    static var nonInstacartStores: [Store] {
        allCases.filter { !$0.isOnInstacart }
    }

    /// SF Symbol icon name for each store
    var iconName: String {
        switch self {
        case .walmart: return "cart.fill"
        case .costco: return "shippingbox.fill"
        case .publix: return "basket.fill"
        case .wholeFoods: return "leaf.fill"
        case .harrisTeeter: return "storefront.fill"
        case .kroger: return "cart.fill"
        case .target: return "target"
        case .aldis: return "basket.fill"
        case .traderjoes: return "leaf.circle.fill"
        case .farmersMarket: return "carrot.fill"
        case .healthFoodStore: return "heart.circle.fill"
        case .other: return "bag.fill"
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
        case .kroger: return Color(red: 0.0, green: 0.33, blue: 0.63)  // Kroger blue
        case .target: return Color(red: 0.8, green: 0.0, blue: 0.0)  // Target red
        case .aldis: return Color(red: 0.0, green: 0.45, blue: 0.74)  // Aldi blue
        case .traderjoes: return Color(red: 0.76, green: 0.09, blue: 0.16)  // TJ's red
        case .farmersMarket: return Color(red: 0.55, green: 0.35, blue: 0.17)  // Earthy brown
        case .healthFoodStore: return Color(red: 0.13, green: 0.55, blue: 0.13)  // Health green
        case .other: return Color.gray
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
        case .kroger: return "K"
        case .target: return "T"
        case .aldis: return "A"
        case .traderjoes: return "TJ"
        case .farmersMarket: return "FM"
        case .healthFoodStore: return "HF"
        case .other: return "?"
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
