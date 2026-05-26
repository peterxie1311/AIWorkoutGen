//
//  SavedFoodsManager.swift
//  Workout
//
//  Created by Peter Xie on 17/5/2026.
//

import CoreData
import UIKit

import UIKit
import CoreData

struct SavedFoodModel {
    let savedFoodRef: UUID
    let name: String
    let image: String
    let grams: Double
    let protein: Double
    let carbs: Double
    let fat: Double

    var calories: Double {
        (protein * 4) + (carbs * 4) + (fat * 9)
    }

    var amountText: String {
        "\(formatNumber(grams))g"
    }

    var uiImage: UIImage {
        UIImage(named: image) ?? UIImage(named: "default_food") ?? UIImage()
    }

    private func formatNumber(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        } else {
            return String(format: "%.1f", value)
        }
    }
}

final class SavedFoodsManager {

    static let shared = SavedFoodsManager()

    private(set) var savedFoods: [SavedFoodModel] = []

    private init() {}
    
    private var viewContext: NSManagedObjectContext? {
        (UIApplication.shared.delegate as? AppDelegate)?
            .persistentContainer
            .viewContext
    }


    // MARK: - Load

    func loadSavedFoods(context: NSManagedObjectContext) {
        let request: NSFetchRequest<SavedFoods> = SavedFoods.fetchRequest()

        request.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true)
        ]

        do {
            let coreDataFoods = try context.fetch(request)

            self.savedFoods = coreDataFoods.compactMap { food in
                guard
                    let id = food.savedFoodref,
                    let name = food.name,
                    let image = food.image
                else {
                    return nil
                }

                return SavedFoodModel(
                    savedFoodRef: id,
                    name: name,
                    image: image,
                    grams: food.grams,
                    protein: food.protein,
                    carbs: food.carbs,
                    fat: food.fat
                )
            }

        } catch {
            print("Failed to load saved foods:", error)
            self.savedFoods = []
        }
    }

    // MARK: - Add

    @discardableResult
    func addSavedFood(
      
        name: String,
        image: String,
        grams: Double,
        protein: Double,
        carbs: Double,
        fat: Double
    ) -> SavedFoodModel? {
        
        guard let context = self.viewContext else {return nil}

        let newSavedFood = SavedFoods(context: context)

        let id = UUID()

        newSavedFood.savedFoodref = id
        newSavedFood.name = name
        newSavedFood.image = image
        newSavedFood.grams = grams
        newSavedFood.protein = protein
        newSavedFood.carbs = carbs
        newSavedFood.fat = fat

        do {
            try context.save()

            let model = SavedFoodModel(
                savedFoodRef: id,
                name: name,
                image: image,
                grams: grams,
                protein: protein,
                carbs: carbs,
                fat: fat
            )

            savedFoods.append(model)
            savedFoods.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            return model

        } catch {
            context.rollback()
            print("Failed to add saved food:", error)
            return nil
        }
    }

    // MARK: - Delete

    func deleteSavedFood(
        context: NSManagedObjectContext,
        savedFoodRef: UUID
    ) -> Bool {

        let request: NSFetchRequest<SavedFoods> = SavedFoods.fetchRequest()
        request.predicate = NSPredicate(format: "savedFoodRef == %@", savedFoodRef as CVarArg)
        request.fetchLimit = 1

        do {
            guard let foodToDelete = try context.fetch(request).first else {
                print("Saved food not found for delete:", savedFoodRef)
                return false
            }

            context.delete(foodToDelete)
            try context.save()

            savedFoods.removeAll { $0.savedFoodRef == savedFoodRef }

            return true

        } catch {
            context.rollback()
            print("Failed to delete saved food:", error)
            return false
        }
    }

    // MARK: - Fetch by ID

    func getSavedFood(savedFoodRef: UUID) -> SavedFoodModel? {
        savedFoods.first { $0.savedFoodRef == savedFoodRef }
    }

    func fetchSavedFoodFromCoreData(
        context: NSManagedObjectContext,
        savedFoodRef: UUID
    ) -> SavedFoodModel? {

        let request: NSFetchRequest<SavedFoods> = SavedFoods.fetchRequest()
        request.predicate = NSPredicate(format: "savedFoodRef == %@", savedFoodRef as CVarArg)
        request.fetchLimit = 1

        do {
            guard let food = try context.fetch(request).first else {
                return nil
            }

            guard
                let id = food.savedFoodref,
                let name = food.name,
                let image = food.image
            else {
                return nil
            }

            return SavedFoodModel(
                savedFoodRef: id,
                name: name,
                image: image,
                grams: food.grams,
                protein: food.protein,
                carbs: food.carbs,
                fat: food.fat
            )

        } catch {
            print("Failed to fetch saved food by id:", error)
            return nil
        }
    }

    // MARK: - Clear Local Cache

    func clearLocalArray() {
        savedFoods.removeAll()
    }
}
