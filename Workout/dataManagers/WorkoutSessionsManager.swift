import CoreData
import UIKit

class WorkoutSessionManager {
    // Singleton instance
    static let shared = WorkoutSessionManager()
    
    // Stored workout sessions as an array of WorkoutSession objects
    var workoutSessions: [WorkoutSession] = []

    private init() {
        // Load workout sessions from Core Data
        loadWorkoutSessions()
    }
    
    func fetchSetreps(for workoutSession: WorkoutSession) {
        // Get the managedObjectContext from the AppDelegate
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let context = appDelegate.persistentContainer.viewContext
        
        // Assuming `setrep` is an NSSet containing related Setrep objects
        let _ = workoutSession.setrep
        
        // Create a fetch request for the related Setrep entity
        let fetchRequest: NSFetchRequest<Setrep> = Setrep.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "workoutSession == %@", workoutSession)

        // Perform the fetch
        do {
            let setrepObjects = try context.fetch(fetchRequest)
            print(setrepObjects.count)
            for setrep in setrepObjects {
                print("Setrep: \(setrep)")
            }
        } catch {
            print("Failed to fetch setreps: \(error)")
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
    
    // Get a workout session by location
    func getWorkoutSession() -> WorkoutSession? {
        for session in workoutSessions {
            
            let startTimeString = session.startTime != nil ? HelperFunctions.parseDateToStringFull(session.startTime!) : "1"
            let endTimeString = session.endTime != nil ? HelperFunctions.parseDateToStringFull(session.endTime!) : "2"
            if startTimeString == endTimeString{
                return session
            }
        }
        
        print("No open workout sessions!")
        return nil
    }

    
    func checkOpenWorkouts() -> String {
        var openWorkouts:String = "#Open Sesh:"
        openWorkouts += "\(checkOpenWorkoutsNum())"
        return openWorkouts
    }
    
    func checkOpenWorkoutsThisWeek()->String{
        var openWorkouts:String = "#Week Sesh:"
        openWorkouts += "\(checkWorkoutsThisWeekNum())"
        return openWorkouts
    }
    
    func checkOpenWorkoutsNum() -> Int64 {
       // var openWorkouts:String = "Number of Open Workouts "
        var counter:Int64 = 0
        
     
        for session in workoutSessions {
            let startTimeString = session.startTime != nil ? HelperFunctions.parseDateToStringFull(session.startTime!) : "1"
            let endTimeString = session.endTime != nil ? HelperFunctions.parseDateToStringFull(session.endTime!) : "2"
            if startTimeString == endTimeString{
                counter += 1
            }
        }
        //openWorkouts += "\(counter)"
        return counter
    }
    func checkWorkoutsThisWeekNum()-> Int64 {
        var counter:Int64 = 0
        for session in workoutSessions{
            if HelperFunctions.isLargerThanSunday(date: session.startTime!){
                counter += 1
            }
        }
        return counter
    }
    
    // get first open gym session
    func getFirstOpenGymSesh()-> WorkoutSession? {
      //  var tmpSession = WorkoutSession()
        for session in workoutSessions {
            let startTimeString = session.startTime != nil ? HelperFunctions.parseDateToStringFull(session.startTime!) : "1"
            let endTimeString = session.endTime != nil ? HelperFunctions.parseDateToStringFull(session.endTime!) : "2"
            if startTimeString == endTimeString{
                return session
            }
        }
        
        return nil
    }
    
    
    func checkIsOpenWorkout(workout: WorkoutSession) -> Bool {
        guard let startTime = workout.startTime, let endTime = workout.endTime else {
               return false
           }
        return HelperFunctions.parseDateToStringFull(startTime) == HelperFunctions.parseDateToStringFull(endTime)
    }
    
    
    // Update an existing workout session
    func updateWorkoutSession(prevWorkout: WorkoutSession, updatedSession: WorkoutSession) {
        if let index = workoutSessions.firstIndex(where: { $0.id == prevWorkout.id }) {
            workoutSessions[index] = updatedSession // Update the workout session object
            saveWorkoutSessions() // Save after updating
            NotificationCenter.default.post(name: NSNotification.Name("workout"), object: nil)
        } else {
            print("Cannot find workout session ID!!")
        }
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
    func addWorkoutSession(durationHrs: Float, endTime: Date, location: String, startTime: Date,sets:[Setrep]) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext

        // Create a new instance of WorkoutSession
        let newSession = WorkoutSession(context: context)
        newSession.id = UUID()
        newSession.duration_hrs = durationHrs
        newSession.endTime = endTime
        newSession.location = location
        newSession.startTime = startTime
        for set in sets {
                newSession.addToSetrep(set)// Assuming addToSets is generated by Core Data
            }

        // Save the context
        do {
            try context.save()
            print("New Workout Session added: Location: \(location), Duration: \(durationHrs) hrs, startdate: \(startTime) endtime: \(endTime)")
            NotificationCenter.default.post(name: NSNotification.Name("workout"), object: nil)
            loadWorkoutSessions() // Optionally reload workout sessions after adding
        } catch {
            print("Failed to add new workout session: \(error)")
        }
    }
}
