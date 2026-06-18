//
//  WorkoutListCardView.swift
//  Workout
//
//  Created by Peter Xie on 2/6/2026.
//



import UIKit

final class WorkoutListCardView: UIView {

    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private let ratingLabel = UILabel()

    private let durationLabel = UILabel()
    private let setsLabel = UILabel()
    private let volumeLabel = UILabel()
    private let totalrestTimeLabel = UILabel()
    

    private let exercisesLabel = UILabel()

    private let mainStack = UIStackView()
    private let headerStack = UIStackView()
    private let statsStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = UIColor.secondarySystemBackground
        layer.cornerRadius = 16
        clipsToBounds = true

        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = .label

        dateLabel.font = .systemFont(ofSize: 13, weight: .medium)
        dateLabel.textColor = .secondaryLabel

        ratingLabel.font = .boldSystemFont(ofSize: 18)
        ratingLabel.textColor = .systemBlue
        ratingLabel.textAlignment = .right
        
        

        exercisesLabel.font = .systemFont(ofSize: 14, weight: .medium)
        exercisesLabel.textColor = .secondaryLabel
        exercisesLabel.numberOfLines = 2

        let leftHeader = UIStackView(arrangedSubviews: [titleLabel, dateLabel])
        leftHeader.axis = .vertical
        leftHeader.spacing = 4

        headerStack.axis = .horizontal
        headerStack.alignment = .top
        headerStack.distribution = .fill
        headerStack.addArrangedSubview(leftHeader)
        headerStack.addArrangedSubview(ratingLabel)

        [durationLabel, setsLabel, volumeLabel,totalrestTimeLabel].forEach {
            $0.font = .boldSystemFont(ofSize: 15)
            $0.textColor = .secondaryLabel
            $0.textAlignment = .center
            $0.numberOfLines = 2
        }

        statsStack.axis = .horizontal
        statsStack.distribution = .fillEqually
        statsStack.spacing = 8
        statsStack.addArrangedSubview(durationLabel)
        statsStack.addArrangedSubview(setsLabel)
        statsStack.addArrangedSubview(volumeLabel)
        statsStack.addArrangedSubview(totalrestTimeLabel)

        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.addArrangedSubview(headerStack)
        mainStack.addArrangedSubview(statsStack)
        mainStack.addArrangedSubview(exercisesLabel)

        addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }

    func configure(workout: WorkoutSession) {
        let titleText: String

        if let tab = workout.workouttab,
           tab.lowercased() != "default" {
            titleText = tab
        } else {
            titleText = workout.workout_genre ?? "Workout"
        }

        titleLabel.text = titleText

        if let start = workout.startTime {
            dateLabel.text = HelperFunctions.parseDateToStringFull(start)
        } else {
            dateLabel.text = "No date"
        }

        let durationMinutes = Int(workout.duration_hrs * 60)
        let setCount = workout.setrepArray.count

        let totalVolume = workout.setrepArray.reduce(0) { partial, setrep in
            partial + (Int(setrep.rep_qty) * Int(setrep.weight))
        }

        durationLabel.text = "\(durationMinutes)\nmin"
        setsLabel.text = "\(setCount)\nsets"
        volumeLabel.text = "\(totalVolume)\nkg"

        let exercises = Array(
            Set(workout.setrepArray.compactMap { $0.workoutName })
        )
        .prefix(3)
        .joined(separator: ", ")

        exercisesLabel.text = exercises.isEmpty ? "No exercises yet" : exercises

        ratingLabel.text = makeRating(workout: workout)
        totalrestTimeLabel.text = "\(WorkoutSessionManager.shared.getTotalRestTime(i_workout: workout)) sec"
    }

    private func makeRating(workout: WorkoutSession) -> String {
        let completedSets = workout.setrepArray.filter { $0.completed }.count
        let totalSets = workout.setrepArray.count
        return "\(Int(round((Double(completedSets) / Double(totalSets)) * 100)))%"
    }
}
