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
    
    func fetchPreviousFoodLogDate(from currentDate: Date) -> Date? {
        loadFoodLogArrays()

        return foodLogHead
            .compactMap(\.date)
            .filter {
                Calendar.current.compare(
                    $0,
                    to: currentDate,
                    toGranularity: .day
                ) == .orderedAscending
            }
            .max()
    }

    func fetchNextFoodLogDate(from currentDate: Date) -> Date? {
        loadFoodLogArrays()

        return foodLogHead
            .compactMap(\.date)
            .filter {
                Calendar.current.compare(
                    $0,
                    to: currentDate,
                    toGranularity: .day
                ) == .orderedDescending
            }
            .min()
    }

    func fetchFoodHeadById(i_id: UUID) -> FoodLogHead? {
        foodLogHead.first { $0.foodHeadID == i_id }
    }

    func removeFoodLogLine(i_foodlogLine: FoodLogLine) async{
        guard let context = viewContext else { return }

        let tmpFoodHead = foodLogHead.filter { $0.foodHeadID == i_foodlogLine.foodHeadID }

        tmpFoodHead.forEach {
            $0.calories -= i_foodlogLine.calories
            $0.carbs -= i_foodlogLine.carbs
            $0.fat -= i_foodlogLine.fat
            $0.protein -= i_foodlogLine.protein
        }

        do {
            await DBConnector.shared.deleteFoodLogs(i_ids: [i_foodlogLine.toPayloadRequest()])
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
        let foodlogArray: [FoodLogLinePayload]
        do {
            foodlogArray = try await DBConnector.shared.fetchFoodLogs()
        } catch {
            if !Task.isCancelled, !(error is APIResponseError) {
                print("[Food log sync] Fetch failed: \(error)")
            }
            return
        }

        guard !Task.isCancelled else { return }
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
            guard !Task.isCancelled else { return }
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

        if !Task.isCancelled, !uploadFoodLogLines.isEmpty {
            let arr = uploadFoodLogLines.map{$0.toPayloadRequest()}
            await DBConnector.shared.insertFoodLog(i_flls: arr)
        }
    }

    func addFoodLogEntry(
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
        do {
            let context = try foodWriteContext()
            let payload = try stageFoodLogEntry(
                date: i_date, calories: i_calories, carbs: i_carbs, fat: i_fat, food: i_food,
                grams: i_grams, protein: i_protein, foodID: i_foodlineId, headID: i_foodheadId,
                in: context
            )
            try context.save()
            if i_foodlineId == nil {
                await DBConnector.shared.insertFoodLog(i_flls: [payload])
            }
            reloadAfterFoodSave()
        } catch {
            print("Failed to add food log entry: \(error)")
        }
    }

    /// Save the reviewed rows together before attempting cloud sync.
    func addReviewedFoodLogs(_ proposal: HistoryChatContext.FoodLogProposal,
                             session: String) async throws {
        guard !LogonViewController.requiresLogon(session),
              SettingsManager.shared.getSetting(name: SettingsManager.sessionKey)?.value == session else {
            throw SettingsSyncError.sessionChanged
        }
        let context = try foodWriteContext()
        let payloads = try proposal.entries.map { entry in
            try stageFoodLogEntry(date: entry.date, calories: entry.calories, carbs: entry.carbs,
                                  fat: entry.fat, food: entry.food, grams: entry.grams,
                                  protein: entry.protein, in: context)
        }
        try context.save()
        await DBConnector.shared.insertFoodLog(i_flls: payloads)
        reloadAfterFoodSave()
    }

    private func foodWriteContext() throws -> NSManagedObjectContext {
        guard let coordinator = viewContext?.persistentStoreCoordinator else {
            throw SettingsSyncError.localStorage
        }
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        return context
    }

    private func stageFoodLogEntry(date: Date, calories: Double, carbs: Double, fat: Double,
                                   food: String, grams: Double, protein: Double, foodID: UUID? = nil,
                                   headID: UUID? = nil,
                                   in context: NSManagedObjectContext) throws -> FoodLogLinePayloadRequest {
        guard let day = Calendar.current.dateInterval(of: .day, for: date) else {
            throw SettingsSyncError.localStorage
        }
        let heads: NSFetchRequest<FoodLogHead> = FoodLogHead.fetchRequest()
        let dateRange = NSPredicate(format: "date >= %@ AND date < %@", day.start as NSDate, day.end as NSDate)
        if let headID {
            heads.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                dateRange, NSPredicate(format: "foodHeadID == %@", headID as NSUUID)
            ])
        } else {
            heads.predicate = dateRange
        }
        let existingHead = try context.fetch(heads).first
        let head = existingHead ?? FoodLogHead(context: context)
        let resolvedHeadID = head.foodHeadID ?? headID ?? UUID()
        head.foodHeadID = resolvedHeadID
        if existingHead == nil { head.date = date }

        let lines: NSFetchRequest<FoodLogLine> = FoodLogLine.fetchRequest()
        lines.predicate = NSPredicate(format: "foodHeadID == %@", resolvedHeadID as NSUUID)
        let existingLines = try context.fetch(lines)
        head.calories = existingLines.reduce(calories) { $0 + $1.calories }
        head.carbs = existingLines.reduce(carbs) { $0 + $1.carbs }
        head.fat = existingLines.reduce(fat) { $0 + $1.fat }
        head.protein = existingLines.reduce(protein) { $0 + $1.protein }

        let payload = FoodLogLinePayloadRequest(
            i_foodheadid: resolvedHeadID, i_foodlineid: foodID ?? UUID(), i_calories: calories,
            i_carbs: carbs, i_fat: fat, i_food: food, i_grams: grams, i_protein: protein, i_date: date
        )
        _ = FoodLogLine.make(in: context, from: payload)
        return payload
    }

    private func reloadAfterFoodSave() {
        loadFoodLogArrays()
        NotificationCenter.default.post(name: NSNotification.Name(Constants.reloadFoodLogTrigger), object: nil)
    }
}
