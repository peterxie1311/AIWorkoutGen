//
//  FoodIcons.swift
//  Workout
//
//  Created by Peter Xie on 17/5/2026.
//

//
//  FoodIconConstants.swift
//  Workout
//

import Foundation

enum FoodIcon: String, CaseIterable, Codable {
    case apple = "apple"
    case avocado = "avocado"
    case banana = "banana"
    case beans = "beans"
    case beef = "beef"
    case berries = "berries"
    case bread = "bread"
    case broccoli = "broccoli"
    case burger = "burger"
    case butter = "butter"
    case carrot = "carrot"
    case cauliflower = "cauliflower"
    case cereal = "cereal"
    case cheese = "cheese"
    case chicken = "chicken"
    case chocolate = "chocolate"
    case corn = "corn"
    case cucumber = "cucumber"
    case dessert = "dessert"
    case egg = "egg"
    case fish = "fish"
    case fries = "fries"
    case garlic = "garlic"
    case grapes = "grapes"
    case icecream = "icecream"
    case ketchup = "ketchup"
    case lettuce = "lettuce"
    case mayo = "mayo"
    case milk = "milk"
    case mushroom = "mushroom"
    case noodles = "noodles"
    case nuts = "nuts"
    case oats = "oats"
    case oliveOil = "olive_oil"
    case onion = "onion"
    case orange = "orange"
    case pasta = "pasta"
    case peas = "peas"
    case pizza = "pizza"
    case pokeBowl = "poke_bowl"
    case pork = "pork"
    case potato = "potato"
    case prawn = "prawn"
    case proteinPowder = "protein_powder"
    case proteinShake = "protein_shake"
    case ramen = "ramen"
    case rice = "rice"
    case salad = "salad"
    case salmon = "salmon"
    case sandwich = "sandwich"
    case sauce = "sauce"
    case spinach = "spinach"
    case sushi = "sushi"
    case sweetPotato = "sweet_potato"
    case tofu = "tofu"
    case tomato = "tomato"
    case tuna = "tuna"
    case vegetables = "vegetables"
    case wrap = "wrap"
    case yogurt = "yogurt"
}
extension FoodIcon {

    static var allowedIconNames: [String] {
        FoodIcon.allCases.map { $0.rawValue }
    }

    static var allowedIconNamesForPrompt: String {
        FoodIcon.allowedIconNames
            .map { "\"\($0)\"" }
            .joined(separator: ", ")
    }
}
