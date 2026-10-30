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


/// Muscle-group illustrations stored in Assets.xcassets alongside food images.
enum ExerciseIcon: String, CaseIterable, Codable {
    case chest = "muscle_chest"
    case upperChest = "muscle_upper_chest"
    case back = "muscle_back"
    case lats = "muscle_lats"
    case traps = "muscle_traps"
    case shoulders = "muscle_shoulders"
    case biceps = "muscle_biceps"
    case triceps = "muscle_triceps"
    case forearms = "muscle_forearms"
    case abs = "muscle_abs"
    case obliques = "muscle_obliques"
    case lowerBack = "muscle_lower_back"
    case glutes = "muscle_glutes"
    case quadriceps = "muscle_quadriceps"
    case hamstrings = "muscle_hamstrings"
    case calves = "muscle_calves"
    case fullBody = "muscle_full_body"
    static let fallback: ExerciseIcon = .fullBody
    static var allowedIconNamesForPrompt: String {
        allCases.map { "\"\($0.rawValue)\"" }.joined(separator: ", ")
    }
    static func resolved(_ proposed: String?, exerciseName: String = "") -> ExerciseIcon {
        if let proposed, let icon = ExerciseIcon(rawValue: proposed) { return icon }
        let name = exerciseName.lowercased()
        if name.contains("calf") { return .calves }
        if name.contains("leg curl") || name.contains("romanian") { return .hamstrings }
        if name.contains("leg press") || name.contains("leg extension") { return .quadriceps }
        if name.contains("hip thrust") || name.contains("glute") { return .glutes }
        if name.contains("bench") || name.contains("chest") || name.contains("fly") || name.contains("press") && name.contains("incline") { return .chest }
        if name.contains("row") || name.contains("pull") { return .back }
        if name.contains("shoulder") || name.contains("lateral raise") || name.contains("overhead press") { return .shoulders }
        if name.contains("curl") { return .biceps }
        if name.contains("tricep") || name.contains("pushdown") { return .triceps }
        if name.contains("crunch") || name.contains("plank") || name.contains("ab ") { return .abs }
        if name.contains("deadlift") { return .lowerBack }
        return fallback
    }
}
