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
    static func formatNumber(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value)) // no .0
        } else {
            return String(format: "%.2f", value) // 2dp
        }
    }
    
    static func parseIntSecToString(seconds: Int) -> String {
        let hrs = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hrs, mins, secs)
    }
    static func parseDateToStringTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    static func isDateHourBetween(date:Date,hour_less:Int,hour_greater:Int) -> Bool{
        let datehour = Calendar.current.component(.hour, from: date)
        return datehour <= hour_less && datehour >= hour_greater
    }
    
    
    static func isLargerThanSunday(date: Date) -> Bool { // we're actually just doing saturday
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 1 = Sunday

        // Calculate the start of the week
        if let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start {
            let normalizedStartOfWeek = calendar.startOfDay(for: startOfWeek)
            return date > normalizedStartOfWeek
        }
        return false
    }
      
}



