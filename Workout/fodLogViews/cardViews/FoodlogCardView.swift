//
//  FoodlogCardView.swift
//  Workout
//
//  Created by Peter Xie on 3/4/2026.
//

import UIKit

final class FoodlogCardView: UIView {
    private let container = UIView()
    private let stackView = UIStackView()
    
    override init(frame: CGRect){
        super.init(frame: frame)
        build()
        style()
        
    }
    required init(coder:NSCoder){
        fatalError("init(coder:) has not been implemented")
    }
    
    private func build(){
        addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        
        container.addSubview(stackView)
        NSLayoutConstraint.activate([container.topAnchor.constraint(equalTo: topAnchor),
                                     container.leadingAnchor.constraint(equalTo: leadingAnchor),
                                     container.trailingAnchor.constraint(equalTo: trailingAnchor),
                                     container.bottomAnchor.constraint(equalTo: bottomAnchor),
                                    
                                     stackView.topAnchor.constraint(equalTo: container.topAnchor, constant : 12),
                                     stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                                     stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                                     stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor,constant: -12)
                                    ])
        
        
    }
    
    private func style(){
        container.backgroundColor = UIColor.systemGray6
        container.layer.cornerRadius = 18
        container.layer.masksToBounds = true
    }
    
    func configure (foodLogLines:[FoodLogLine],totalCalories:Double,totalProtein:Double){
        clearStack()
        
        var foodEntryRows:[FoodEntryRowView] = []
        for (index, line) in foodLogLines.enumerated() {
            let row = FoodEntryRowView()
            row.configure(foodLogline: line, totalCalories: totalCalories, totalProtein: totalProtein)
            stackView.addArrangedSubview(row)
            foodEntryRows.append(row)

            if index < foodLogLines.count - 1 {
                stackView.addArrangedSubview(makeDivider())
            }
        }
        layoutIfNeeded()

        foodEntryRows.forEach{
            $0.setProgress()
        }
    }
    
    private func clearStack() {
        stackView.arrangedSubviews.forEach{
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }
    
    private func makeDivider() -> UIView {
        let container = UIView()

        let divider = UIView()
        divider.backgroundColor = UIColor.systemGray4.withAlphaComponent(0.5)
        divider.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(divider)

        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 1),
            divider.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            divider.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            divider.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            container.heightAnchor.constraint(equalToConstant: 12)
        ])

        return container
    }

}

private final class FoodEntryRowView: UIView {
    //for the delete button
    private let backgroundContainer = UIView()
    private let foregroundContainer = UIView()
    private let deleteButton        = UIButton(type: .system)
    
