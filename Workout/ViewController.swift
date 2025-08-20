import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate  {
    
    override var prefersHomeIndicatorAutoHidden: Bool {
           return true
       }
 
    // Setup Constants && Objects ---------------------------------
    
    // labels ------------------------------
    var main_Title: String  = "Person"
    let mainTitleLabel      = UILabel()
    //Gym counter
    var gymcounters         = UIView()
    // test counter
    var restCounter          = workoutDesigns.createLinearProgressBarView(withText: "Rest Timer")
    
    // gym timers
    var gymtimerstring      = ""
    var timercounter        = ""
    var starttimestring     = ""
    var gymtimers           = UIView()
    let startDatePrefic     = "Start Time: "
    
    // rest counter
    //let restTimerPrefix     = "Rest Time: "
  //  var restTimer           = UIView()
    //var restTimerString     = ""
    
    // Buttons --------------------------------------
    var addRepButton        = workoutDesigns.createStyledButton(title: "Generate Workout",
                                                                systemImageName: "plus",
                                                                width: 20,
                                                                height: 40)
    var clearToDoList       = workoutDesigns.createStyledButton(title: "Clear Todo List",
                                                                systemImageName: "trash",
                                                                width: 30,
                                                                height: 40)
    var AddSetRepButton     = workoutDesigns.createStyledButton(title: "Add Set",
                                                                systemImageName: "list.clipboard",
                                                                width: 30,
                                                                height: 40)
    let toolbar = UIToolbar()
    
    // Table View ------------------------------
    let todoList = UITableView()
    let todoCellreuseIdentifier = "todoListCell"
    
    // Commenting out because we are generating our workouts with workoutAIService.Shared.queryGPT
    
    // Timer properties ---
    var timer: Timer?
    var elapsedTime: TimeInterval = 0
    
    // Data ----------------
    var workouts:[Workout]                = WorkoutManager.shared.workouts
    let settings: [Setting]               = SettingsManager.shared.settings
    var workoutSessions: [WorkoutSession] = WorkoutSessionManager.shared.workoutSessions
    var toDoArray:[Setrep]                = SetrepManager.shared.Setreps
    
    //scroll view ----------
    let scrollView  = UIScrollView()
    //let contentView = UIView()
    // replacing contentView with stack view for cleaner UI sorting
    let contentStackView = UIStackView()
    
    //textfield ------
    let workoutcustomisation = UITextField()
    let workout_genre        = UITextField()
    
    // setup stackview
    let stackView  = UIStackView()
    let stackScrollView = UIScrollView()
    var stackcheck = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadViews()
        scrollView.keyboardDismissMode = .interactive // or .onDrag
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: NSNotification.Name("workout"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: NSNotification.Name("SetRep"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: NSNotification.Name("settings"), object: nil)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = contentStackView.bounds.size
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollView.contentSize = contentStackView.bounds.size
    }
    
    @objc private func reload() {
        DispatchQueue.main.async {
            SetrepManager.shared.loadSetreps() // Reload data if necessary
            self.toDoArray = SetrepManager.shared.Setreps
            WorkoutManager.shared.loadWorkout() // Reload data if necessary
            self.workouts = WorkoutManager.shared.workouts
            self.workoutSessions = WorkoutSessionManager.shared.workoutSessions
            self.todoList.reloadData()
            self.updateTodoListVisibility()
//            workoutDesigns.updateLabelText(in: self.restTimer, newText: self.getRestTimerString())
            let gymcounterstring = "#Gym: \(self.workoutSessions.count)\n\(WorkoutSessionManager.shared.checkOpenWorkouts())\n\(WorkoutSessionManager.shared.checkOpenWorkoutsThisWeek())"
            workoutDesigns.updateLabelText(in: self.gymcounters, newText: gymcounterstring)
        }
    }
  
    func loadViews() {
        view.backgroundColor = .systemBackground
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints       = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)
        
        scrollView.isUserInteractionEnabled                        = true
        contentStackView.isUserInteractionEnabled                  = true
       
        addRepButton.isUserInteractionEnabled                      = true
        AddSetRepButton.isUserInteractionEnabled                   = true
        clearToDoList.isUserInteractionEnabled                     = true
        
// Call Functions -------------------------------------------------
        loadConstraints() // it is important that we do load constraints first because we're adding all of our views here
        setupView()
        setuptextfields()
        setupButton()
        setupToolbar(toolbar: toolbar,
                              settingsSelector: #selector(goToSettings),
                              viewWorkoutSelector: #selector(goToViewWorkout),
                              startWorkoutSelector: #selector(startWorkout),
                              finishWorkoutSelector: #selector(finishTimer),
                              gymprogresstracker:#selector(goToProgressTracker))
        setupTodoList()
        setuptextfields()
        setupstackview()
        setupViewConstrains()
        addDoneButtonToKeyboard()
    }

    func setupstackview() {
        stackScrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis                                            = .horizontal // Align horizontally
        stackView.distribution                                    = .fillEqually // Distribute views evenly
        stackView.spacing                                         = 20 // Adjust space between the views
        stackView.translatesAutoresizingMaskIntoConstraints       = false
        
        stackView.addArrangedSubview(gymcounters)
        stackView.addArrangedSubview(gymtimers)
//        stackView.addArrangedSubview(restTimer)
        
        stackcheck = true
        
       // contentStackView.addSubview(stackScrollView)
        stackScrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackScrollView.widthAnchor.constraint(equalTo: contentStackView.widthAnchor),
            stackScrollView.heightAnchor.constraint(equalToConstant: 100),
            stackView.leadingAnchor.constraint(equalTo: stackScrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: stackScrollView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: stackScrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: stackScrollView.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: stackScrollView.heightAnchor),
            stackView.widthAnchor.constraint(equalTo: stackScrollView.widthAnchor) // Make it twice as wide for scrolling
        ])
        
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters = CharacterSet(charactersIn: "0123456789")
        let characterSet = CharacterSet(charactersIn: string)
        return allowedCharacters.isSuperset(of: characterSet)
    }
    
    private func addDoneButtonToKeyboard() {
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
            let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            toolbar.items = [spacer, doneButton]
            workoutcustomisation.inputAccessoryView = toolbar
        }
    
    @objc func dismissKeyboard() {
        print("Swipe gesture detected")
        UIView.animate(withDuration: 0.3) {
               self.view.endEditing(true)
           }
    }
    
    func setuptextfields(){
        workoutcustomisation.placeholder        = "Enter your workout customisations"
//        workoutcustomisation.layer.borderWidth  = 1
//        workoutcustomisation.layer.borderColor  = UIColor.label.cgColor
//        workoutcustomisation.layer.cornerRadius = 10
        
       
        
        workoutcustomisation.translatesAutoresizingMaskIntoConstraints = false
    }
    
    
    func setupTodoList() {
        //setup table header
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 40))
        
        let titles = ["Workout", "QTY", "Kgs", "Status"]
        let headerStackView = UIStackView()
        headerStackView.axis = .horizontal
        headerStackView.distribution = .fillEqually
        headerStackView.alignment = .center
        headerStackView.spacing = 10
        
        for title in titles {
            let label = UILabel()
            label.text = title
            label.textAlignment = .center
            label.font = UIFont.boldSystemFont(ofSize: 16)
            label.textColor = .systemBlue
            headerStackView.addArrangedSubview(label)
        }
        
        headerView.addSubview(headerStackView)
        headerStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerStackView.topAnchor.constraint(equalTo: headerView.topAnchor),
            headerStackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10),
            headerStackView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -10),
            headerStackView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])
        
        todoList.tableHeaderView = headerView
        
        // Setup
        todoList.register(TodoListCell.self, forCellReuseIdentifier: "todoListCell")
        todoList.delegate = self
        todoList.dataSource = self
        todoList.translatesAutoresizingMaskIntoConstraints = false
        todoList.heightAnchor.constraint(equalToConstant: 400).isActive = true
        todoList.register(TodoListCell.self, forCellReuseIdentifier: "TodoListCell")

        if toDoArray.isEmpty {
            todoList.isHidden = true
        } else {
            todoList.isHidden = false
            todoList.reloadData()
        }
    }
  
    

    
    func setupButton() {
        // Auto Layout constraints (if needed)
        addRepButton.translatesAutoresizingMaskIntoConstraints = false
        addRepButton.addTarget(self, action: #selector(addRep), for: .touchUpInside)
        
        AddSetRepButton.translatesAutoresizingMaskIntoConstraints = false
        AddSetRepButton.addTarget(self, action: #selector(goToAddSetVC), for: .touchUpInside)
        
        // clear to do list array
        clearToDoList.setTitle("Clear List", for: .normal)
        clearToDoList.addTarget(self, action: #selector(clearRep), for: .touchUpInside)
        clearToDoList.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func setupView() {
        if let setting = SettingsManager.shared.getSetting(name: "Name") {
            main_Title = setting.value ?? "Person"
        }
        
        mainTitleLabel.text = main_Title
        mainTitleLabel.font = UIFont.boldSystemFont(ofSize: 34)
        mainTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let gymcounterstring = "#Gym: \(self.workoutSessions.count)\n\(WorkoutSessionManager.shared.checkOpenWorkouts())\n\(WorkoutSessionManager.shared.checkOpenWorkoutsThisWeek())"
        //need to implement update of gym counters
        gymcounters = workoutDesigns.createRoundedSquareView(withText: gymcounterstring)
        gymcounters.translatesAutoresizingMaskIntoConstraints = false
        
        if WorkoutSessionManager.shared.getWorkoutSession() !== nil {
            continueWorkout()
        }
        else{
            timercounter = "Time Elapsed: 0 Mins"
        }
        
        if gymtimerstring == "" { // this is the value when first initialised
            
            if let startTime = WorkoutSessionManager.shared.getWorkoutSession()?.startTime {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                let timeString = timeFormatter.string(from: startTime)
                starttimestring = startDatePrefic + timeString + "\n"
                gymtimerstring = starttimestring + timercounter
            } else {
                 gymtimerstring = startDatePrefic 
            }
            
            
            gymtimers = workoutDesigns.createRoundedSquareView(withText: gymtimerstring)
            gymtimers.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    

    func setupViewConstrains() {
        NSLayoutConstraint.activate([
            // Scroll View Constraints
            scrollView.leadingAnchor.constraint (equalTo: view.leadingAnchor,constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: -16),
            scrollView.topAnchor.constraint     (equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint  (equalTo: toolbar.topAnchor), // Adjusted to avoid overlapping

            // Content View Constraints
            contentStackView.leadingAnchor.constraint (equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStackView.topAnchor.constraint     (equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStackView.bottomAnchor.constraint  (equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStackView.widthAnchor.constraint   (equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        // Ensure the content view is at least as tall as the scroll view
        let heightConstraint = contentStackView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor)
        heightConstraint.priority = .defaultLow
        heightConstraint.isActive = true
    }

    
    func loadConstraints() {
        let viewsToAdd = [mainTitleLabel,stackScrollView,restCounter,workoutcustomisation,addRepButton,AddSetRepButton,clearToDoList,todoList] //make sure to add all elements to this array otherwise they wont get added
        
        for view in viewsToAdd {
            contentStackView.addArrangedSubview(view)
        }
        contentStackView.axis                                      = .vertical
        contentStackView.spacing                                   = 10
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
    }


    @objc func startWorkout() {
        // Start the timer
        elapsedTime = 0
        //gymtimerstring = "Time Elapsed: \(elapsedTime) seconds\n" // Reset label text
        timer?.invalidate() // Invalidate any existing timer
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        
        WorkoutSessionManager.shared.addWorkoutSession(durationHrs: 0, endTime: Date(), location: "", startTime: Date(), sets: [])
        if let startTime = WorkoutSessionManager.shared.getWorkoutSession()?.startTime {
            starttimestring = startDatePrefic + HelperFunctions.parseDateToStringTime(startTime) + "\n"
            gymtimerstring = starttimestring + timercounter
            workoutDesigns.updateLabelText(in: gymtimers, newText: gymtimerstring)
//            workoutDesigns.updateLabelText(in: restTimer, newText: getRestTimerString())
            workoutDesigns.updateLabelText(in: gymcounters, newText: "#Gym: \(workoutSessions.count)\n\(WorkoutSessionManager.shared.checkOpenWorkouts())")
        } else {
            gymtimerstring = startDatePrefic
        }
    }
    
    @objc func continueWorkout() {
        timer?.invalidate() // Invalidate any existing timer
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
   //This is for the addRep Button ----------------
    @objc func addRep(){
        let customisations = workoutcustomisation.text ?? ""
        let excludeWorkouts = SettingsManager.shared.getSetting(name: "Exclude Workout")?.value ?? ""
//        var workoutstring = "Generate me a workout for strength based training in JSON format within a flat array where we have the columns workoutname, setqty and repqty. "
//        
//        if customisations != "" {
//            workoutstring += "This is my goal for this gym session: [\(customisations)]. "
//        }
//        if excludeWorkouts != "" {
//            workoutstring += "Exlude the following workouts:[\(excludeWorkouts)] "
//        }
//        workoutstring += """
//                              This is previous workout data sent in JSON
//                              Field meanings:
//                              - "w": workout name
//                              - "o": overall workout
//                              - "r": rep quantity
//                              - "s": set quantity
//                              - "wt": weight in kg
//                              - "d": date
//                              """
        
        // Step 1: Sort sessions by date descending
        let sortedSessions = WorkoutSessionManager.shared.workoutSessions.sorted {
            ($0.startTime ?? Date.distantPast) > ($1.startTime ?? Date.distantPast)
        }

        // Step 2: Flatten all Setreps
        var allSetreps: [(setrep: Setrep, sessionDate: Date,workout_genre:String?)] = []

        for session in sortedSessions {
            let reps = (session.setrep?.allObjects as? [Setrep]) ?? []
            for setrep in reps {
                allSetreps.append((setrep, session.startTime ?? Date(),session.workout_genre))
            }
        }

        // Step 3: Take the first 100 most recent reps
        let latestSetreps = allSetreps.prefix(120)

        // Step 4: Build JSON string
        var jsonWorkoutData = "[\n"
        for (setrep, sessionDate,workout_genre) in latestSetreps {
            let entry = """
              {
                "w": "\(setrep.workoutName ?? "unknown")",
                "o": \(workout_genre ?? " "),
                "r": \(setrep.rep_qty),
                "wt": \(setrep.weight),
                "d": "\(HelperFunctions.parseDateToString(sessionDate))"
              },
            """
            jsonWorkoutData += entry + "\n"
        }
        jsonWorkoutData += "]"

//        // Now append to workoutstring
//        workoutstring += "\n" + jsonWorkoutData + "\n"
        
        var workoutstring = """
        You are a fitness AI that creates optimized strength training plans.

        Return ONLY a JSON array, no extra text, no explanations.

        Rules:
        - Format: [{"workoutname": String, "setqty": Int, "repqty": Int}]
        - Use camelCase for keys.
        - setqty = number of sets
        - repqty = number of reps per set
        - Only strength-based exercises.
        - Avoid any exercises in the exclusion list.
        - Avoid repeating muscle groups already trained in the last 7 days (based on history data).
        - Ensure workout is balanced and realistic for a single session.
        - Target muscles not yet trained this week, unless customizations say otherwise.
        - Provide between 5 and 8 exercises.

        Customization: \(customisations.isEmpty ? "None" : customisations)
        Exclude Workouts: \(excludeWorkouts.isEmpty ? "None" : excludeWorkouts)

        Workout history JSON (last 120 sets):
        This is previous workout data sent in JSON
        Field meanings:
            - "w": workout name
            - "o": overall workout
            - "r": rep quantity
            - "s": set quantity
            - "wt": weight in kg
            - "d": date
        \(jsonWorkoutData)
        """

       
        let messages = [
            ["role": "system", "content": "You are a helpful fitness assistant who responds ONLY in JSON."],
            ["role": "user", "content": workoutstring]
               ]
        
               workoutAIservice.shared.queryChatGPT(messages: messages) { result in
                   DispatchQueue.main.async {
                       switch result {
                       case .success(let response):
                           print("Response: \(response)")
                           self.todoList.reloadData()
                       case .failure(let error):
                           HelperFunctions.showAlert(on: self, title: "Failed to add workout!", message: "Error: \(error.localizedDescription)")
                       }
                   }
               }
        
        if let tmpSession = WorkoutSessionManager.shared.getFirstOpenGymSesh() {
            tmpSession.workout_genre = customisations
            WorkoutSessionManager.shared.updateWorkoutSession(prevWorkout: tmpSession, updatedSession: tmpSession)
        } else {
            startWorkout() // if workout has not been started just start one
            if let tmpSession = WorkoutSessionManager.shared.getFirstOpenGymSesh() {
                tmpSession.workout_genre = customisations
                WorkoutSessionManager.shared.updateWorkoutSession(prevWorkout: tmpSession, updatedSession: tmpSession)
            }
        }
    }
    
    @objc func clearRep(){
        SetrepManager.shared.clearSetreps()
        updateTodoListVisibility()
        todoList.reloadData()
    }
    
    @objc func clearWorkoutSessions(){
        WorkoutSessionManager.shared.clearWorkoutsessions()
        updateTodoListVisibility()
        todoList.reloadData()
    }
    

    func updateTodoListVisibility() {
        if toDoArray.isEmpty {
            todoList.isHidden = true
        } else {
            todoList.isHidden = false
            todoList.reloadData()
        }
    }
    

    // This is for the finish button ----------------
    @objc func finishTimer() {
        timer?.invalidate()
        timer = nil // Clear the timer
        let mins = elapsedTime / 60
        if let currentWorkout = WorkoutSessionManager.shared.getWorkoutSession(){
            let newWorkout = currentWorkout
            newWorkout.endTime = Date()
            newWorkout.duration_hrs = Float(mins)
            var finishedSets:[Setrep] = []
            for set in toDoArray{
                if set.completed == true{
                    finishedSets.append(set)
                    set.workoutSession = newWorkout
                }
            }
            newWorkout.setrep = NSSet(array: finishedSets)
            WorkoutSessionManager.shared.updateWorkoutSession(prevWorkout:currentWorkout,updatedSession:newWorkout)
            timercounter = "Total: \(String(format: "%.2f", mins)) mins \n"
           gymtimerstring = starttimestring + timercounter
        
            workoutDesigns.updateLabelText(in: gymtimers, newText: gymtimerstring)
//            workoutDesigns.updateLabelText(in: restTimer, newText: getRestTimerString())
            SetrepManager.shared.clearSetreps()
            print(SetrepManager.shared.Setreps.count)
            reload()
        }
      
    }


    @objc func updateTimer() {
        if let startTime = WorkoutSessionManager.shared.getWorkoutSession()?.startTime {
            let timeDifference = Date().timeIntervalSince(startTime) // time in seconds
            let minutes = round(timeDifference / 60.0) // convert seconds to minutes
            elapsedTime = timeDifference
            timercounter = "Time: \(minutes) mins" // Update the label with the new elapsed
            gymtimerstring = starttimestring + timercounter
            workoutDesigns.updateLabelText(in: gymtimers, newText: gymtimerstring)
        }
        else{
            print("FAILED TO START TIME!")
        }
    }
    
    // go to viewcontroller
    @objc func goToSettings() {
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    @objc func goToViewWorkout() {
        let viewWorkoutVC = WorkoutsListViewController()
        navigationController?.pushViewController(viewWorkoutVC, animated: true)
    }
    
    @objc func goToProgressTracker() {
        let viewWorkoutVC = WorkoutTreeViewController();
        navigationController?.pushViewController(viewWorkoutVC, animated: true)
    }
    
    @objc func goToAddSetVC() {
        if let tmpSession = WorkoutSessionManager.shared.getFirstOpenGymSesh() {
            let AddSetVC = AddSetViewController(workout: tmpSession )
            navigationController?.pushViewController(AddSetVC, animated: true)
        }
        else {
            HelperFunctions.showAlert(on: self, title: "Error", message: "Please Start a workout")
        }
    }
    
    // table designs
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toDoArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: todoCellreuseIdentifier, for: indexPath) as! TodoListCell
        let item = toDoArray[indexPath.row]
        cell.configure(with: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
          tableView.deselectRow(at: indexPath, animated: true)
          let selectedItem = toDoArray[indexPath.row]
          let detailViewController = RepViewController(rep: selectedItem)
          navigationController?.pushViewController(detailViewController, animated: true)
      }

    
}

// cell class for the table

class TodoListCell: UITableViewCell {
    let workoutLabel = UILabel()
    let qtyLabel = UILabel()
    let kgsLabel = UILabel()
    let status = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let stackView = UIStackView(arrangedSubviews: [workoutLabel, qtyLabel, kgsLabel, status])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.spacing = 10
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5)
        ])
        
        // Style Labels
        [workoutLabel, qtyLabel, kgsLabel].forEach {
            $0.textAlignment = .center
            $0.font = UIFont.systemFont(ofSize: 16)
        }
        
        status.contentMode = .scaleAspectFit

        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with setrep: Setrep) {
        workoutLabel.text = setrep.workoutName
        qtyLabel.text = String(setrep.rep_qty)
        kgsLabel.text = String(setrep.weight)
        
        let isCompleted = setrep.completed // Assuming `isCompleted` is a property of `Setrep`
                if isCompleted {
                    status.image = UIImage(systemName: "checkmark.circle") // Checkmark icon
                    status.tintColor = .systemGreen
                } else {
                    status.image = UIImage(systemName: "x.circle") // "X" icon
                    status.tintColor = .systemRed
                }
        
        
        [workoutLabel, qtyLabel, kgsLabel].forEach {
                $0.numberOfLines = 0
                $0.lineBreakMode = .byWordWrapping
            }
    }

}


