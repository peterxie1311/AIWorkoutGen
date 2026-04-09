//
//  FoodLogManager.swift
//  Workout
//
//  Created by Peter Xie on 24/1/2026.
//

import CoreData
import UIKit

class FoodLogManager {
    // Singleton instance
    static let shared = FoodLogManager()
    
    // Stored workout sessions as an array of WorkoutSession objects
    var foodLogHead: [FoodLogHead] = []
    var foodLogLine: [FoodLogLine] = []
    let reloadConst:String = "FoodLogReload"

    private init() {
        loadFoodLogArrays()
    }
    
    func loadFoodLogArrays() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        let foodLogHeadfetchRequest: NSFetchRequest<FoodLogHead> = FoodLogHead.fetchRequest()
        let foodLogLinefetchRequest: NSFetchRequest<FoodLogLine> = FoodLogLine.fetchRequest()

        do {
            
            foodLogHead = try context.fetch(foodLogHeadfetchRequest)
            foodLogLine = try context.fetch(foodLogLinefetchRequest)
        } catch {
            print("Issue with loading foodlogs");
        }
    }
    
    func fetchFoodLinesbyID(i_id: UUID)-> [FoodLogLine] {
        loadFoodLogArrays()
        return foodLogLine.filter { $0.foodHeadID == i_id }
    }
    
    func fetchFoodLinesbyIDLessThanHour(i_id:UUID,i_hourLessThan:Int,i_hourGreaterThan:Int) -> [FoodLogLine]{
        loadFoodLogArrays()
        return foodLogLine.filter {
            guard let date = $0.date else { return false }

            return $0.foodHeadID == i_id &&
            HelperFunctions.isDateHourBetween(date: date, hour_less:i_hourLessThan, hour_greater:i_hourGreaterThan)
        }
    }
    
    func fetchFoodHeadbyDate(i_date: Date)-> FoodLogHead? {
        if let firstHead = foodLogHead.first(where: { head in
            guard let nsDate = head.date else { return false }
            let date = nsDate as Date
            return Calendar.current.isDate(date, inSameDayAs: i_date)
        }) {
            return firstHead
        }else{
            return nil;
        }
    }
    
    func fetchFoodHeadById (i_id:UUID) -> FoodLogHead?{
        if let firstHead = foodLogHead.first(where: {$0.foodHeadID == i_id}) {
            return firstHead
        }else{
            return nil;
        }
        
    }
    
    func removeFoodLogLine (i_foodlogLine:FoodLogLine){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        let tmpFoodHead = foodLogHead.filter{$0.foodHeadID == i_foodlogLine.foodHeadID}
        //recalculate the head values
        tmpFoodHead.forEach{
            $0.calories -= i_foodlogLine.calories
            $0.carbs    -= i_foodlogLine.carbs
            $0.fat      -= i_foodlogLine.fat
            $0.protein  -= i_foodlogLine.protein
        }
        
        do {
            context.delete(i_foodlogLine)
            try context.save()
            NotificationCenter.default.post(name:NSNotification.Name(Constants.reloadFoodLogTrigger),object: nil)
        } catch {
            print("failed")
        }
    }
    
    func addFoodLogEntry(i_date: Date, i_calories: Double, i_carbs: Double, i_fat: Double, i_food: String, i_grams: Double, i_protein: Double) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        //check if there already exists a head for this date
        loadFoodLogArrays()
        if let firstHead = foodLogHead.first(where: { head in
            guard let nsDate = head.date else { return false }
            let date = nsDate as Date
            return Calendar.current.isDate(date, inSameDayAs: i_date)
        }) {
            // exists create a new food line
            let newFoodLine        = FoodLogLine(context:context)
            newFoodLine.calories   = i_calories
            newFoodLine.carbs      = i_carbs
            newFoodLine.fat        = i_fat
            newFoodLine.food       = i_food
            newFoodLine.grams      = i_grams
            newFoodLine.protein    = i_protein
            newFoodLine.foodHeadID = firstHead.foodHeadID
            newFoodLine.foodID     = UUID()
            newFoodLine.date       = Date()
            
            // Now we have to recalculate the totals of the foodhead
            var calcCaloriesTotals = i_calories
            var calcCarbsTotals    = i_carbs
            var calcFatTotals      = i_fat
            var calcProteinTotals  = i_protein
            
            for line in foodLogLine where line.foodHeadID == firstHead.foodHeadID {
                calcCaloriesTotals += line.calories
                calcCarbsTotals    += line.carbs
                calcFatTotals      += line.fat
                calcProteinTotals  += line.protein
            }
            firstHead.calories     = calcCaloriesTotals
            firstHead.carbs        = calcCarbsTotals
            firstHead.fat          = calcFatTotals
            firstHead.protein      = calcProteinTotals
        
            do {
                try context.save()
                NotificationCenter.default.post(name: NSNotification.Name(Constants.reloadFoodLogTrigger),object:nil)
                loadFoodLogArrays()
            } catch {
                print("Failed to add new Food Log Entry!!")
            }
            
        } else {
            // doesn't exist create a new food head and line
            let newFoodLogHead = FoodLogHead(context: context)
            newFoodLogHead.calories   = i_calories
            newFoodLogHead.carbs      = i_carbs
            newFoodLogHead.fat        = i_fat
            newFoodLogHead.date       = i_date
            newFoodLogHead.protein    = i_protein
            newFoodLogHead.foodHeadID = UUID()
            
            let newFoodLine = FoodLogLine(context:context)
            newFoodLine.calories   = i_calories
            newFoodLine.carbs      = i_carbs
            newFoodLine.fat        = i_fat
            newFoodLine.food       = i_food
            newFoodLine.grams      = i_grams
            newFoodLine.protein    = i_protein
            newFoodLine.foodHeadID = newFoodLogHead.foodHeadID
            newFoodLine.foodID     = UUID()
            newFoodLine.date       = Date()
            
            do {
                try context.save()
                NotificationCenter.default.post(name: NSNotification.Name(Constants.reloadFoodLogTrigger),object:nil)
                loadFoodLogArrays()
            } catch{
                print("Error saving new Food Log Entry!!`")
            }
        }
    }
}
