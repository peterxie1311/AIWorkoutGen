//
//  HelperFunctions.swift
//  Workout
//
//  Created by Peter Xie on 22/12/2024.
//

import Foundation

import UIKit

class HelperFunctions {
   
    static func parseDateToStringFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    static func parseDateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    static func showAlert(on viewController: UIViewController, title: String, message: String) {
           let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
           alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
           viewController.present(alert, animated: true, completion: nil)
       }
    
    static func parseDateToStringTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    static func isLargerThanSunday(date: Date) -> Bool { // we're actually just doing saturday 
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // 1 = Sunday

        // Calculate the start of the week
        if let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start {
            let normalizedStartOfWeek = calendar.startOfDay(for: startOfWeek)
            return date > normalizedStartOfWeek
        }
        return false
    }



    
}



