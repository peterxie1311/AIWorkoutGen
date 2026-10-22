//
//  WorkoutSummaryCardView.swift
//  Workout
//
//  Created by Peter Xie on 25/4/2026.
//

import UIKit

final class WorkoutSummaryCardView: UIView {
    // MARK: Define all the stuff
    private let container = UIView()
    
    
    //labels (these should get styled in make column)
    private let startTimeLabel      = UILabel()
    private let startTimeValueLabel = UILabel()
    
    private let durationLabel       = UILabel()
    private let durationValueLabel  = UILabel()
    
    private let restTimeLabel       = UILabel()
    private let restTimeValueLabel  = UILabel()
    
    private let totalRestTimeLabel  = UILabel()
    private let totalRestTimeValueLabel = UILabel()
    
    
    
    override init(frame: CGRect){
        super.init(frame:frame)
        build()
        style()
    }
    required init?(coder: NSCoder){
        fatalError("look into workoutsummaryCardView def required init?")
    }
    
    
    func updateTimers(i_startDate:Date,
                      i_restTime:Int,
                      i_totalRestTimeSec:Int){
        let duration = Int(Date().timeIntervalSince(i_startDate))
        startTimeValueLabel.text     = HelperFunctions.parseDateToStringTime(i_startDate)
        durationValueLabel.text      = HelperFunctions.parseIntSecToString  (seconds: duration)
        restTimeValueLabel.text      = HelperFunctions.parseIntSecToString  (seconds: i_restTime)
        totalRestTimeValueLabel.text = HelperFunctions.parseIntSecToString  (seconds: i_totalRestTimeSec)
    }
    
    private func build(){
        addSubview(container)
        
        container.translatesAutoresizingMaskIntoConstraints = false
        let col1 = makeColumn(title: startTimeLabel, value: startTimeValueLabel, align: .left, systemImageName: "clock",imageColour: .systemPurple)
     
        let col2 = makeColumn(title: durationLabel, value: durationValueLabel, align: .left, systemImageName:"alarm" ,imageColour:WorkoutTheme.accent)

        let col3 = makeColumn(title: restTimeLabel, value: restTimeValueLabel, align: .left, systemImageName: "timer", imageColour: .systemCyan)
  
        let col4 = makeColumn(title: totalRestTimeLabel, value: totalRestTimeValueLabel, align: .left, systemImageName: "flame", imageColour: .systemOrange)
        
        let row1 = UIStackView(arrangedSubviews: [col1, col2])
        let row2 = UIStackView(arrangedSubviews: [col3, col4])
        [row1, row2].forEach { $0.distribution = .fillEqually; $0.spacing = 16 }
        let hstack = UIStackView(arrangedSubviews: [row1, row2])
        hstack.axis = .vertical
        hstack.spacing = 20
        hstack.translatesAutoresizingMaskIntoConstraints = false
        hstack.distribution = .fillEqually
        
        container.addSubview(hstack)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),

            hstack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            hstack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            hstack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            hstack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
        ])
        
        
        
    }
    private func style() {
        WorkoutTheme.card(container)
        container.layer.cornerRadius = 22
        container.layer.masksToBounds = true

        startTimeLabel.text = "Start"
        startTimeValueLabel.text = "—"
        
        durationLabel.text = "Duration"
        durationValueLabel.text = "00:00:00"
        
        restTimeLabel.text = "Rest"
        restTimeValueLabel.text = "—"
        
        totalRestTimeLabel.text = "Total Rest"
        totalRestTimeValueLabel.text = "00:00"
    }
    
    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            divider.widthAnchor.constraint(equalToConstant: 1)])
        return divider
    }
    
    private func makeColumn(title: UILabel, value: UILabel, align: NSTextAlignment,systemImageName:String,imageColour:UIColor) -> UIStackView {
        title.textAlignment = align
        title.font = .preferredFont(forTextStyle: .caption1)
        title.adjustsFontForContentSizeCategory = true

        value.textAlignment = align
        value.font = UIFontMetrics(forTextStyle: .title3).scaledFont(for: .monospacedDigitSystemFont(ofSize: 22, weight: .semibold))
        value.adjustsFontForContentSizeCategory = true
        value.adjustsFontSizeToFitWidth = true
        value.minimumScaleFactor = 0.7
        
        title.textColor = .secondaryLabel
        value.textColor = .label
        
        let image = UIImageView(image: UIImage(systemName: systemImageName))
        image.tintColor = imageColour
        image.widthAnchor.constraint(equalToConstant: 28).isActive = true
        image.heightAnchor.constraint(equalToConstant: 28).isActive = true
        image.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        image.contentMode = .scaleAspectFit
        
        let v = UIStackView(arrangedSubviews: [title, value])
        v.axis = .vertical
        v.spacing = 4
        v.alignment = align == .left ? .leading : (align == .right ? .trailing : .center)
        
        let h = UIStackView(arrangedSubviews: [image,v])
        h.axis = .horizontal
        h.spacing = 10
        h.alignment = .center//align == .left ? .leading : (align == .right ? .trailing : .center)
        h.translatesAutoresizingMaskIntoConstraints = false
        
        return h
    }
}

