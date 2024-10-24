import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate  {
 
 
    // Setup Constants && Objects ---------------------------------
    
    // labels ------------------------------
    var main_Title: String  = "Person"
    let mainTitleLabel      = UILabel()
    //Gym counter
    var gymcounters         = UIView()
    
    // gym timers
    var gymtimerstring      = ""
    var timercounter        = ""
    var starttimestring     = ""
    var gymtimers           = UIView()
    let startDatePrefic     = "Start Time: "
    
    // rest counter
    let restTimerPrefix     = "Rest Time: "
    var restTimer           = UIView()
    var restTimerString     = ""
    
    
    
    
    // Buttons --------------------------------------
    let addRepButton        = workoutDesigns.createStyledButton(title: "Generate Workout")
    let clearToDoList       = workoutDesigns.createStyledButton(title: "Clear Todo List")
    let AddSetRepButton     = workoutDesigns.createStyledButton(title: "Add Set")
    
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
    let contentView = UIView()
    
    //textfield ------
    let workoutcustomisation = UITextField()
    let workout_genre        = UITextField()
    
    
    // setup stackview
    let stackView  = UIStackView()
    let stackScrollView = UIScrollView()
    var stackcheck = false
    
    //PieChart ----------
    //let workoutchart = PieChartView()
    
   
    
    
   
    

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
        scrollView.contentSize = contentView.bounds.size
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollView.contentSize = contentView.bounds.size
    }
    
    private func setupToolbar() {
        view.addSubview(toolbar)

        toolbar.layer.cornerRadius = 20
        toolbar.layer.masksToBounds = true
        toolbar.backgroundColor = .systemGray6
        toolbar.layer.shadowColor = UIColor.black.cgColor
        toolbar.layer.shadowOpacity = 0.1
        toolbar.layer.shadowOffset = CGSize(width: 0, height: 2)
        toolbar.layer.shadowRadius = 4
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        let settingsButton = createCustomButton(imageName: "gearshape", action: #selector(goToSettings))
        let viewWorkoutButton = createCustomButton(imageName: "dumbbell", action: #selector(goToViewWorkout))
        let startWorkoutButton = createCustomButton(imageName: "play", action: #selector(startWorkout))
        let finishWorkoutButton = createCustomButton(imageName: "stop", action: #selector(finishTimer))

        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        toolbar.items = [
            flexibleSpace, settingsButton,
            flexibleSpace, viewWorkoutButton,
            flexibleSpace, startWorkoutButton,
            flexibleSpace, finishWorkoutButton,
            flexibleSpace
        ]


        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            toolbar.heightAnchor.constraint(equalToConstant: 55)
        ])
    }

    private func createCustomButton(imageName: String, action: Selector) -> UIBarButtonItem {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: imageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 25)), for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return UIBarButtonItem(customView: button)
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
            workoutDesigns.updateLabelText(in: self.restTimer, newText: self.getRestTimerString())
            let gymcounterstring = "#Gym: \(self.workoutSessions.count)\n\(WorkoutSessionManager.shared.checkOpenWorkouts())\n\(WorkoutSessionManager.shared.checkOpenWorkoutsThisWeek())"
            workoutDesigns.updateLabelText(in: self.gymcounters, newText: gymcounterstring)
        }
    }
  
    
    
    func loadViews() {
        view.backgroundColor = .systemBackground
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints  = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        scrollView.isUserInteractionEnabled                = true
        contentView.isUserInteractionEnabled               = true
       
        addRepButton.isUserInteractionEnabled              = true
        AddSetRepButton.isUserInteractionEnabled           = true
        clearToDoList.isUserInteractionEnabled             = true
        
// Call Functions -------------------------------------------------
        
        setupView()
        setuptextfields()
        setupButton()
        setupToolbar()
        setupTodoList()
        setuptextfields()
        setupstackview()
        loadConstraints()
        setupViewConstrains()
        addDoneButtonToKeyboard()
        
        
    }

    func setupstackview() {
        stackScrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal // Align horizontally
        stackView.distribution = .fillEqually // Distribute views evenly
        stackView.spacing = 20 // Adjust space between the views
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.addArrangedSubview(gymcounters)
        stackView.addArrangedSubview(gymtimers)
        stackView.addArrangedSubview(restTimer)
        stackcheck = true
        
        contentView.addSubview(stackScrollView)
        stackScrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackScrollView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            stackScrollView.heightAnchor.constraint(equalToConstant: 100),
            stackView.leadingAnchor.constraint(equalTo: stackScrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: stackScrollView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: stackScrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: stackScrollView.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: stackScrollView.heightAnchor),
            stackView.widthAnchor.constraint(equalTo: stackScrollView.widthAnchor, multiplier: 2) // Make it twice as wide for scrolling
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
        workoutcustomisation.placeholder = "Enter your workout customisations"
        workoutcustomisation.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(workoutcustomisation)
    }
    
    
    func setupTodoList() {
        contentView.addSubview(todoList)
        // header
        
        //setup table header
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 40))
       // headerView.backgroundColor = .lightGray
        
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
        
        contentView.addSubview(AddSetRepButton)
        contentView.addSubview(addRepButton)
        // clear to do list array
        clearToDoList.setTitle("Clear List", for: .normal)
        clearToDoList.addTarget(self, action: #selector(clearRep), for: .touchUpInside)
        clearToDoList.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(clearToDoList)
        
    }
    
    func setupView() {
        if let setting = SettingsManager.shared.getSetting(name: "Name") {
            main_Title = setting.value ?? "Person"
        }
        
        mainTitleLabel.text = main_Title
        mainTitleLabel.font = UIFont.boldSystemFont(ofSize: 34)
        mainTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainTitleLabel)
        

        
        let gymcounterstring = "#Gym: \(self.workoutSessions.count)\n\(WorkoutSessionManager.shared.checkOpenWorkouts())\n\(WorkoutSessionManager.shared.checkOpenWorkoutsThisWeek())"
        //workoutDesigns.updateLabelText(in: gymcounters, newText: gymcounterstring)
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
            
            print(gymtimerstring)
            
            gymtimers = workoutDesigns.createRoundedSquareView(withText: gymtimerstring)
            gymtimers.translatesAutoresizingMaskIntoConstraints = false
           // contentView.addSubview(gymtimers)
        }
        if restTimerString == "" {
            restTimer = workoutDesigns.createRoundedSquareView(withText: getRestTimerString())
            restTimer.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    func getRestTimerString()->String{
       var restTimeString = ""
        
        if SetrepManager.shared.toDoHasCompletedSetRep() == true {
            let latestSetRep = SetrepManager.shared.getLatestSetRep(setrepArray: SetrepManager.shared.Setreps)
            let restTime     = latestSetRep.finishTime?.timeIntervalSinceNow ?? 0
            restTimeString  = restTimerPrefix + "\(round(-restTime))"
            print("Rest Timer string! \(restTimeString)")
        }
        else {
            restTimeString  = restTimerPrefix + "0"
        }
        
        return restTimeString
    }
    
    func setupViewConstrains() {
        NSLayoutConstraint.activate([
            // Scroll View Constraints
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: toolbar.topAnchor), // Adjusted to avoid overlapping

            // Content View Constraints
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        // Ensure the content view is at least as tall as the scroll view
        let heightConstraint = contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor)
        heightConstraint.priority = .defaultLow
        heightConstraint.isActive = true
    }

    
    func loadConstraints() {
        NSLayoutConstraint.activate([
            // Constraints for mainTitleLabel
            mainTitleLabel.centerXAnchor.constraint(equalTo: contentView .centerXAnchor),
            mainTitleLabel.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 20),
            
            stackScrollView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackScrollView.topAnchor.constraint(equalTo: mainTitleLabel.bottomAnchor, constant: 40),

            
            
            
            // Constraints for workoutcustomisation
            workoutcustomisation.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            workoutcustomisation.topAnchor.constraint(equalTo: stackScrollView.bottomAnchor, constant: 20), // Increase space
            
            // Constraints for addRepButton
            addRepButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            addRepButton.topAnchor.constraint(equalTo: workoutcustomisation.bottomAnchor, constant: 20), // Increase space
            
            // Constraints for addRepButton
            AddSetRepButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            AddSetRepButton.topAnchor.constraint(equalTo: addRepButton.bottomAnchor, constant: 20), // Increase space
            
            // Constraints for clearToDoList
            clearToDoList.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            clearToDoList.topAnchor.constraint(equalTo: AddSetRepButton.bottomAnchor, constant: 20), // Increase space
            
            // Constraints for todoList
            todoList.topAnchor.constraint(equalTo: clearToDoList.bottomAnchor, constant: 20), // Move todoList down further
            todoList.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            todoList.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            todoList.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
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
            workoutDesigns.updateLabelText(in: restTimer, newText: getRestTimerString())
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
        var workoutstring = "Generate me a workout for strength based training in JSON format within a flat array where we have the columns workoutname, setqty and repqty."
        
        if customisations != "" {
            workoutstring += "Here are some workout customisations: [\(customisations)]."
        }
        if excludeWorkouts != "" {
            workoutstring += "Exlude the following workouts:[\(excludeWorkouts)]"
        }

        let messages = [
            ["role": "system", "content": workoutstring]
               ]

               workoutAIservice.shared.queryChatGPT(messages: messages) { result in
                   DispatchQueue.main.async {
                       switch result {
                       case .success(let response):
                           print("Response: \(response)")
                           self.todoList.reloadData()
                       case .failure(let error):
                           print("Error: \(error.localizedDescription)")
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
            workoutDesigns.updateLabelText(in: restTimer, newText: getRestTimerString())
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
            workoutDesigns.updateLabelText(in: restTimer, newText: getRestTimerString())
        }
        else{
            print("FAILED TO START TIME!")
        }
    }

    @objc func goToSettings() {
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    @objc func goToAddWorkout() {
        let addWorkoutVC = Piechartviewcontroller()
        navigationController?.pushViewController(addWorkoutVC, animated: true)
    }
    
    @objc func goToViewWorkout() {
        let viewWorkoutVC = WorkoutsListViewController()
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


