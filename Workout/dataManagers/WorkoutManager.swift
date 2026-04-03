import CoreData
import UIKit

class WorkoutManager {
    // Singleton instance
    static let shared = WorkoutManager()
    
    // Stored workouts as an array of Workout objects
    var workouts: [Workout] = []
    var todoList: [Workout] = []

    private init() {
        // Load workouts from Core Data
        loadWorkout()
    }
    
    // Get a workout by name
    func getWorkout(workoutName: String) -> Workout? {
        for workout in workouts {
            if workout.workoutName == workoutName {
                return workout
            }
        }
        print("No workout found with name: \(workoutName)!")
        return nil
    }
    
    // Update an existing workout
    func updateWorkout(workoutName: String, updatedWorkout: Workout) {
        if let index = workouts.firstIndex(where: { $0.workoutName == workoutName }) {
            workouts[index] = updatedWorkout // Update the workout object
            saveWorkout() // Save after updating
            NotificationCenter.default.post(name: NSNotification.Name("workout"), object: nil)
        } else {
            print("No workout found to update with name: \(workoutName)!")
        }
    }
    
    func removeWorkout(workoutName:String, bodyPart:String,video:String,workoutDescription:String){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
        fetchRequest.predicate = NSPredicate(format:"workoutName == %@ AND bodyPart == %@ AND video == %@ AND workoutDescription == %@",workoutName,bodyPart,video,workoutDescription)
        do {
            let workoutsToDelete = try context.fetch(fetchRequest)
            
            for workout in workoutsToDelete{
                context.delete(workout)
                NotificationCenter.default.post(name: NSNotification.Name("workout"), object: nil)
            }
            try context.save()
            loadWorkout()
            print("Workout(s) with name \(workoutName) successfully removed!")
        } catch {
            print("Failed to remove workout!: \(error)")
        }
    }
    
    // Load workouts from Core Data
    func loadWorkout() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        // Create a fetch request for the Workout entity
        let fetchRequest: NSFetchRequest<Workout> = Workout.fetchRequest()

        do {
            // Execute the fetch request
            workouts = try context.fetch(fetchRequest) // Fetch and assign directly to workouts
        } catch {
            print("Failed to load workouts: \(error)")
        }
    }
    
    // Save workouts to Core Data
    func saveWorkout() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        // Save the context
        do {
            try context.save()
            print("Workouts saved successfully!")
        } catch {
            print("Failed to save workouts: \(error)")
        }
    }
    
    // Add a new workout
    func addWorkout(bodyPart: String, video: String, workoutDescription: String, workoutName: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext

        // Create a new instance of Workout
        let newWorkout = Workout(context: context)
        newWorkout.bodyPart = bodyPart
        newWorkout.video = video
        newWorkout.workoutDescription = workoutDescription
        newWorkout.workoutName = workoutName

        // Save the context
        do {
            try context.save()
            NotificationCenter.default.post(name: NSNotification.Name("workout"), object: nil)
            print("New Workout added: Body Part: \(bodyPart), Workout Name: \(workoutName)")
            loadWorkout() // Optionally reload workouts after adding
        } catch {
            print("Failed to add new workout: \(error)")
        }
    }
}
