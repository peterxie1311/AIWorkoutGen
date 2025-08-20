import CoreData
import UIKit

class SetrepManager {
    // Singleton instance
    static let shared = SetrepManager()
    
    // Stored Setreps as an array of Setrep objects
    var Setreps: [Setrep] = []

    private init() {
        // Load Setreps from Core Data
        loadSetreps()
    }
    
    // Get a Setrep by its quantity
    func getSetrep(uuid: UUID) -> Setrep? {
        for Setrep in Setreps {
            if Setrep.repid == uuid {
                return Setrep
            }
        }
        return nil
    }
    // Clear all Setreps from Core Data
    func clearSetreps() {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest: NSFetchRequest<Setrep> = Setrep.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "workoutSession == nil")
            
            do {
                // Fetch all Setreps
                let allSetreps = try context.fetch(fetchRequest)
                
                // Delete each Setrep
                for setrep in allSetreps {
                    context.delete(setrep)
                }
                
                // Save changes to context
                try context.save()
                
                // Reload Setreps array
                loadSetreps()
                NotificationCenter.default.post(name: NSNotification.Name("SetRep"), object: nil)
                
                print("All Setreps successfully cleared!")
                
            } catch {
                print("Failed to clear Setreps: \(error)")
            }
        }

    
    //remove setRep
    func removeSetrep(repid:UUID){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Setrep> = Setrep.fetchRequest()
        fetchRequest.predicate = NSPredicate(format:"repid == %@ ",repid as CVarArg)
        do {
            let setRepsToDelete = try context.fetch(fetchRequest)
            
            for setRep in setRepsToDelete{
                context.delete(setRep)
            NotificationCenter.default.post(name: NSNotification.Name("SetRep"), object: nil)
            }
            try context.save()
            loadSetreps()
            print("SetRep(s) with name \(repid) successfully removed!")
        } catch {
            print("Failed to remove workout!: \(error)")
        }
    }
    
    // Update an existing Setrep
    func updateSetrep(repid:UUID,updatedSetrep:Setrep) {
        if let index = Setreps.firstIndex(where: { $0.repid == repid}) {
            Setreps[index] = updatedSetrep
            saveSetreps()
            print("Updated rep! \(repid)")
            NotificationCenter.default.post(name: NSNotification.Name("SetRep"), object: nil)
        } else {
            print("No Setrep found to update with quantity: \(repid)!")
        }
    }
    
    // Load Setreps from Core Data
    func loadSetreps() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Setrep> = Setrep.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "workoutSession == nil")

        do {
            Setreps = try context.fetch(fetchRequest)
            print("Loaded \(Setreps.count) Setreps not associated with any WorkoutSession")
        } catch {
            print("Failed to load Setreps: \(error)")
        }
    }
    
    // Save Setreps to Core Data
    func saveSetreps() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        // Save the context
        do {
            try context.save()
            print("Setreps saved successfully!")
        } catch {
            print("Failed to save Setreps: \(error)")
        }
    }
    
    func toDoHasCompletedSetRep() -> Bool {
        for setRep in Setreps {
            if setRep.completed == true {
                return true
            }
        }
        return false
    }
    
    func initSetRep(qty: Int, startTime: Date, finishTime: Date, workoutName: String, weight: Int64) -> Setrep {
        let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext ?? NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)

        let newSetrep = Setrep(context: context)
        newSetrep.rep_qty = Int64(qty)
        newSetrep.startTime = startTime
        newSetrep.finishTime = finishTime
        newSetrep.workoutName = workoutName
        newSetrep.completed = false
        newSetrep.weight = weight
        newSetrep.repid = UUID()
        
        return newSetrep
    }
    
    func getLatestSetRep(setrepArray:[Setrep]) -> Setrep{
        var latestRep = setrepArray[0]
        for setrep in setrepArray {
            if setrep.finishTime ?? Date(timeIntervalSince1970: 0) > latestRep.finishTime ?? Date(timeIntervalSince1970: 0){ // just using 1970 if null because it will always be smaller
                latestRep = setrep
            }
        }
        return latestRep
    }
    
//    func initSetrep (workoutName:String) -> Setrep? {
//        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
//        let context = appDelegate.persistentContainer.viewContext
//        let newSetrep         = Setrep(context: context)
//        newSetrep.rep_qty     = Int64(0)
//        newSetrep.startTime   = Date()
//        newSetrep.finishTime  = Date()
//        newSetrep.workoutName = workoutName
//        newSetrep.completed   = false
//        newSetrep.weight      = 0
//        newSetrep.repid       = UUID()
//        
//        return newSetrep
//        
//    }

    // Add a new Setrep
    func addSetrep(qty: Int, startTime: Date, finishTime: Date, workoutName: String,weight:Int64) {
        DispatchQueue.main.async { // run it on the main thread
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let context = appDelegate.persistentContainer.viewContext

            let newSetrep         = Setrep(context: context)
            newSetrep.rep_qty     = Int64(qty)
            newSetrep.startTime   = startTime
            newSetrep.finishTime  = finishTime
            newSetrep.workoutName = workoutName
            newSetrep.completed   = false
            newSetrep.weight      = weight
            newSetrep.repid       = UUID()

            do {
                try context.save()
                print("New Setrep added: Quantity: \(qty), Workout Name: \(workoutName)")
                self.loadSetreps()
                NotificationCenter.default.post(name: NSNotification.Name("SetRep"), object: nil)
            } catch {
                print("Failed to add new Setrep: \(error)")
            }
        }
        
        
    }
}
