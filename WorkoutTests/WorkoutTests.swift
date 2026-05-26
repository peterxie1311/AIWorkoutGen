//
//  WorkoutTests.swift
//  WorkoutTests
//
//  Created by Peter Xie on 24/10/2024.
//

import XCTest
@testable import Workout

final class WorkoutTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
//    func testCreateWorkoutPlan() async throws {
//        let vc = UIViewController()
//
//        let result = try await workoutAIservice.shared.createWorkoutPlan(
//            i_cntInputData: [],
//            i_sessions: 5,
//            i_vc: vc,
//            i_customisations: "Upper body hypertrophy"
//        )
//
//        print("RESULT COUNT:", result.count)
//
//        result.forEach {
//            print($0.workouttab)
//        }
//
//        XCTAssertEqual(result.count, 5)
//    }
    
    func testInsertStuff() async throws{
       
//
//        let url = Bundle(for: type(of: self))
//             .url(forResource: "workouts", withExtension: "json")!
//
//         let data = try Data(contentsOf: url)
//
//         let decoder = JSONDecoder()
//         decoder.dateDecodingStrategy = .iso8601
//
//         let workouts = try decoder.decode(
//             [WorkoutSessionUploadDTO].self,
//             from: data
//         )
      
            
//            await DBConnector.shared.insertWorkouts(i_ws: workouts)
        

//        workouts.forEach{
//            print($0.workout_genre)
//        }
        
    }
    
//    func testGrabWorkouts() async throws{
//                await WorkoutSessionManager.shared.syncworkoutsessionentries()
//            
//        
//        
//    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testAiFoodEstimate() async throws {
        let vc = UIViewController()
        
        let chicken = MacroEstimate(
            foodname: "Chicken",
            foodgrams: 150,
            protein: 0,
            carbs: 0,
            fats: 0,
            fiber: 0,
            assumptions: [],
            confidence: ""
        )
        
        try await workoutAIservice.shared.estimateMacros(i_ingredients: [chicken], i_vc: vc)
    }
    
    func UpdatesetrepDate() async throws {
        await MainActor.run {
            WorkoutSessionManager.shared.loadWorkoutSessions()
        }

        let dbWorkouts = await DBConnector.shared.fetchWorkoutSessions()

        await MainActor.run {
            for dbWorkout in dbWorkouts {
                print("WORKING  " )

                if let localWorkout =  WorkoutSessionManager.shared.workoutSessions.first(where: {
                    $0.id == dbWorkout.id
                }) {
                    for setrep in dbWorkout.setreps {
                        
                        if let localSet = localWorkout.setrepArray.first(where: {
                            $0.repid == setrep.repid
                            
                        }) {
                            localSet.duration_sec = Float(setrep.duration_sec)
                            print("Saved")
                            print(Float(setrep.duration_sec))
                            
                        }
                    }

                }
            }
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let context = appDelegate.persistentContainer.viewContext
            do{
                try context.save()
            }catch{
                print("didnt work")
            }
        }
    }
    
//    func testRemoveAllWorkouts() throws {
//        WorkoutSessionManager.shared.loadWorkoutSessions()
//        
//        WorkoutSessionManager.shared.workoutSessions.forEach{
//            
//            if let id = $0.id{
//                WorkoutSessionManager.shared.removeWorkoutSession(workoutid: id)
//            }
//        }
        
  //  }

}
