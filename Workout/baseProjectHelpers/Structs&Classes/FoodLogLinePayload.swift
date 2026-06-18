//
//  FoodLogLinePayload.swift
//  Workout
//
//  Created by Peter Xie on 23/4/2026.
//

import Foundation
import CoreData

struct FoodLogLinePayload: Decodable {
    let foodID: UUID
    let foodHeadID: UUID
    let calories: Double
    let carbs: Double
    let date: Date
    let fat: Double
    let grams: Double
    let protein: Double
    let userId: UUID
    let genDate: Date
    let food: String
}

//this is the header for the foodloglinepayloadrequest
struct AddFoodLogEntriesRequest: Encodable {
    let i_sessionid: String
    let i_payload: [FoodLogLinePayloadRequest]
}
struct FoodLogLinePayloadRequest: Encodable {
    let i_foodheadid: UUID
    let i_foodlineid: UUID
    let i_calories: Double
    let i_carbs: Double
    let i_fat: Double
    let i_food: String
    let i_grams: Double
    let i_protein: Double
    let i_date: Date
}
// ---- this is just to make code cleaner in foodlogmanager
extension FoodLogLine {
    static func make(
        in context: NSManagedObjectContext,
        from payload: FoodLogLinePayloadRequest
    ) -> FoodLogLine {
        
        let obj = FoodLogLine(context: context)
        
        obj.foodHeadID = payload.i_foodheadid
        obj.foodID = payload.i_foodlineid
        obj.calories = payload.i_calories
        obj.carbs = payload.i_carbs
        obj.fat = payload.i_fat
        obj.food = payload.i_food
        obj.grams = payload.i_grams
        obj.protein = payload.i_protein
        obj.date = payload.i_date
        
        return obj
    }
    func toPayloadRequest() -> FoodLogLinePayloadRequest {
          return FoodLogLinePayloadRequest(
              i_foodheadid: self.foodHeadID ?? UUID(),
              i_foodlineid: self.foodID ?? UUID(),
              i_calories: self.calories,
              i_carbs: self.carbs,
              i_fat: self.fat,
              i_food: self.food ?? "",
              i_grams: self.grams,
              i_protein: self.protein,
              i_date: self.date ?? Date()
          )
      }
}
