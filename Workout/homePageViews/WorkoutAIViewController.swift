//
//  WorkoutViewController.swift
//  Workout
//
//  Created by Peter Xie on 25/4/2026.
//

import UIKit

class WorkoutAIViewController: UIViewController {
    
    // setup views
    private let stackScrollView = UIScrollView()
    private let stackView = UIStackView()
    
    private let summaryCard = WorkoutSummaryCardView()
    private let timerView   = WorkoutSummaryTimerView()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(stackScrollView)
        stackScrollView.addSubview(stackView)
        stackScrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .fill
        
        let views = [summaryCard,timerView]
        
        views.forEach{
            stackView.addArrangedSubview($0)
        }
        
        
        
        NSLayoutConstraint.activate([
            stackScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
               stackView.topAnchor.constraint(equalTo: stackScrollView.contentLayoutGuide.topAnchor),
               stackView.leadingAnchor.constraint(equalTo: stackScrollView.contentLayoutGuide.leadingAnchor, constant: 20),
               stackView.trailingAnchor.constraint(equalTo: stackScrollView.contentLayoutGuide.trailingAnchor, constant: -20),
               stackView.bottomAnchor.constraint(equalTo: stackScrollView.contentLayoutGuide.bottomAnchor),

               stackView.widthAnchor.constraint(equalTo: stackScrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
