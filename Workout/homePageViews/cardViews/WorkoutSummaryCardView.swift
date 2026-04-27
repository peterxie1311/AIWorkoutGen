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
                      i_duration:Int,
                      i_totalRestTimeSec:Int){
        startTimeValueLabel.text     = HelperFunctions.parseDateToStringTime(i_startDate)
        durationValueLabel.text      = HelperFunctions.parseIntSecToString  (seconds: i_duration)
        totalRestTimeValueLabel.text = HelperFunctions.parseIntSecToString  (seconds: i_totalRestTimeSec)
    }
    
    private func build(){
        addSubview(container)
        
        container.translatesAutoresizingMaskIntoConstraints = false
        let col1 = makeColumn(title: startTimeLabel, value: startTimeValueLabel, align: .left, systemImageName: "clock",imageColour: .systemPurple)
        
        
        let divider1 = makeDivider()
        
        let col2 = makeColumn(title: durationLabel, value: durationValueLabel, align: .left, systemImageName:"alarm" ,imageColour:.systemBlue)
        
        let divider2 = makeDivider()
        
        let col3 = makeColumn(title: restTimeLabel, value: restTimeValueLabel, align: .right, systemImageName: "timer", imageColour: .systemCyan)
        let divider3 = makeDivider()
        
        let col4 = makeColumn(title: totalRestTimeLabel, value: totalRestTimeValueLabel, align: .right, systemImageName: "flame", imageColour: .systemOrange)
        let divider4 = makeDivider()
        
        let hstack = UIStackView(arrangedSubviews: [col1,divider1,col2,divider2,col3,divider3,col4,divider4])
        hstack.axis = .horizontal
        hstack.spacing = 10
        hstack.translatesAutoresizingMaskIntoConstraints = false
        //hstack.distribution = .fill
        
        container.addSubview(hstack)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),

            hstack.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            hstack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            hstack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            hstack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14)
        ])
        
        
        
    }
    private func style() {
        container.backgroundColor = UIColor.systemGray6
        container.layer.cornerRadius = 18
        container.layer.masksToBounds = true

        startTimeLabel.text = "Start Time"
        startTimeValueLabel.text = "12:00 PM"
        
        durationLabel.text = "Duration"
        durationValueLabel.text = "00:00:00"
        
        restTimeLabel.text = "Rest Time"
        restTimeValueLabel.text = "01:00"
        
        totalRestTimeLabel.text = "Total Rest"
        totalRestTimeValueLabel.text = "01:00"
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
        title.font = .systemFont(ofSize: 10)

        value.textAlignment = align
        value.font = .systemFont(ofSize: 10, weight: .bold)
        
        title.textColor = .label
        value.textColor = .secondaryLabel
        
        let image = UIImageView(image: UIImage(systemName: systemImageName))
        image.tintColor = imageColour
        image.contentMode = .scaleAspectFit
        
        let v = UIStackView(arrangedSubviews: [title, value])
        v.axis = .vertical
        v.spacing = 4
        v.alignment = align == .left ? .leading : (align == .right ? .trailing : .center)
        
        let h = UIStackView(arrangedSubviews: [image,v])
        h.axis = .horizontal
        h.spacing = 2
        h.alignment = .center//align == .left ? .leading : (align == .right ? .trailing : .center)
        h.translatesAutoresizingMaskIntoConstraints = false
        
        return h
    }

    

    
    
}
