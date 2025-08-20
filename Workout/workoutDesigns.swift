import UIKit

class workoutDesigns {
    
   static func createRoundedSquareView(withText text: String) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemBlue
        containerView.layer.cornerRadius = 16 // Adjust for desired roundness
        containerView.layer.masksToBounds = true
      // containerView.translatesAutoresizingMaskIntoConstraints = false
       //containerView.widthAnchor.constraint(equalToConstant: 100).isActive = true
       
//        containerView.layer.borderWidth = 2
//        containerView.layer.borderColor = UIColor { traitCollection in
//            return traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
//        }.cgColor
        
        // Add a label for the text
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
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
        
        // Container view
        let containerView = UIView()
        containerView.backgroundColor = .systemBlue//UIColor(red: 15/255, green: 76/255, blue: 157/255, alpha: 1) // Deep blue like your UI
        containerView.layer.cornerRadius = 16
        containerView.layer.masksToBounds = true
        
        // Label
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 25, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(label)
        
        // Progress View
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progressTintColor = .systemTeal // Matches your screenshot
        progressView.trackTintColor = UIColor(red: 3/255, green: 34/255, blue: 82/255, alpha: 1) // Darker track like in image
        progressView.layer.cornerRadius = 5
        progressView.clipsToBounds = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(progressView)
        
        // Constraints
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            progressView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
            progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            progressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            progressView.heightAnchor.constraint(equalToConstant: 8),
            progressView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
        
        //func getRestTimerString()->String{
           //var restTimeString = ""
            
           // if SetrepManager.shared.toDoHasCompletedSetRep() == true {
                //let latestSetRep = SetrepManager.shared.getLatestSetRep(setrepArray: SetrepManager.shared.Setreps)
              //  let restTime     = latestSetRep.finishTime?.timeIntervalSinceNow ?? 0
            //    restTimeString  = restTimerPrefix + "\(round(-restTime))"
            //}
          //  else {
            //    restTimeString  = restTimerPrefix + "0"
            //}
            
    //        return restTimeString
      //  }
        
        // Timer to update progress
//        let startTime = Date()
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            
             if SetrepManager.shared.toDoHasCompletedSetRep() == true {
                 let latestSetRep = SetrepManager.shared.getLatestSetRep(setrepArray: SetrepManager.shared.Setreps)
                 let restTime     = latestSetRep.finishTime?.timeIntervalSinceNow ?? 0
                // label.text       = "\(round(-restTime))"
                // restTimeString  = restTimerPrefix + "\(round(-restTime))"
                 
                 let clampedRestTime = max(0, -restTime) // Ensure it's not negative
                 label.text = "Rest Time: \(Int(round(clampedRestTime))).0"

                 // Calculate progress as how much of the rest duration has passed
                 let progress = Float(min(clampedRestTime / duration, 1.0))
                 progressView.setProgress(progress, animated: true)
             }
             else {
               //  restTimeString  = restTimerPrefix + "0"
                 label.text            = "Rest Time: 0.0"
                 progressView.progress = 0
             }
            
//            let elapsed = Date().timeIntervalSince(startTime)
//            let progress = Float(elapsed / duration)
//            progressView.setProgress(min(progress, 1.0), animated: true)
//            
//            // Update label with remaining time
//            let remainingTime = max(duration - elapsed, 0)
//           // label.text = "\(text): \(Int(remainingTime))s remaining"
//            
//            if elapsed >= duration {
//                progressView.setProgress(1.0, animated: true)
//            }
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
