//
//  WorkoutSession.swift
//  Workout
//
//  Created by Peter Xie on 9/5/2026.
//

// WorkoutSession+Helpers.swift

import Foundation

extension WorkoutSession {
    
    var setrepArray: [Setrep] {
        let set = setrep as? Set<Setrep> ?? []
        
        return set.sorted {
            ($0.workoutName ?? "") < ($1.workoutName ?? "")
        }
    }
}
