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
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
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
        Task{
            await WorkoutSessionManager.shared.removeWorkoutSession(workoutid: self.id ?? UUID())
            await MainActor.run {
                  self.navigationController?.popViewController(animated: true)
              }
        }
        guard self.id != nil else {
                print("Workout ID is nil")
                return
            }
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
        view.backgroundColor = WorkoutTheme.background
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: NSNotification.Name("SetRep"), object: nil)
        setupUI()
        setupData()
    }
    
    @objc private func reload(){
        tableView.reloadData()
    }
    
    private func summaryCard(_ title: String, _ value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title.uppercased()
        titleLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        titleLabel.textColor = .secondaryLabel
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 18, weight: .bold)
        valueLabel.textColor = .label
        valueLabel.numberOfLines = 2
        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .center
        let card = UIView()
        WorkoutTheme.card(card)
        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -6)
        ])
        return card
    }

    private func setupUI() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let start = startTime.map { dateFormatter.string(from: $0) } ?? "—"
        let end = endTime.map { dateFormatter.string(from: $0) } ?? "—"
        let duration = (startTime != nil && endTime != nil)
            ? max(0, Int((endTime!.timeIntervalSince(startTime!)) / 60))
            : Int(duration_hrs * 60)
        let title = UILabel()
        title.text = (workoutGenre?.isEmpty == false ? workoutGenre : nil) ?? "Workout Session"
        title.font = .systemFont(ofSize: 30, weight: .bold)
        title.textColor = .label
        title.numberOfLines = 0
        let date = UILabel()
        date.text = startTime.map { DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none) } ?? "Session details"
        date.font = .systemFont(ofSize: 15)
        date.textColor = .secondaryLabel
        let header = UIStackView(arrangedSubviews: [title, date])
        header.axis = .vertical
        header.spacing = 6

        let stats = UIStackView(arrangedSubviews: [
            summaryCard("Start", start),
            summaryCard("Finish", end),
            summaryCard("Duration", "\(duration) min")
        ])
        stats.axis = .horizontal
        stats.spacing = 8
        stats.distribution = .fillEqually

        let heading = UILabel()
        heading.text = "Exercises  •  \(setreps.count) sets"
        heading.font = .systemFont(ofSize: 22, weight: .bold)
        heading.textColor = .label

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WorkoutTableViewCell.self, forCellReuseIdentifier: "WorkoutCell")
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.heightAnchor.constraint(equalToConstant: CGFloat(setreps.count) * 108 + 20).isActive = true

        deleteButton.setTitle("Delete Workout", for: .normal)
        deleteButton.addTarget(self, action: #selector(confirmDeleteWorkout), for: .touchUpInside)
        deleteButton.configuration?.baseBackgroundColor = .systemRed.withAlphaComponent(0.12)
        deleteButton.configuration?.baseForegroundColor = .systemRed
        excludeButton.addTarget(self, action: #selector(excludeWorkout), for: .touchUpInside)
        excludeButton.configuration?.baseBackgroundColor = .secondarySystemGroupedBackground
        excludeButton.configuration?.baseForegroundColor = .label
        AddSetRep.addTarget(self, action: #selector(goToAddSetVC), for: .touchUpInside)

        let actionRow = UIStackView(arrangedSubviews: [deleteButton, excludeButton])
        actionRow.axis = .horizontal
        actionRow.spacing = 10
        actionRow.distribution = .fillEqually
        let root = UIStackView(arrangedSubviews: [header, stats, AddSetRep, heading, tableView, actionRow])
        root.axis = .vertical
        root.spacing = Constants.Design.Spacing.large
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(root)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            root.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            root.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
            root.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            root.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            root.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }

    @objc private func confirmDeleteWorkout() {
        let alert = UIAlertController(title: "Delete Workout?", message: "This session and its sets will be removed.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in self?.removeWorkout() })
        present(alert, animated: true)
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
    
    private func setupData() { }
}

class WorkoutTableViewCell: UITableViewCell {
    private let name = UILabel()
    private let details = UILabel()
    private let status = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = WorkoutTheme.surface
        contentView.layer.cornerRadius = Constants.Design.Radius.compactCard
        contentView.layer.cornerCurve = .continuous
        name.font = .systemFont(ofSize: 17, weight: .semibold)
        name.textColor = .label
        name.numberOfLines = 2
        details.font = .systemFont(ofSize: 14)
        details.textColor = .secondaryLabel
        details.numberOfLines = 2
        let labels = UIStackView(arrangedSubviews: [name, details])
        labels.axis = .vertical
        labels.spacing = 8
        status.contentMode = .scaleAspectFit
        status.widthAnchor.constraint(equalToConstant: 26).isActive = true
        let row = UIStackView(arrangedSubviews: [labels, status])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(with setrep: Setrep) {
        name.text = setrep.workoutName ?? "Exercise"
        details.text = "\(setrep.rep_qty) reps  •  \(setrep.weight) kg  •  " + String(format: "%.1f sec", setrep.duration_sec)
        status.image = UIImage(systemName: setrep.completed ? "checkmark.circle.fill" : "circle")
        status.tintColor = setrep.completed ? .systemGreen : .tertiaryLabel
    }
}
