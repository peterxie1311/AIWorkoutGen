import UIKit

class WorkoutsListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    override var prefersHomeIndicatorAutoHidden: Bool {
           return true
       }
    // UI Components
    private let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchData()
        view.backgroundColor = UIColor.systemBackground
        NotificationCenter.default.addObserver(self, selector: #selector(reloadWorkouts), name: NSNotification.Name("workout"), object: nil)
    }
    
    
    
    private func setupUI() {
        title = ""
        //setup table header
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 40))
       // headerView.backgroundColor = .lightGray
        
        let titles = ["Focus","Date","Location"]
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
        
        
        
        // Setup TableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WorkoutListTableViewCell.self, forCellReuseIdentifier: "WorkoutCell")
        
        // Add TableView to the view
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    @objc private func reloadWorkouts() {
        WorkoutSessionManager.shared.loadWorkoutSessions() // Reload data if necessary
        tableView.reloadData()
    }
    
    private func fetchData() {
        tableView.reloadData() // Reload the table view data
    }
    
    // UITableViewDataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return WorkoutSessionManager.shared.workoutSessions.count // Number of workouts
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "WorkoutCell", for: indexPath) as?
                WorkoutListTableViewCell else {
            return UITableViewCell()
        }
        
        let workout = WorkoutSessionManager.shared.workoutSessions[indexPath.row]
        cell.configure(with: workout)
        
       
        
        return cell
    }

    // UITableViewDelegate Method
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let workout = WorkoutSessionManager.shared.workoutSessions[indexPath.row]
        let workoutViewController = WorkoutViewController(workout: workout)
        navigationController?.pushViewController(workoutViewController, animated: true)
        
    }
}

class WorkoutListTableViewCell: UITableViewCell {
    
    let genre        = UILabel()
    let date         = UILabel()
    let location     = UILabel()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let stackView = UIStackView(arrangedSubviews: [genre, date, location ])
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
        [genre, date, location ].forEach {
            $0.textAlignment = .center
            $0.font = UIFont.systemFont(ofSize: 16)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with workout: WorkoutSession) {
        genre.text = workout.workout_genre
        date.text = HelperFunctions.parseDateToStringFull(workout.startTime ?? Date())
        location.text = workout.location
        
        
        
        [genre, date, location].forEach {
                $0.numberOfLines = 0
                $0.lineBreakMode = .byWordWrapping
            }
    }
}
