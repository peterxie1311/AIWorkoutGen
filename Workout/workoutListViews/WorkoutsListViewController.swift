import UIKit

class WorkoutsListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    override var prefersHomeIndicatorAutoHidden: Bool {
           return true
       }
    // UI Components
    private let tableView = UITableView()
    var sortedWorkouts: [WorkoutSession] {
        WorkoutSessionManager.shared.workoutSessions.sorted {
            ($0.endTime ?? .distantPast) > ($1.endTime ?? .distantPast)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchData()
        view.backgroundColor = UIColor.systemBackground
        NotificationCenter.default.addObserver(self, selector: #selector(reloadWorkouts), name: NSNotification.Name("workout"), object: nil)
    }
    
    
    
    private func setupUI() {
        
        // Setup TableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WorkoutListTableViewCell.self, forCellReuseIdentifier: "WorkoutCell")
        tableView.separatorStyle = .none
        
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
        return sortedWorkouts.count // Number of workouts
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "WorkoutCell", for: indexPath) as?
                WorkoutListTableViewCell else {
            return UITableViewCell()
        }
        
        let workout = sortedWorkouts[indexPath.row]
        cell.cardView.configure(workout: workout)
        
       
        
        return cell
    }

    // UITableViewDelegate Method
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let workout = sortedWorkouts[indexPath.row]
        let workoutViewController = WorkoutViewController(workout: workout)
        navigationController?.pushViewController(workoutViewController, animated: true)
        
    }
}

class WorkoutListTableViewCell: UITableViewCell {
    
    let cardView = WorkoutListCardView()
    
    override init(style: UITableViewCell.CellStyle,
                  reuseIdentifier: String?) {
        
        super.init(style: style,
                   reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        contentView.addSubview(cardView)
        
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 8
            ),
            cardView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 16
            ),
            cardView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -16
            ),
            cardView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -8
            )
        ])
        
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}
