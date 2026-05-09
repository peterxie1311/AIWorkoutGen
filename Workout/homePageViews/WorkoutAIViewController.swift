//
//  WorkoutViewController.swift
//  Workout
//
//  Created by Peter Xie on 25/4/2026.
//

import UIKit

class WorkoutAIViewController: UIViewController,UITextFieldDelegate {
    
    // setup views
    private let stackScrollView = UIScrollView()
    private let stackView = UIStackView()
    
    private let summaryCard = WorkoutSummaryCardView()
    private lazy var timerView   = WorkoutSummaryTimerView(startButtonAction: #selector(startWorkout),finishButtonAction: #selector(finishWorkout),target: self)
    
    private let customisations = UITextField()
    var timer: Timer?
    private let planTabsView = WorkoutPlanTabsView()
    private lazy var handler: (Setrep) -> Void = { [weak self] setrep in
        self?.goToSetRep(s: setrep)
    }
 
    
    private let genWorkoutButton = workoutDesigns.createStyledButton( title: "+ Workout",
                                                                         titleFontSize: 16,
                                                                         imageSize: 16,
                                                                        systemImageName: "heart.text.clipboard",
                                                                        backgroundColor: .clear,
                                                                        borderColor: .systemBlue,
                                                                        textColor: .systemBlue,

                                                                        width: 25 ,
                                                                        height: 40)
    // define tool bar items
    
    let settingToolbar = WorkoutToolBar.ToolBarItem(
        imageName: "gearshape",
        target: WorkoutAIViewController.self,
        selector: #selector(goToSettings)
    )

    let viewWorkoutToolbar = WorkoutToolBar.ToolBarItem(
        imageName: "dumbbell",
        target: WorkoutAIViewController.self,
        selector: #selector(goToViewWorkout)
    )

    let foodTrackerToolbar = WorkoutToolBar.ToolBarItem(
        imageName: "fork.knife",
        target: WorkoutAIViewController.self,
        selector: #selector(goTofoodtracker)
    )
    
    let toolBar = WorkoutToolBar()
    
    func updateTimer(i_currWorkout:WorkoutSession){
        let latestDate = WorkoutSessionManager.shared.getLastSetRep(i_workout: i_currWorkout)?.finishTime ?? Date()
        timerView.configureTime(i_date: latestDate)
        
    }
    
    @objc func finishWorkout() {
        timer?.invalidate()
        timer = nil // Clear the timer
        
        if let curWorkout = planTabsView.selectedWorkoutSession {
            let newWorkout = curWorkout
            newWorkout.endTime = Date()
            WorkoutSessionManager.shared.updateWorkoutSession(prevWorkout:curWorkout,updatedSession:newWorkout)
        }
        loadViewDatas()
      
    }
    
    //MARK: Button Functions!
    @objc func startWorkout() {
        // Start the timer
        timer?.invalidate() // Invalidate any existing timer
        if let currworkout = planTabsView.selectedWorkoutSession{
            let newWorkout = currworkout
            newWorkout.startTime = Date()
            newWorkout.endTime   = Date()
            WorkoutSessionManager.shared.updateWorkoutSession(prevWorkout:currworkout,updatedSession:newWorkout)
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                self.updateTimer(i_currWorkout: currworkout)
            }

        }else {
            HelperFunctions.showAlert(on: self, title: "No Open Workouts!", message: "Need to Open a workout theres nothing to start!")
        }
        
        
        loadViewDatas()
    
    }
    
    
    @objc func syncWorkout() {
        print("BUTTON TAPPED ✅")
        WorkoutSessionManager.shared.loadWorkoutSessions()
        Task {
            await WorkoutSessionManager.shared.syncworkoutsessionentries()
        }
        
    }
    
    func initObserver(){
        NotificationCenter.default.addObserver(self, selector: #selector(loadViewDatas), name: NSNotification.Name("SetRep"), object: nil)
    }
    @objc func loadViewDatas(){
        planTabsView.configure(i_workoutSessions: WorkoutSessionManager.shared.getOpenWorkouts(),onSetRepSelected: handler)
        
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        initObserver()
        view.backgroundColor = .systemBackground
        view.addSubview(stackScrollView)
        view.addSubview(toolBar)
        stackScrollView.addSubview(stackView)
        stackScrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .fill
        
       
        
        planTabsView.heightAnchor.constraint(equalToConstant: 350).isActive = true
        
        let views = [summaryCard,timerView,genWorkoutButton,planTabsView]
        genWorkoutButton.addTarget(self, action: #selector(goToAddSetVC), for: .touchUpInside)
        
        views.forEach{
            stackView.addArrangedSubview($0)
        }
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        toolBar.configure(toolbarItems: [
            settingToolbar,
            viewWorkoutToolbar,
            foodTrackerToolbar
        ])
        
        
        
        NSLayoutConstraint.activate([
            stackScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackScrollView.bottomAnchor.constraint(equalTo: toolBar.topAnchor),

            toolBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            toolBar.heightAnchor.constraint(equalToConstant: 70),

            stackView.topAnchor.constraint(equalTo: stackScrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: stackScrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: stackScrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: stackScrollView.contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: stackScrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
        loadViewDatas()
      
     
        
        
        
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
