import UIKit

class workoutDesigns {
    
   static func createRoundedSquareView(withText text: String) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 16 // Adjust for desired roundness
        containerView.layer.masksToBounds = true
        
        // Add a label for the text
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.textColor = .label
        label.textAlignment = .center
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(label)
        
        // Constraints for the label
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
           
        ])
       
        return containerView
    }
    
    static func createLinearProgressBarView(
        withText text: String,
        duration: TimeInterval = 300
    ) -> UIView {
        let containerView = UIView()
     //   containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 16
        containerView.layer.masksToBounds = true

        let titleLabel = UILabel()
        titleLabel.text = text.uppercased()
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        let timeLabel = UILabel()
        timeLabel.text = "0"
        timeLabel.textColor = .white
        timeLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(timeLabel)

        let circleContainer = UIView()
        circleContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(circleContainer)

        let center = CGPoint(x: 50, y: 50)
        let circlePath = UIBezierPath(arcCenter: center, radius: 40, startAngle: -.pi/2, endAngle: 3 * .pi/2, clockwise: true)

        let trackLayer = CAShapeLayer()
        trackLayer.path = circlePath.cgPath
        trackLayer.strokeColor = UIColor.systemGray6.cgColor //UIColor(red: 3/255, green: 34/255, blue: 82/255, alpha: 1).cgColor
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineWidth = 8
        circleContainer.layer.addSublayer(trackLayer)

        let progressLayer = CAShapeLayer()
        progressLayer.path = circlePath.cgPath
        progressLayer.strokeColor = UIColor.systemBlue.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 8
        progressLayer.strokeEnd = 0
        circleContainer.layer.addSublayer(progressLayer)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            circleContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            circleContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            circleContainer.widthAnchor.constraint(equalToConstant: 100),
            circleContainer.heightAnchor.constraint(equalToConstant: 100),

            timeLabel.centerXAnchor.constraint(equalTo: circleContainer.centerXAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: circleContainer.centerYAnchor),

            circleContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])

        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if SetrepManager.shared.toDoHasCompletedSetRep() {
                let latestSetRep = SetrepManager.shared.getLatestSetRep(setrepArray: SetrepManager.shared.Setreps)
                let restTime = latestSetRep.finishTime?.timeIntervalSinceNow ?? 0
                let clamped = max(0, -restTime)
                timeLabel.text = String(format: "%.1f", clamped)
                let progress = min(clamped / duration, 1.0)
                progressLayer.strokeEnd = CGFloat(progress)
            } else {
                timeLabel.text = "0.0"
                progressLayer.strokeEnd = 0
            }
        }
        RunLoop.current.add(timer, forMode: .common)

        return containerView
    }


    
    static func updateLabelText(in view: UIView, newText: String) {
          // Look for the label in the container view by traversing the subviews
          if let label = view.subviews.compactMap({ $0 as? UILabel }).first {
              label.text = newText
          }
      }
    
    static func createStyledButton(
        title: String,
        systemImageName: String? = nil,
        backgroundColor: UIColor = .systemBlue,
        cornerRadius: CGFloat = 20,
        width: CGFloat ,
        height: CGFloat
    ) -> UIButton {
        let button = UIButton(type: .system)
        if let systemImageName = systemImageName {
                let image = UIImage(systemName: systemImageName)
                button.setImage(image, for: .normal)
                button.tintColor = .white
                button.imageView?.contentMode = .scaleAspectFit
            button.semanticContentAttribute = .forceRightToLeft
            button.setTitle(title + " ", for: .normal)
                
            } else {
                button.setTitle(title, for: .normal)
            }
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = backgroundColor
        
        // Styling for the button
        button.layer.cornerRadius = cornerRadius
//        button.layer.borderWidth = 2
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 2, height: 2)
        button.layer.shadowRadius = 5
        
        // Auto Layout constraints
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: height),
        ])
        
        return button
    }

}


extension UIViewController {
    
     func setupToolbar(toolbar: UIToolbar,
                       settingsSelector: Selector,
                       viewWorkoutSelector: Selector,
                       startWorkoutSelector: Selector,
                       finishWorkoutSelector: Selector,
                       gymprogresstracker:Selector) {
        view.addSubview(toolbar)
        toolbar.layer.masksToBounds = true
        toolbar.backgroundColor = .systemBackground
        toolbar.isTranslucent = false
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        let settingsButton = createCustomButton(imageName: "gearshape", action: settingsSelector)
        let viewWorkoutButton = createCustomButton(imageName: "dumbbell", action: viewWorkoutSelector)
        let startWorkoutButton = createCustomButton(imageName: "play", action: startWorkoutSelector)
        let finishWorkoutButton = createCustomButton(imageName: "stop", action: finishWorkoutSelector)
        let gymprogressSelector = createCustomButton(imageName: "tree", action: gymprogresstracker)
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        toolbar.items = [
            flexibleSpace, settingsButton,
            flexibleSpace, viewWorkoutButton,
            flexibleSpace, startWorkoutButton,
            flexibleSpace, finishWorkoutButton,
            flexibleSpace, gymprogressSelector,
            flexibleSpace
        ]


        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor,constant: -15),
            toolbar.heightAnchor.constraint(equalToConstant: 55)
        ])
    }

    private func createCustomButton(imageName: String, action: Selector) -> UIBarButtonItem {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: imageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 25)), for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return UIBarButtonItem(customView: button)
    }
    
}
