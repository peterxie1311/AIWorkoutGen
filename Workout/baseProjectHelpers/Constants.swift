//
//  Constants.swift
//  Workout
//
//  Created by Peter Xie on 26/10/2024.
//

import Foundation
import CoreGraphics



struct Constants {
   static let minDate: Date             = Date.distantPast
   static let reloadFoodLogTrigger: String = "reloadFoodLogTrigger"
   static let string_default :String    =  " "
   static let num_default:Int           = 0
   static let num_defaultDouble:Double  = 0.0
   static let string_numDefault:String  = "0"
    static let setRepNotification:String = "SetRep"
    static let workoutSessionNotif:String = "workout"
}

extension Constants {
    /// Shared visual tokens. Keep content-specific measurements local to their views.
    enum Design {
        enum Radius {
            static let tile: CGFloat = 10
            static let field: CGFloat = 12
            static let button: CGFloat = 14
            static let compactCard: CGFloat = 18
            static let card: CGFloat = 22
        }
        enum Spacing {
            static let xsmall: CGFloat = 4
            static let small: CGFloat = 8
            static let medium: CGFloat = 12
            static let large: CGFloat = 16
            static let xlarge: CGFloat = 20
            static let section: CGFloat = 24
        }
        enum Size {
            static let buttonHeight: CGFloat = 50
            static let inputHeight: CGFloat = 48
            static let icon: CGFloat = 24
        }
    }
}
