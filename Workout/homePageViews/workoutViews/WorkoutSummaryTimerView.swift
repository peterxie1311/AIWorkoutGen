//
//  WorkoutSummaryTimerView.swift
//  Workout
//
//  Created by Peter Xie on 26/4/2026.
//

import UIKit

class WorkoutSummaryTimerView: UIView {
    
//    private var startDate:Date
//    private var
    
    private let timerView       = TimerView()
    private let containerView   = UIView()
    private let hStack          = UIStackView()
    private let vStack          = UIStackView()
    private let restTimerLabel  = UILabel()
    
    private let startWorkoutButton = workoutDesigns.createStyledButton( title: "Start",
                                                                        titleFontSize: 16,
                                                                        imageSize: 16,
                                                                        systemImageName: "play.fill",
                                                                        backgroundColor: .systemBlue,
                                                                        cornerRadius: 16,
                                                                        width: 100 ,
                                                                        height: 30)
    private let finishWorkoutButton = workoutDesigns.createStyledButton( title: "Finish",
                                                                         titleFontSize: 16,
                                                                         imageSize: 16,
                                                                        systemImageName: "stop",
                                                                        backgroundColor: .clear,
                                                                        borderColor: .systemBlue,
                                                                        textColor: .systemBlue,
                                                                        cornerRadius: 16,
                                                                        width: 100 ,
                                                                        height: 30)
    

    override init(frame: CGRect){
        super.init(frame:frame)
        build()
        style()
    }
    required init?(coder: NSCoder){
        fatalError("look into workoutsummaryCardView def required init?")
    }
    
    
    private func build(){
        addSubview(containerView)
        containerView.layer.cornerRadius = 16
        containerView.layer.masksToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        //Configure the hstack
        hStack.axis    = .horizontal
        hStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.axis    = .vertical
        vStack.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonHstack = UIStackView()
        buttonHstack.axis = .horizontal
        buttonHstack.distribution = .fillEqually
       // buttonHstack.spacing      = 
        buttonHstack.alignment    = .fill
        buttonHstack.translatesAutoresizingMaskIntoConstraints = false
        buttonHstack.addArrangedSubview(startWorkoutButton)
        buttonHstack.addArrangedSubview(finishWorkoutButton)
     //   finishWorkoutButton.addTarget(self, action: #selector(syncWorkout), for: .touchUpInside)
        containerView.addSubview(hStack)
     
        vStack.addArrangedSubview(makeDividerHeight(gap: 25))
        vStack.addArrangedSubview(restTimerLabel)
        vStack.addArrangedSubview(buttonHstack)
        vStack.addArrangedSubview(makeDividerHeight(gap: 25))
        
        let views = [timerView,vStack]
        views.forEach{
            hStack.addArrangedSubview($0)
        }
        
        
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            hStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            hStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            hStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            hStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)
        ])
        
    }
    
    private func style(){
        containerView.backgroundColor = .systemGray6
        let date = Date().addingTimeInterval(-120)
        self.timerView.updateTimer(i_finishTime: date)
        restTimerLabel.text = "Rest Timer"
        restTimerLabel.textColor = .systemBlue
        restTimerLabel.font = .systemFont(ofSize: 32, weight: .bold)
        
        
        
        
    }
    
    private func makeDividerHeight(gap:CGFloat) -> UIView {
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: gap)])
        return divider
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

private final class TimerView: UIView {
    
    private let container = UIView()
    private let timeLabel = UILabel()
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private var duration:TimeInterval = 300
    
    
    override init(frame:CGRect){
        super.init(frame: frame)
        build()
        style()
    }
    required init?(coder: NSCoder){
        fatalError("look into workoutsummaryCardView def required init?")
    }
    
    private func build(){
        addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let diameter:CGFloat = 150
        
        container.layer.addSublayer(trackLayer)
        container.layer.addSublayer(progressLayer)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            container.centerXAnchor.constraint(equalTo: centerXAnchor),
            container.widthAnchor.constraint(equalToConstant: diameter),
            container.heightAnchor.constraint(equalToConstant: diameter),
            container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            
            // Labels inside circle
            timeLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            timeLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 50)
//            timeLabel.centerXAnchor.constraint(equalTo: circleContainer.centerXAnchor),
//            timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8)
        ])
        
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        calculatePath()
    }
    
    func updateTimer(i_finishTime:Date){
        let restTime = i_finishTime.timeIntervalSinceNow
        let normalisedRestTime = max(0,-restTime)
        
        let seconds = Int(normalisedRestTime)
        let mins = seconds / 60
        let secs = seconds % 60
        timeLabel.text = String(format: "%02d:%02d", mins, secs)
        
//        timeLabel.text = String(format:"%.1f",normalisedRestTime)
        let progress = min(normalisedRestTime/duration,1)
        progressLayer.strokeEnd = CGFloat(progress)
        
    }
    
    private func calculatePath(){
        let b = container.bounds
        let radius = min(b.width,b.height) / 2 - progressLayer.lineWidth - 2
        let center = CGPoint(x: b.midX, y: b.midY)
        let path   = UIBezierPath(arcCenter: center,
                                  radius: radius,
                                  startAngle: -.pi/2,
                                  endAngle: 3 * .pi/2,
                                  clockwise: true)
        trackLayer.path = path.cgPath
        progressLayer.path = path.cgPath
    }
    private func style(){
        timeLabel.text      = "00:00"
        timeLabel.textColor = .systemBlue
        timeLabel.font      = .systemFont(ofSize: 34, weight: .semibold)
        
        // style the track
        trackLayer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.2).cgColor
        trackLayer.fillColor   = UIColor.clear.cgColor
        trackLayer.lineWidth   = 8
        trackLayer.lineCap     = .round
        
        progressLayer.strokeColor = UIColor.systemBlue.cgColor
        progressLayer.fillColor   = UIColor.clear.cgColor
        progressLayer.lineWidth   = 8
        progressLayer.lineCap     = .round
        progressLayer.strokeEnd   = 0
        
    }
}
