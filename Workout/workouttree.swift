import UIKit
import SwiftUI

class WorkoutTreeViewController: UIViewController {
    
    func getWorkoutStats() -> [workoutTree]{
        
        var setreps:[Setrep] = []
        var workoutnames:[String] = []
        var topWorkouts: [workoutTree] = []
        
        
        for session in WorkoutSessionManager.shared.workoutSessions{
            setreps.append(contentsOf: (session.setrep?.allObjects as? [Setrep]) ?? [])
            
        }
        
        // add all of the sets to the array
        for sets in setreps {
            workoutnames.append(sets.workoutName ?? " ")
        }
        //apply set to the array to get distinct values
        let uniqueNames = Array(Set(workoutnames))
        
        // then we need to get the max weight of all of the workout names
        for workoutname in uniqueNames {
            var maxWeight = 0
            var biggestRep: Setrep? = nil

            for rep in setreps {
                if rep.workoutName == workoutname && rep.weight > maxWeight {
                    maxWeight = Int(rep.weight)
                    biggestRep = rep
                }
            }

            if let rep = biggestRep {
                // Create workoutTree using info from biggestRep
                let workout = workoutTree(
                    workoutName: rep.workoutName ?? "Unknown",
                    WorkoutWeight: Int(maxWeight),
                    workoutreps: Int(rep.rep_qty)  // adjust depending on type of reps
                )
                topWorkouts.append(workout)
            }
        }
        
        return topWorkouts
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let treeView = TreeView(trees: getWorkoutStats())
        let hostingController = UIHostingController(rootView: treeView)

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        hostingController.didMove(toParent: self)
    }
}
