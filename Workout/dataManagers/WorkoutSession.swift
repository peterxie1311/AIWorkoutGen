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
               if ($0.workoutName ?? "") == ($1.workoutName ?? "") {
                   return ($0.repid?.uuidString ?? "") < ($1.repid?.uuidString ?? "")
               }

               return ($0.workoutName ?? "") < ($1.workoutName ?? "")
           }
    }
    
    
    func toDTO() -> WorkoutSessionUploadDTO {

         WorkoutSessionUploadDTO(
             id: self.id ?? UUID(),
             endTime: self.endTime,
             startTime: self.startTime,
             location: self.location,
             workout_genre: self.workout_genre,
             duration_hrs: Double(self.duration_hrs),
             workouttab: self.workouttab,
             rest_duration: self.rest_duration,
             moddate: self.moddate,
             setreps: self.setrepArray.map {
                 $0.toDTO()
             }
         )
     }
}
