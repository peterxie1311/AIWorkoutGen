import CoreData
import UIKit

class WorkoutSessionManager {
    static let shared = WorkoutSessionManager()
    var workoutSessions: [WorkoutSession] = []

    private init() {
        loadWorkoutSessions()
    }
    

    @MainActor
    func syncworkoutsessionentries() async {
//        await MainActor.run {
//            loadWorkoutSessions()
//        }
//
//        let dbWorkouts = await DBConnector.shared.fetchWorkoutSessions()
//        var uploadArr:[WorkoutSessionUploadDTO] = []
//
//    
//            var didChange = false
//            for dbWorkout in dbWorkouts {
//                var shouldUpdate = false
//
//                if let localWorkout = workoutSessions.first(where: {
//                    $0.id == dbWorkout.id
//                }) {
//
//                    if localWorkout.moddate != dbWorkout.moddate {
//
//                        if localWorkout.moddate ?? .distantPast > dbWorkout.moddate ?? .distantPast {
//                            print("should update database with local workout session")
//                            shouldUpdate = true
//
//                        } else {
//                            localWorkout.duration_hrs = Float(dbWorkout.duration_hrs)
//                            localWorkout.endTime = dbWorkout.endTime
//                            localWorkout.location = dbWorkout.location
//                            localWorkout.moddate = dbWorkout.moddate
//                            localWorkout.rest_duration = dbWorkout.rest_duration ?? localWorkout.rest_duration
//                            localWorkout.startTime = dbWorkout.startTime
//                            localWorkout.workout_genre = dbWorkout.workout_genre
//                            localWorkout.workouttab = dbWorkout.workouttab
//
//                            didChange = true
//                            print("updated local workout session")
//                        }
//                    }
//
//                    dbWorkout.setreps.forEach { dto in
//
//                        if let localSetrep = localWorkout.setrepArray.first(where: {
//                            $0.repid == dto.repid
//                        }) {
//
//                            if localSetrep.moddate ?? .distantPast > dto.moddate ?? .distantPast {
//                                print("should update database with local setrep")
//                                shouldUpdate = true
//
//                            } else if localSetrep.moddate != dto.moddate {
//                                localSetrep.duration_sec = Float(dto.duration_sec)
//                                localSetrep.finishTime = dto.finishTime
//                                localSetrep.rep_qty = Int64(dto.rep_qty)
//                                localSetrep.startTime = dto.startTime
//                                localSetrep.weight = Int64(dto.weight)
//                                localSetrep.workoutName = dto.workoutName
//                                localSetrep.completed = dto.completed
//                                localSetrep.moddate = dto.moddate
//
//                                didChange = true
//                                print("updated local setrep")
//                            }
//
//                        } else {
//                            let newSetrep = SetrepManager.shared.initSetRep(
//                                qty: dto.rep_qty,
//                                startTime: dto.startTime ?? Date(),
//                                finishTime: dto.finishTime ?? Date(),
//                                workoutName: dto.workoutName ?? "",
//                                weight: Int64(dto.weight),
//                                uuid: dto.repid
//                            )
//
//                            newSetrep.duration_sec = Float(dto.duration_sec)
//                            newSetrep.completed = dto.completed
//                            newSetrep.moddate = dto.moddate
//
//                            localWorkout.addToSetrep(newSetrep)
//
//                            didChange = true
//                            print("inserted missing setrep into local workout")
//                        }
//                    }
//                    if shouldUpdate {
//                        uploadArr.append(localWorkout.toDTO())
//                    }
//                } else {
//                    let sets = dbWorkout.setreps.map { dto in
//                        let setrep = SetrepManager.shared.initSetRep(
//                            qty: dto.rep_qty,
//                            startTime: dto.startTime ?? Date(),
//                            finishTime: dto.finishTime ?? Date(),
//                            workoutName: dto.workoutName ?? "",
//                            weight: Int64(dto.weight),
//                            uuid: dto.repid
//                        )
//
//                        setrep.duration_sec = Float(dto.duration_sec)
//                        setrep.completed = dto.completed
//                        setrep.moddate = dto.moddate
//
//                        return setrep
//                    }
//
//                    addWorkoutSession(
//                        durationHrs: Float(dbWorkout.duration_hrs),
//                        endTime: dbWorkout.endTime ?? Date(),
//                        location: dbWorkout.location ?? "",
//                        startTime: dbWorkout.startTime ?? Date(),
//                        sets: sets,
//                        workoutTab: dbWorkout.workouttab ?? dbWorkout.workout_genre ?? "",
//                        uuid: dbWorkout.id
//                    )
//
//                    didChange = true
//                    print("inserted missing workout session")
//                }
//                
//               
//            }
//
//            if didChange {
//                saveWorkoutSessions()
//            }
//            
//            // now check if theres anyws.id in our local db not existing in our online db
//            for localWorkout in workoutSessions {
//                        if !dbWorkouts.contains(where: { $0.id == localWorkout.id }) {
//                            uploadArr.append(localWorkout.toDTO())
//                        }
//                    }
//        
//      
//        if uploadArr.count > 0{
//            await DBConnector.shared.insertWorkouts(i_ws: uploadArr)
//        }
    }
    
