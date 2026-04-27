import CoreData
import UIKit

@MainActor
class FoodLogManager {
    static let shared = FoodLogManager()

    var foodLogHead: [FoodLogHead] = []
    var foodLogLine: [FoodLogLine] = []
    let reloadConst: String = "FoodLogReload"

    private init() {
        loadFoodLogArrays()
    }

    private var viewContext: NSManagedObjectContext? {
        (UIApplication.shared.delegate as? AppDelegate)?
            .persistentContainer
            .viewContext
    }

    func loadFoodLogArrays() {
        guard let context = viewContext else { return }

        let foodLogHeadfetchRequest: NSFetchRequest<FoodLogHead> = FoodLogHead.fetchRequest()
        let foodLogLinefetchRequest: NSFetchRequest<FoodLogLine> = FoodLogLine.fetchRequest()

        do {
            foodLogHead = try context.fetch(foodLogHeadfetchRequest)
            foodLogLine = try context.fetch(foodLogLinefetchRequest)
        } catch {
            print("Issue with loading foodlogs")
        }
    }

    func fetchFoodLinesbyID(i_id: UUID) -> [FoodLogLine] {
        loadFoodLogArrays()
        return foodLogLine.filter { $0.foodHeadID == i_id }
    }

    func fetchFoodLinesbyIDLessThanHour(
        i_id: UUID,
        i_hourLessThan: Int,
        i_hourGreaterThan: Int
    ) -> [FoodLogLine] {
        loadFoodLogArrays()
        return foodLogLine.filter {
            guard let date = $0.date else { return false }

            return $0.foodHeadID == i_id &&
                HelperFunctions.isDateHourBetween(
                    date: date,
                    hour_less: i_hourLessThan,
                    hour_greater: i_hourGreaterThan
                )
        }
    }

    func fetchFoodHeadbyDate(i_date: Date) -> FoodLogHead? {
        foodLogHead.first { head in
            guard let date = head.date else { return false }
            return Calendar.current.isDate(date, inSameDayAs: i_date)
        }
    }

    func fetchFoodHeadById(i_id: UUID) -> FoodLogHead? {
        foodLogHead.first { $0.foodHeadID == i_id }
    }

    func removeFoodLogLine(i_foodlogLine: FoodLogLine) {
        guard let context = viewContext else { return }

        let tmpFoodHead = foodLogHead.filter { $0.foodHeadID == i_foodlogLine.foodHeadID }

        tmpFoodHead.forEach {
            $0.calories -= i_foodlogLine.calories
            $0.carbs -= i_foodlogLine.carbs
            $0.fat -= i_foodlogLine.fat
            $0.protein -= i_foodlogLine.protein
        }

        do {
            context.delete(i_foodlogLine)
            try context.save()
            NotificationCenter.default.post(
                name: NSNotification.Name(Constants.reloadFoodLogTrigger),
                object: nil
            )
            loadFoodLogArrays()
        } catch {
            print("failed")
        }
    }

    func syncFoodLogEntries() async {
        loadFoodLogArrays()

        let foodlogArray = await DBConnector.shared.fetchFoodLogs()

        let localIds = Set(foodLogLine.map { $0.foodID })
        let dbIds = Set(foodlogArray.map { $0.foodID })

        var uploadFoodLogLines: [FoodLogLine] = []

        // local -> db
        for localItem in foodLogLine {
            if (localItem.foodID) != nil {
                if !dbIds.contains(localItem.foodID!) {
                    uploadFoodLogLines.append(localItem)
                }
            }
        }
        

        // db -> local
        for dbItem in foodlogArray {
            if !localIds.contains(dbItem.foodID) {
                await addFoodLogEntry(
                    i_date: dbItem.date,
                    i_calories: dbItem.calories,
                    i_carbs: dbItem.carbs,
                    i_fat: dbItem.fat,
                    i_food: dbItem.food,
                    i_grams: dbItem.grams,
                    i_protein: dbItem.protein,
                    i_foodlineId: dbItem.foodID,
                    i_foodheadId: dbItem.foodHeadID
                )
            }
        }

        if !uploadFoodLogLines.isEmpty {
         //   await DBConnector.shared.insertFoodLog(i_flls: uploadFoodLogLines)
        }
    }

    func addFoodLogEntry  (
        i_date: Date,
        i_calories: Double,
        i_carbs: Double,
        i_fat: Double,
        i_food: String,
        i_grams: Double,
        i_protein: Double,
        i_foodlineId: UUID? = nil,
        i_foodheadId: UUID? = nil
    ) async {
        guard let context = viewContext else { return }

        loadFoodLogArrays()
        
        let foodlineID = i_foodlineId ?? UUID()

        if let firstHead = foodLogHead.first(where: { head in
            guard let date = head.date else { return false }

            let sameDay = Calendar.current.isDate(date, inSameDayAs: i_date)

            if let id = i_foodheadId {
                return sameDay && head.foodHeadID == id
            } else {
                return sameDay
            }
        }) {

            var calcCaloriesTotals = i_calories
            var calcCarbsTotals = i_carbs
            var calcFatTotals = i_fat
            var calcProteinTotals = i_protein

            for line in foodLogLine where line.foodHeadID == firstHead.foodHeadID {
                calcCaloriesTotals += line.calories
                calcCarbsTotals += line.carbs
                calcFatTotals += line.fat
                calcProteinTotals += line.protein
            }
            
            firstHead.calories = calcCaloriesTotals
            firstHead.carbs = calcCarbsTotals
            firstHead.fat = calcFatTotals
            firstHead.protein = calcProteinTotals
            
            let dbPayload  = FoodLogLinePayloadRequest(i_foodheadid: firstHead.foodHeadID ?? UUID(),
                                                       i_foodlineid: foodlineID,
                                                       i_calories: i_calories,
                                                       i_carbs: i_carbs,
                                                       i_fat: i_fat,
                                                       i_food: i_food,
                                                       i_grams: i_grams,
                                                       i_protein: i_protein,
                                                       i_date: i_date)
            _ = FoodLogLine.make(in: context, from: dbPayload)
            do {
                
                await DBConnector.shared.insertFoodLog(i_flls: [dbPayload])
                try context.save()
                NotificationCenter.default.post(
                    name: NSNotification.Name(Constants.reloadFoodLogTrigger),
                    object: nil
                )
                loadFoodLogArrays()
            } catch {
                print("Failed to add new Food Log Entry!!")
            }
        } else {
            let newFoodLogHead = FoodLogHead(context: context)
            newFoodLogHead.calories = i_calories
            newFoodLogHead.carbs = i_carbs
            newFoodLogHead.fat = i_fat
            newFoodLogHead.date = i_date
            newFoodLogHead.protein = i_protein
            newFoodLogHead.foodHeadID = i_foodheadId ?? UUID()

            let newFoodLine = FoodLogLine(context: context)
            newFoodLine.calories = i_calories
            newFoodLine.carbs = i_carbs
            newFoodLine.fat = i_fat
            newFoodLine.food = i_food
            newFoodLine.grams = i_grams
            newFoodLine.protein = i_protein
            newFoodLine.foodHeadID = newFoodLogHead.foodHeadID
            newFoodLine.foodID = foodlineID
            newFoodLine.date = i_date

            do {
                try context.save()
                NotificationCenter.default.post(
                    name: NSNotification.Name(Constants.reloadFoodLogTrigger),
                    object: nil
                )
                loadFoodLogArrays()
            } catch {
                print("Error saving new Food Log Entry!!")
            }
        }
    }
}