    private lazy var leftSwipeGesture  = UISwipeGestureRecognizer(target: self, action: #selector(handleLeftSwipe))
    private lazy var rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleRightSwipe))

    private let foodNameAndProtein        = UILabel()
    private let foodCalories              = UILabel()
    private let foodCarbsAndPercentage    = UILabel()

    private let bar1Track            = UIView()
    private let bar1Fill             = UIView()
    private var bar1Progress:CGFloat = 0
    
    private let bar2Track            = UIView()
    private let bar2Fill             = UIView()
    private var bar2Progress:CGFloat = 0
    
    private var line:FoodLogLine    = FoodLogLine()
    
    override init(frame: CGRect){
        super.init(frame:frame)
        build()
        style()
    }
    
    required init(coder:NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func handleLeftSwipe() {
        UIView.animate(withDuration: 0.25) {
            self.foregroundContainer.transform = CGAffineTransform(translationX: -80, y: 0)
        }
    }

    @objc private func handleRightSwipe() {
        UIView.animate(withDuration: 0.25) {
            self.foregroundContainer.transform = .identity
        }
    }
    
    @objc private func deleteFoodLogLine () {
        FoodLogManager.shared.removeFoodLogLine(i_foodlogLine: line)
    }
    
    func configure (
        foodLogline:FoodLogLine,
        totalCalories:Double,
        totalProtein:Double
    ){
    // this is the attributes of the struct
//        struct attributedText{
//            let text:String
//            //let font:UIFont
//            let fontsize:CGFloat = 20
//            let colour:UIColor   = .label
//            let fontWeight:UIFont.Weight = .semibold
//            
//            
//        }
        //define all the labels
        //first do the foodNameAndProtien
        
        let foodName = workoutDesigns.attributedText(text: foodLogline.food ?? " ",
                                                     fontWeight: .bold)
        let proteinLabel = workoutDesigns.attributedText(text: " Protein:",
                                                         fontsize: 16,
                                                         colour: UIColor.secondaryLabel)
        let proteinValueLabel = workoutDesigns.attributedText(text: "\(HelperFunctions.formatNumber(foodLogline.protein))",
                                                              fontsize: 16
                                                            )
        //fodCalories
        let carbs = workoutDesigns.attributedText(text: "Carbs:",
                                                  fontsize: 16,
                                                  colour: UIColor.secondaryLabel)
        let carbValue  = workoutDesigns.attributedText(text: "\(HelperFunctions.formatNumber(foodLogline.carbs))",
                                                      fontsize: 16)
        
        let safeTotalCalories = totalCalories == 0 ? 1 : totalCalories
        let safeTotalProtein  = totalProtein  == 0 ? 1 : totalProtein
        
        let percentageProtein = workoutDesigns.attributedText(text:"  \("(\(Int(((foodLogline.protein/safeTotalProtein)*100).rounded()))%)")",
                                                       fontsize: 16,
                                                       colour:UIColor.systemBlue)
        
        let percentageCals = workoutDesigns.attributedText(text:"  \("(\(Int(((foodLogline.calories/safeTotalCalories)*100).rounded()))%)")",
                                                       fontsize: 16,
                                                       colour:UIColor.systemGreen)
        let calValue = workoutDesigns.attributedText(text:"\(HelperFunctions.formatNumber(foodLogline.calories))")
        let cal = workoutDesigns.attributedText(text: " Cal",
                                                fontsize: 16,
                                                colour: UIColor.secondaryLabel)
        
        foodNameAndProtein.attributedText = workoutDesigns.makeAttributedString(textArray:[foodName,proteinLabel,proteinValueLabel])
                                                                                    
                                                                                    
        foodCalories.attributedText = workoutDesigns.makeAttributedString(textArray: [calValue,cal])
        
        foodCarbsAndPercentage.attributedText = workoutDesigns.makeAttributedString(textArray: [carbs,carbValue,percentageProtein,percentageCals])
        
        bar1Progress = CGFloat(min(1, max(0, Float(foodLogline.protein) / Float(safeTotalProtein))))
        bar2Progress = CGFloat(min(1, max(0, Float(foodLogline.calories) / Float(safeTotalCalories))))
        line = foodLogline
    }

  func setProgress() {
        //set the progress of bar1
        let clamped = max(0, min(1, bar1Progress))
        let width = bar1Track.bounds.width * clamped

        // Update the width constraint we created in makeBar(...)
        if let widthConstraint = bar1Fill.constraints.first(where: { $0.firstAttribute == .width }) {
            widthConstraint.constant = width
        }
      
        // set the progress of bar 2
        let clamped2 = max(0, min(1, bar2Progress))
        let width2   = bar2Track.bounds.width * clamped2

        // Update the width constraint we created in makeBar(...)
        if let widthConstraint2 = bar2Fill.constraints.first(where: { $0.firstAttribute == .width }) {
            widthConstraint2.constant = width2
        }
      
        // Animate if you want:
        UIView.animate(withDuration: 1) {
            self.layoutIfNeeded()
        }
        roundBar(track: bar1Track, fill: bar1Fill)
        roundBar(track: bar2Track, fill: bar2Fill)

    }

    private func build() {
        addSubview(backgroundContainer)
        addSubview(foregroundContainer)
        
        backgroundContainer.translatesAutoresizingMaskIntoConstraints = false
        foregroundContainer.translatesAutoresizingMaskIntoConstraints = false
        let row1 = makeRow(floatLeft: foodNameAndProtein, floatRight: foodCalories)
        let progressBar = workoutDesigns.makeProgressBar(track: bar1Track, fill: bar1Fill, height: 8)
        let progressBar2 = workoutDesigns.makeProgressBar(track: bar2Track, fill: bar2Fill, height: 8)
        
        let stackView = UIStackView(arrangedSubviews: [row1,progressBar,progressBar2,foodCarbsAndPercentage])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        foregroundContainer.addSubview(stackView)
        
        // delete button stuff
        
        deleteButton.setImage(UIImage(systemName: "trash.fill"), for: .normal)
        deleteButton.tintColor = .white
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(deleteFoodLogLine), for: .touchUpInside)
        
        leftSwipeGesture.direction = .left
        rightSwipeGesture.direction = .right

        foregroundContainer.addGestureRecognizer(leftSwipeGesture)
        foregroundContainer.addGestureRecognizer(rightSwipeGesture)
        foregroundContainer.isUserInteractionEnabled = true

        backgroundContainer.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            backgroundContainer.topAnchor.constraint(equalTo: topAnchor),
            backgroundContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            deleteButton.trailingAnchor.constraint(equalTo: backgroundContainer.trailingAnchor, constant: -16),
            deleteButton.centerYAnchor.constraint(equalTo: backgroundContainer.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 28),
            deleteButton.heightAnchor.constraint(equalToConstant: 28),

            foregroundContainer.topAnchor.constraint(equalTo: topAnchor),
            foregroundContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            foregroundContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            foregroundContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: foregroundContainer.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: foregroundContainer.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: foregroundContainer.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: foregroundContainer.bottomAnchor, constant: -12)
        ])
    }
    
    private func style(){
        foregroundContainer.backgroundColor = UIColor.systemGray6
        //delete button
        backgroundContainer.backgroundColor = .systemRed
        
        backgroundContainer.layer.cornerRadius = 18
        backgroundContainer.layer.masksToBounds = true
        
        foregroundContainer.layer.cornerRadius = 18
        foregroundContainer.layer.masksToBounds = true
        //container.layer.cornerRadius = 18
        //container.layer.masksToBounds = true
        
        foodNameAndProtein.textColor = .label
        foodCalories.textColor = .label
        foodCarbsAndPercentage.textColor = .label
        
        foodNameAndProtein.numberOfLines = 0
        foodNameAndProtein.lineBreakMode = .byWordWrapping
        
        //------test --------\\
        foodNameAndProtein.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        foodCalories.setContentCompressionResistancePriority(.required, for: .horizontal)
        
      //  bar1Track.backgroundColor = UIColor.systemGray4.withAlphaComponent(0.6)
     //   bar1Track.layer.masksToBounds = true
      //
     //   bar2Track.backgroundColor = UIColor.systemGray4.withAlphaComponent(0.6)
    //    bar2Track.layer.masksToBounds = true
        
        bar1Fill.backgroundColor = .systemBlue
        bar2Fill.backgroundColor = .systemGreen
    }
    
    private func roundBar(track: UIView, fill: UIView) {
        track.layer.cornerRadius = track.bounds.height / 2
        fill.layer.cornerRadius = fill.bounds.height / 2
        fill.layer.masksToBounds = true
        track.layer.masksToBounds = true
    }

    private func makeRow  (floatLeft: UILabel,
                           floatRight: UILabel,
                           font:CGFloat = 26,
                           fontWeight: UIFont.Weight = .bold) -> UIStackView {
        floatLeft.textAlignment = .left
        floatRight.textAlignment = .right
        floatLeft.font  = .systemFont(ofSize: font, weight: fontWeight)
        floatRight.font = .systemFont(ofSize: font, weight: fontWeight)

        let v = UIStackView(arrangedSubviews: [floatLeft, floatRight])
        v.axis = .horizontal
        v.distribution = .equalSpacing
        return v
    }


    
    
    
  

}

