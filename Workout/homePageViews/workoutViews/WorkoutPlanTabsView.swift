//
//  WorkoutPlanTabsView.swift
//  Workout
//
//  Created by Peter Xie on 27/4/2026.
//
import UIKit

final class WorkoutPlanTabsView: UIView {

    private let tabStack = UIStackView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    private var workoutSessions: [WorkoutSession] = []
    private var selectedIndex = 0
    private var headerCreated = false
    

   
    

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
        style()
        reloadTabs()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(i_workoutSessions: [WorkoutSession]) {
        workoutSessions = i_workoutSessions
        selectedIndex = 0
        reloadTabs()
        tableView.reloadData()
    }
    
// we have to do this because if we do this in self.build() none of the widths are init and there will be some errrs
    override func layoutSubviews() {
        super.layoutSubviews()

        if !headerCreated {
            tableView.tableHeaderView = createHeader()
            headerCreated = true
        }

        if let header = tableView.tableHeaderView {
            header.frame = CGRect(
                x: 0,
                y: 0,
                width: tableView.bounds.width,
                height: 40
            )
            tableView.tableHeaderView = header
        }
    }


    private func build() {
        addSubview(tabStack)
        addSubview(tableView)

        tabStack.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tabStack.axis = .horizontal
        tabStack.distribution = .fillEqually
        tabStack.spacing = 6
        
      //  tableView.tableHeaderView = createHeader()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WorkoutListCell.self, forCellReuseIdentifier: "cell")

        NSLayoutConstraint.activate([
            tabStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            tabStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            tabStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            tabStack.heightAnchor.constraint(equalToConstant: 36),

            tableView.topAnchor.constraint(equalTo: tabStack.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func style() {
        backgroundColor = .systemGray6
        layer.cornerRadius = 18
        clipsToBounds = true

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
    }
    private func createHeader () -> UIView {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 40))
        
        let titles = ["Workout", "QTY", "Kgs", "Status"]
        let headerStackView = UIStackView()
        headerStackView.axis = .horizontal
        headerStackView.distribution = .fillEqually
        headerStackView.alignment = .center
        headerStackView.spacing = 10
        
        for title in titles {
            let label           = UILabel()
            label.text          = title
            label.textAlignment = .center
            label.font          = UIFont.boldSystemFont(ofSize: 16)
            label.textColor     = .systemBlue
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
        return headerView
    }

    private func reloadTabs() {
        tabStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, session) in workoutSessions.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(session.workout_genre ?? " ", for: .normal)
            button.tag = index
            button.layer.cornerRadius = 12
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)

            if index == selectedIndex {
                button.backgroundColor = .systemBlue
                button.setTitleColor(.white, for: .normal)
            } else {
                button.backgroundColor = .clear
                button.setTitleColor(.systemBlue, for: .normal)
            }

            button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            tabStack.addArrangedSubview(button)
        }
    }

    @objc private func tabTapped(_ sender: UIButton) {
        selectedIndex = sender.tag
        reloadTabs()
        tableView.reloadData()
    }
}

extension WorkoutPlanTabsView: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard workoutSessions.indices.contains(selectedIndex) else {
               return 0
        }

        let array = Array(workoutSessions[selectedIndex].setrep as? Set<Setrep> ?? [])
        
        return array.count
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! WorkoutListCell
        //let setrep = workoutSessions[selectedIndex].setrep[indexPath.row] ??
        let array = Array(workoutSessions[selectedIndex].setrep as? Set<Setrep> ?? [])
        cell.configure(with:array[indexPath.row])
        return cell
    }
}


//MARK: Declaration of table
class WorkoutListCell: UITableViewCell {
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
        stackView.spacing = 8

        workoutLabel.numberOfLines = 0
        workoutLabel.lineBreakMode = .byWordWrapping
        // cell stack constraints end -----------------------------------------
        
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        // Style Labels
        [workoutLabel, qtyLabel, kgsLabel].forEach {
            $0.textAlignment = .center
            $0.font = UIFont.systemFont(ofSize: 16)
            $0.textColor = .white
        }
        
        status.contentMode = .scaleAspectFit
        status.tintColor   = .white
        
        contentView.backgroundColor = .secondarySystemBackground
        backgroundColor = .clear
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

