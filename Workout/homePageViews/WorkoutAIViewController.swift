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
 
    
    private let genWorkoutButton = workoutDesigns.createStyledButton( title: "Create workout",
                                                                         titleFontSize: 16,
                                                                         imageSize: 16,
                                                                        systemImageName: "heart.text.clipboard",
                                                                        backgroundColor: WorkoutTheme.accent,
                                                                        borderColor: WorkoutTheme.accent,
                                                                        textColor: WorkoutTheme.onAccent,

                                                                        width: 25 ,
                                                                        height: 40)
    lazy var settingToolbar = WorkoutToolBar.ToolBarItem(
        imageName: "gearshape",
        target: self,
        selector: #selector(goToSettings)
    )

    lazy var viewWorkoutToolbar = WorkoutToolBar.ToolBarItem(
        imageName: "dumbbell",
        target: self,
        selector: #selector(goToViewWorkout)
    )

    lazy var foodTrackerToolbar = WorkoutToolBar.ToolBarItem(
        imageName: "fork.knife",
        target: self,
        selector: #selector(goTofoodtracker)
    )
    
    let toolBar = WorkoutToolBar()
    
    func updateTimer(i_currWorkout:WorkoutSession){
        let latestDate = WorkoutSessionManager.shared.getLastSetRep(i_workout: i_currWorkout)?.finishTime ?? Date()
        let totalRestTime = WorkoutSessionManager.shared.getTotalRestTime(i_workout: i_currWorkout)
        timerView.configureTime(i_date: latestDate)
        self.summaryCard.updateTimers(i_startDate: i_currWorkout.startTime ?? Date(), i_restTime: Int(i_currWorkout.rest_duration),i_totalRestTimeSec: totalRestTime)
        
    }
    
    func updateViews(ws:WorkoutSession) {
        
        // Start the timer
        timer?.invalidate() // Invalidate any existing timer
        if ws.startTime != ws.endTime{
            timerView.configureRestTimeDur(i_timeinterval: TimeInterval(ws.rest_duration))
            //            summaryCard.updateTimers(i_startDate: Date(), i_totalRestTimeSec: newWorkout.rest_duration)
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                self.updateTimer(i_currWorkout: ws)
                
            }
            loadViewDatas()
        }
    }
    
    @objc func finishWorkout() {
        timer?.invalidate()
        timer = nil // Clear the timer
        
        if let curWorkout = planTabsView.selectedWorkoutSession {
            let newWorkout = curWorkout
            newWorkout.endTime = Date()
            newWorkout.isComplete = true
            let minutes = newWorkout.endTime!.timeIntervalSince(curWorkout.startTime!) / 60
            newWorkout.duration_hrs = Float(minutes / 60)
            Task {
                await WorkoutSessionManager.shared.updateWorkoutSession(prevWorkout:curWorkout,updatedSession:newWorkout)
            }
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
           // newWorkout.endTime   = Date()
            Task {
                await WorkoutSessionManager.shared.updateWorkoutSession(prevWorkout:currworkout,updatedSession:newWorkout)
            }
            timerView.configureRestTimeDur(i_timeinterval: TimeInterval(newWorkout.rest_duration))
//            summaryCard.updateTimers(i_startDate: Date(), i_totalRestTimeSec: newWorkout.rest_duration)
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                self.updateTimer(i_currWorkout: newWorkout)
          
            }

        }else {
            HelperFunctions.showAlert(on: self, title: "No Open Workouts!", message: "Need to Open a workout theres nothing to start!")
        }
        
        
        loadViewDatas()
    
    }
    
    
    
    @objc func loadViewDatas(){
        WorkoutSessionManager.shared.loadWorkoutSessions()
        self.planTabsView.configure(i_workoutSessions: WorkoutSessionManager.shared.getOpenWorkouts(),i_onSetRepSelected: self.handler, i_onTabSelectedFunc: { [weak self] workout in
            self?.updateViews(ws: workout)
        })
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadViewDatas()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
      //  initObserver()
        title = "Train"
        navigationItem.backButtonTitle = "Back"
        view.backgroundColor = WorkoutTheme.background
        stackScrollView.showsVerticalScrollIndicator = false
        view.addSubview(stackScrollView)
        view.addSubview(toolBar)
        stackScrollView.addSubview(stackView)
        stackScrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.distribution = .fill
        
       
        
        planTabsView.heightAnchor.constraint(greaterThanOrEqualToConstant: 350).isActive = true
        
        let intro = WorkoutTheme.section("Make every rep count", subtitle: "Your training, at your pace.")
        let planHeading = WorkoutTheme.section("Your plan", subtitle: "Choose a session to see your exercises.")
        let views: [UIView] = [intro, summaryCard, timerView, planHeading, genWorkoutButton, planTabsView]
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
            toolBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolBar.heightAnchor.constraint(equalToConstant: 64),

            stackView.topAnchor.constraint(equalTo: stackScrollView.contentLayoutGuide.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: stackScrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: stackScrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: stackScrollView.contentLayoutGuide.bottomAnchor, constant: -24),
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

