//
//  FoodLabel.swift
//  McCallHome
//
//  Created by Claude on 12/3/25.
//

import Foundation

/// Food quality/certification labels for ingredient preferences
enum FoodLabel: String, Codable, CaseIterable, Identifiable {
    // Meat & Poultry
    case grassFed = "grass_fed"
    case grassFinished = "grass_finished"
    case pastureRaised = "pasture_raised"
    case freeRange = "free_range"
    case cageFree = "cage_free"
    case airChilled = "air_chilled"
    case antibioticFree = "antibiotic_free"
    case hormoneFree = "hormone_free"
    case humanelyRaised = "humanely_raised"

    // Seafood
    case wildCaught = "wild_caught"
    case farmRaised = "farm_raised"
    case sustainable = "sustainable"
    case mscCertified = "msc_certified"

    // Religious/Dietary
    case kosher = "kosher"
    case halal = "halal"

    // General Quality
    case organic = "organic"
    case nonGMO = "non_gmo"
    case natural = "natural"
    case fairTrade = "fair_trade"
    case local = "local"

    // Dietary Restrictions
    case glutenFree = "gluten_free"
    case dairyFree = "dairy_free"
    case vegan = "vegan"
    case plantBased = "plant_based"
    case lowSodium = "low_sodium"
    case noAddedSugar = "no_added_sugar"
    case wholeGrain = "whole_grain"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .grassFed: return "Grass-Fed"
        case .grassFinished: return "Grass-Finished"
        case .pastureRaised: return "Pasture-Raised"
        case .freeRange: return "Free-Range"
        case .cageFree: return "Cage-Free"
        case .airChilled: return "Air-Chilled"
        case .antibioticFree: return "No Antibiotics"
        case .hormoneFree: return "No Hormones"
        case .humanelyRaised: return "Humanely Raised"
        case .wildCaught: return "Wild-Caught"
        case .farmRaised: return "Farm-Raised"
        case .sustainable: return "Sustainable"
        case .mscCertified: return "MSC Certified"
        case .kosher: return "Kosher"
        case .halal: return "Halal"
        case .organic: return "Organic"
        case .nonGMO: return "Non-GMO"
        case .natural: return "Natural"
        case .fairTrade: return "Fair Trade"
        case .local: return "Local"
        case .glutenFree: return "Gluten-Free"
        case .dairyFree: return "Dairy-Free"
        case .vegan: return "Vegan"
        case .plantBased: return "Plant-Based"
        case .lowSodium: return "Low Sodium"
        case .noAddedSugar: return "No Added Sugar"
        case .wholeGrain: return "Whole Grain"
        }
    }

    /// Icon for the label
    var iconName: String {
        switch self {
        case .grassFed, .grassFinished: return "leaf.fill"
        case .pastureRaised, .freeRange, .cageFree, .humanelyRaised: return "bird"
        case .airChilled: return "wind"
        case .antibioticFree, .hormoneFree: return "cross.vial"
        case .wildCaught: return "water.waves"
        case .farmRaised: return "building.2"
        case .sustainable, .mscCertified: return "globe.americas"
        case .kosher, .halal: return "checkmark.seal"
        case .organic: return "leaf.circle"
        case .nonGMO: return "dna"
        case .natural: return "tree"
        case .fairTrade: return "hand.raised"
        case .local: return "mappin.circle"
        case .glutenFree: return "wheat.slash"
        case .dairyFree: return "drop.triangle"
        case .vegan, .plantBased: return "carrot"
        case .lowSodium: return "minus.circle"
        case .noAddedSugar: return "cube"
        case .wholeGrain: return "rectangle.split.3x3"
        }
    }

    /// Category for grouping in UI
    var category: LabelCategory {
        switch self {
        case .grassFed, .grassFinished, .pastureRaised, .freeRange, .cageFree,
             .airChilled, .antibioticFree, .hormoneFree, .humanelyRaised:
            return .meatPoultry
        case .wildCaught, .farmRaised, .sustainable, .mscCertified:
            return .seafood
        case .kosher, .halal:
            return .religious
        case .organic, .nonGMO, .natural, .fairTrade, .local:
            return .quality
        case .glutenFree, .dairyFree, .vegan, .plantBased, .lowSodium, .noAddedSugar, .wholeGrain:
            return .dietary
        }
    }

    enum LabelCategory: String, CaseIterable {
        case meatPoultry = "Meat & Poultry"
        case seafood = "Seafood"
        case religious = "Religious"
        case quality = "Quality"
        case dietary = "Dietary"
    }

    /// Labels commonly used for a given grocery category
    static func suggestedLabels(for category: GroceryItem.Category) -> [FoodLabel] {
        switch category {
        case .meat:
            return [.grassFed, .grassFinished, .pastureRaised, .freeRange, .organic,
                    .antibioticFree, .hormoneFree, .humanelyRaised, .kosher, .halal]
        case .produce:
            return [.organic, .local, .nonGMO]
        case .dairy:
            return [.organic, .grassFed, .pastureRaised, .kosher, .dairyFree]
        case .bakery:
            return [.organic, .wholeGrain, .glutenFree, .vegan]
        case .frozen:
            return [.organic, .nonGMO, .glutenFree, .vegan]
        case .beverages:
            return [.organic, .noAddedSugar, .fairTrade]
        case .pantry, .verifyPantry:
            return [.organic, .nonGMO, .glutenFree, .kosher, .lowSodium]
        case .other:
            return [.organic, .nonGMO, .kosher, .halal]
        }
    }
}