    func createWorkoutPlan(
        i_workouts: Int,
        i_sessions: Int,
        i_vc: UIViewController,
        i_customisations: String
    )  {
        Task {
            do {

                let sortedWorkouts = workoutSessions.sorted {
                    ($0.endTime ?? .distantPast) > ($1.endTime ?? .distantPast)
                }

                let recentWorkouts = Array(sortedWorkouts.prefix(i_workouts))

                let workoutArray: [WorkoutSessionDTO] = recentWorkouts.map { workout in

                    let setreps: [SetrepDTO] = workout.setrepArray.compactMap { setrep in
                        guard setrep.completed == true else {
                            return nil
                        }

                        return SetrepDTO(
                            workoutName: setrep.workoutName ?? "",
                            rep_qty: Int(setrep.rep_qty),
                            weight: Int(setrep.weight),
                            set_qty: 1
                        )
                    }

                    return WorkoutSessionDTO(
                        workouttab: workout.workouttab ?? "",
                        location: workout.location,
                        workout_genre: workout.workout_genre,
                        rest_time:workout.rest_duration,
                        setreps: setreps
                    )
                }
                
       
               let arr = try await workoutAIservice.shared.createWorkoutPlan(
                    i_cntInputData: workoutArray,
                    i_sessions: i_sessions,
                    i_vc: i_vc,
                    i_customisations: i_customisations
                )
                
                // wheen we call init on the DTO object it needs to run on the main thread
                
                await MainActor.run {
                    arr.forEach { w in
                        self.addWorkoutSession(
                            sets: w.setreps.flatMap(\.asSetreps),
                            workoutTab: w.workouttab,
                            rest_duration:w.rest_time
                        )
                    }
                }
                
                

            } catch {
                await MainActor.run {
                    HelperFunctions.showAlert(
                        on: i_vc,
                        title: "Workout Plan Failed",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    func removeWorkoutSession(workoutid:UUID){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<WorkoutSession> = WorkoutSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format:"id == %@",workoutid as CVarArg)

        do {
            let workoutsToDelete = try context.fetch(fetchRequest)
            print("Found \(workoutsToDelete.count) workout(s) to delete.")
            for workout in workoutsToDelete{
                context.delete(workout)
                NotificationCenter.default.post(name: NSNotification.Name("workout"), object: nil)
            }
            try context.save()
            loadWorkoutSessions()
            print("Workout(s) with name \(workoutid) successfully removed!")
        } catch {
            print("Failed to remove workout!: \(error)")
        }
    }

    func getOpenWorkouts() -> [WorkoutSession]{
        var arr:[WorkoutSession]=[]
        for session in workoutSessions {
            let startTimeString = session.startTime != nil ? HelperFunctions.parseDateToStringFull(session.startTime!) : "1"
            let endTimeString = session.endTime != nil ? HelperFunctions.parseDateToStringFull(session.endTime!) : "2"
            if startTimeString == endTimeString{
                arr.append(session)
            }
        }
        return arr;
    }
    
    // Update an existing workout session
    func updateWorkoutSession(prevWorkout: WorkoutSession, updatedSession: WorkoutSession) {
        if let index = workoutSessions.firstIndex(where: { $0.id == prevWorkout.id }) {
            updatedSession.moddate = Date()
            workoutSessions[index] = updatedSession // Update the workout session object
            saveWorkoutSessions() // Save after updating
            NotificationCenter.default.post(name: NSNotification.Name("workout"), object: nil)
        } else {
            print("Cannot find workout session ID!!")
        }
    }
    
    func getLastSetRep(i_workout: WorkoutSession) -> Setrep? {
        return i_workout.setrepArray.max {
            ($0.finishTime ?? Date()) < ($1.finishTime ?? Date())
        }
    }
    
    func getTotalRestTime(i_workout: WorkoutSession) -> Int {

        let completedSets = i_workout.setrepArray
            .filter { $0.completed == true }
            .sorted {
                ($0.finishTime ?? .distantPast) <
                ($1.finishTime ?? .distantPast)
            }

        var totalRest: TimeInterval = 0
        
        if completedSets.count == 0 {
            return 0
        }
        
        if completedSets.count == 1 {
            let set = completedSets[0].finishTime ?? Date()
            return Int(Date().timeIntervalSince(set))
        }
        for i in 1..<completedSets.count {

            guard
                let previous = completedSets[i - 1].finishTime,
                let current = completedSets[i].startTime
            else { continue }

            totalRest += current.timeIntervalSince(previous)
        }

        return Int(totalRest)
    }
    
    func clearWorkoutsessions() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<WorkoutSession> = WorkoutSession.fetchRequest()
        
        do {
            // Fetch all Setreps
            let allWorkoutSessions = try context.fetch(fetchRequest)
            
            // Delete each Setrep
            for s in allWorkoutSessions {
                context.delete(s)
            }
            
            // Save changes to context
            try context.save()
            
            // Reload Setreps array
            loadWorkoutSessions()
            NotificationCenter.default.post(name: NSNotification.Name("workout"), object: nil)
            
            print("All Setreps successfully cleared!")
            
        } catch {
            print("Failed to clear Setreps: \(error)")
        }
    }
    
    // Load workout sessions from Core Data
    func loadWorkoutSessions() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        // Create a fetch request for the WorkoutSession entity
        let fetchRequest: NSFetchRequest<WorkoutSession> = WorkoutSession.fetchRequest()

        do {
            // Execute the fetch request
            workoutSessions = try context.fetch(fetchRequest) // Fetch and assign directly to workoutSessions
        } catch {
            print("Failed to load workout sessions: \(error)")
        }
    }
    
    // Save workout sessions to Core Data
    func saveWorkoutSessions() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        // Save the context
        do {
            try context.save()
            print("Workout sessions saved successfully!")
            NotificationCenter.default.post(name: NSNotification.Name("workout"), object: nil)
        } catch {
            print("Failed to save workout sessions: \(error)")
        }
    }
    
    // Add a new workout session
    func addWorkoutSession(durationHrs: Float = 0 , endTime: Date = Date(), location: String = "", startTime: Date = Date(),sets:[Setrep],workoutTab:String,uuid:UUID = UUID(),rest_duration:Float = 0) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext

        // Create a new instance of WorkoutSession
        let newSession = WorkoutSession(context: context)
        newSession.id = uuid
        newSession.duration_hrs = durationHrs
        newSession.endTime = endTime
        newSession.location = location
        newSession.startTime = startTime
        newSession.workouttab = workoutTab
        newSession.rest_duration = rest_duration
        newSession.moddate = Date()
        for set in sets {
                newSession.addToSetrep(set)// Assuming addToSets is generated by Core Data
            }

        // Save the context
        do {
            try context.save()
            print("New Workout Session added: Location: \(location), Duration: \(durationHrs) hrs, startdate: \(startTime) endtime: \(endTime) |workout tab \(workoutTab)")
            loadWorkoutSessions()
            NotificationCenter.default.post(name: NSNotification.Name("workout"), object: nil)
             // Optionally reload workout sessions after adding
        } catch {
            print("Failed to add new workout session: \(error)")
        }
    }
}
