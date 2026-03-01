//
//  GoToVC.swift
//  Workout
//
//  Created by Peter Xie on 7/2/2026.
//

import UIKit

extension UIViewController {

    func goToAddSetPageVC() {
        if let tmpSession = WorkoutSessionManager.shared.getFirstOpenGymSesh() {
            let vc = AddSetViewController(workout: tmpSession)
            navigationController?.pushViewController(vc, animated: true)
        } else {
            HelperFunctions.showAlert(on: self, title: "Error", message: "Please Start a workout")
        }
    }
    
    func goToAddFoodLine(i_date:Date){
        let vc = AddFoodLogViewController(i_date: i_date)
        navigationController?.pushViewController(vc, animated: true)
    }
}
