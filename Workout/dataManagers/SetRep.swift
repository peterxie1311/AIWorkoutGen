//
//  SetRep.swift
//  Workout
//
//  Created by Peter Xie on 15/5/2026.
//

import Foundation
extension Setrep {

    func toDTO() -> SetrepUploadDTO {

        SetrepUploadDTO(
            repid: self.repid ?? UUID(),
            duration_sec: Double(self.duration_sec),
            finishTime: self.finishTime,
            rep_qty: Int(self.rep_qty),
            startTime: self.startTime,
            weight: Double(self.weight),
            workoutName: self.workoutName,
            completed: self.completed,
            moddate: self.moddate
        )
    }
}
