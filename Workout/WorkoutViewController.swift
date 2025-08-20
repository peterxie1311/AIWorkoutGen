import UIKit
import AVKit

class WorkoutViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    override var prefersHomeIndicatorAutoHidden: Bool {
           return true
       }
    
    // Properties
    let startTime:Date?
    let location:String?
    let workoutGenre:String?
    let id:UUID?
    let endTime:Date?
    let duration_hrs:Float
    let setreps:[Setrep]
    let WorkoutSession:WorkoutSession
    
    // UI Components
    private let startimelabel = UILabel()
    private let locationlabel = UILabel()
    private let workoutLabel  = UILabel()
    private let endtimelabel  = UILabel()
    private let durationlabel = UILabel()
    private var deleteButton  = workoutDesigns.createStyledButton(title: "Delete Sesh",
                                                                  systemImageName: "trash",
                                                                  width: 20,
                                                                  height: 30)
    private var excludeButton = workoutDesigns.createStyledButton(title: "Exclude Workout",
                                                                  systemImageName: "nosign",
                                                                  width: 20,
                                                                  height: 30) 
    private var AddSetRep     = workoutDesigns.createStyledButton(title: "Add Set",
                                                                  systemImageName: "plus",
                                                                  width: 20,
                                                                  height: 30)
    
    //table
    private let tableView = UITableView()
    
    // views
    private let scrollView = UIScrollView()
    
    
    // Initializer
    init(workout:WorkoutSession) {
        self.WorkoutSession = workout
        self.startTime      = workout.startTime
        self.location       = workout.location
        self.id             = workout.id
        self.endTime        = workout.endTime
        self.workoutGenre   = workout.workout_genre
        self.duration_hrs   = workout.duration_hrs
        self.setreps        = (workout.setrep?.allObjects as? [Setrep]) ?? []
        super.init(nibName: nil, bundle: nil)
    }
    
    @objc private func removeWorkout(){
        WorkoutSessionManager.shared.removeWorkoutSession(workoutid: self.id ?? UUID())
        guard self.id != nil else {
                print("Workout ID is nil")
                return
            }
           
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func excludeWorkout() {
        if let exclWOSetting = SettingsManager.shared.getSetting(name: "Exclude Workout") {
            let sName = exclWOSetting.settingName
            var exclString = ""
            
            var distinctWorkoutNames = Set<String>()
            for setrep in setreps {
                if let workoutName = setrep.workoutName, !workoutName.isEmpty {
                    distinctWorkoutNames.insert(workoutName)
                }
            }
            exclString = distinctWorkoutNames.joined(separator: ",")
            SettingsManager.shared.updateSetting(name: sName ?? "", newValue: exclString)
        } else {
            // Initialize settings and call the function again if setting doesn't exist
            SettingsManager.shared.initSettings()
            excludeWorkout()
        }
    }

    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        NotificationCenter.default.addObserver(self, selector: #selector(tableView.reloadData), name: NSNotification.Name("SetRep"), object: nil)
        setupUI()
        setupData()
    }
    
    @objc private func reload(){
        tableView.reloadData()
    }
    
    private func setupUI() {
        //setup table header
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 40))
       // headerView.backgroundColor = .lightGray
        
        let titles = ["Workout", "QTY", "Kgs", "Sec"]
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
        
        tableView.tableHeaderView = headerView
        
        
        // setup table
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WorkoutTableViewCell.self, forCellReuseIdentifier: "WorkoutCell")
        
        // Setup UI Components
        startimelabel.font = UIFont.systemFont(ofSize: 18)
        endtimelabel.font  = UIFont.systemFont(ofSize: 18)
        locationlabel.font = UIFont.systemFont(ofSize: 18)
       // endtimelabel.font = UIFont.systemFont(ofSize: 18)
        durationlabel.font = UIFont.systemFont(ofSize: 18)
        workoutLabel.font  = UIFont.systemFont(ofSize: 18)
        
        // Configure Description TextView
        deleteButton.setTitle("Delete Workout", for: .normal)
        deleteButton.addTarget(self, action: #selector(removeWorkout), for: .touchUpInside)
        
        AddSetRep.addTarget(self, action: #selector(goToAddSetVC), for: .touchUpInside)
        
        excludeButton.setTitle("Exclude Workout", for: .normal)
        excludeButton.addTarget(self, action: #selector(excludeWorkout), for: .touchUpInside)
        
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        
        NSLayoutConstraint.activate([
              scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
              scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
              scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
              scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
          ])
        
        // Add Subviews and Set Constraints
        // Add stackView inside scrollView
        let stackView = UIStackView(arrangedSubviews: [
            workoutLabel, startimelabel, locationlabel,
            endtimelabel, durationlabel, deleteButton,
            excludeButton, AddSetRep, tableView
        ])
        
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
        
//        deleteButton = workoutDesigns.createStyledButton(title: "Delete Sesh",
//                                                         width: stackView.frame.width,
//                                                         height: 100)
//        excludeButton =
//        AddSetRep    = 
        
            
        tableView.heightAnchor.constraint(equalToConstant: 400).isActive = true
            

    }
    
    // UITableViewDataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.setreps.count  // Number of workouts
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "WorkoutCell", for: indexPath) as? WorkoutTableViewCell else {
            return UITableViewCell()
        }
        
        let workout = self.setreps[indexPath.row]
        cell.configure(with: workout)
        
        return cell
    }
    
    @objc func goToAddSetVC() {
       
            let AddSetVC = AddSetViewController(workout: WorkoutSession )
            navigationController?.pushViewController(AddSetVC, animated: true)
       
    }
    
    private func setupData() {
        print(self.setreps.count)
        startimelabel.text = "Start Time: " + HelperFunctions.parseDateToStringFull(startTime!)
        endtimelabel.text  = "Finish Time: " + HelperFunctions.parseDateToStringFull(endTime!)
        locationlabel.text = "Location: " + (self.location ?? "")
        durationlabel.text = "Duration (mins): " + String(self.duration_hrs)
        workoutLabel.text =  "Workout: \(self.workoutGenre ?? "")"
        
    }
    
}

class WorkoutTableViewCell: UITableViewCell {
    
    let workoutLabel = UILabel()
    let qtyLabel = UILabel()
    let kgsLabel = UILabel()
    let secLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let stackView = UIStackView(arrangedSubviews: [workoutLabel, qtyLabel, kgsLabel, secLabel])
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
        [workoutLabel, qtyLabel, kgsLabel, secLabel].forEach {
            $0.textAlignment = .center
            $0.font = UIFont.systemFont(ofSize: 16)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with setrep: Setrep) {
        workoutLabel.text = setrep.workoutName
        qtyLabel.text = String(setrep.rep_qty)
        kgsLabel.text = String(setrep.weight)
        secLabel.text = String(format: "%.2f",setrep.duration_sec)
        
        
        [workoutLabel, qtyLabel, kgsLabel, secLabel].forEach {
                $0.numberOfLines = 0
                $0.lineBreakMode = .byWordWrapping
            }
    }
}
