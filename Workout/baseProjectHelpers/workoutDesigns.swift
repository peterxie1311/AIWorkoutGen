import UIKit

struct TextField {
    let labelName:String
    let keyboardType:UIKeyboardType
    let uiTextfield:UITextField
    let useLabelNameAsPlaceHolder:Bool
    let delegate:UITextFieldDelegate
}

class workoutDesigns {
    
    static func setupTextField(
        _ tf: UITextField,
        placeholder: String,
        keyboardType: UIKeyboardType,
        delegate: UITextFieldDelegate?
    ) {
        tf.borderStyle = .roundedRect
        tf.placeholder = placeholder
        tf.keyboardType = keyboardType
        tf.delegate = delegate
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.isUserInteractionEnabled = true

        // Make it look like an input (height is the big one)
        tf.heightAnchor.constraint(equalToConstant: 44).isActive = true

        // Optional: nicer UX
        tf.clearButtonMode = .whileEditing
        tf.returnKeyType = .done
    }
    
    static func createRoundedSquareViewWithTextFields(textFields: [TextField]) -> UIView {

        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 16
        containerView.layer.masksToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])

        for field in textFields {
            
            setupTextField(
                       field.uiTextfield,
                       placeholder: field.useLabelNameAsPlaceHolder ? field.labelName : (field.uiTextfield.placeholder ?? ""),
                       keyboardType: field.keyboardType,
                       delegate: field.delegate
                   )

            let label  = UILabel()
            label.text = field.labelName
            label.font = UIFont.preferredFont(forTextStyle: .body)

            let fieldStack     = UIStackView(arrangedSubviews: [label, field.uiTextfield])
            fieldStack.axis    = .vertical
            fieldStack.spacing = 4
            stackView.addArrangedSubview(fieldStack)
        }

        return containerView
    }
    
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
    
    //MARK: MacroSummaryCard functions ---------------
    static func createMacroSummaryCard (calorieCurrent: Double,
                                        proteinCurrent: Double,
                                        carbsCurrent: Double,
                                        calorieGoal: Double,
                                        proteinGoal: Double,
                                        carbsGoal: Double,
                                        parentView:UIView
    
    
    ) -> UIView {
        
        let cardView = UIView()
        let containerView = UIView()
        cardView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        //MARK: - BUILD!!
        //split it into 3 cols calrotie protein and carbs
        
        let caloriesTitle = UILabel()
        let caloriesValue = UILabel()
        
        let proteinTitle = UILabel()
        let proteinValue = UILabel()
        
        let carbsTitle = UILabel()
        let carbsValue = UILabel()
        
        //Helper func defined in here it should only be used for making this view anyways
        
        func makeColumn(title: UILabel, value: UILabel, align: NSTextAlignment) -> UIStackView {
             title.textAlignment = align

             value.textAlignment = align
             // default font for split value; calories uses its own bigger font
             value.font = .systemFont(ofSize: 26, weight: .bold)

             let v = UIStackView(arrangedSubviews: [title, value])
             v.axis = .vertical
             v.spacing = 4
             v.alignment = align == .left ? .leading : (align == .right ? .trailing : .center)
             return v
         }
        
        
        // define objects
        let col1 = makeColumn(title: caloriesTitle, value: caloriesValue, align: .left)
        let col2 = makeColumn(title: proteinTitle,  value: proteinValue,  align: .center)
        let col3 = makeColumn(title: carbsTitle,    value: carbsValue,    align: .right)
        
        let divider1 = UIView()
        let divider2 = UIView()
        
        divider1.translatesAutoresizingMaskIntoConstraints = false
        divider2.translatesAutoresizingMaskIntoConstraints = false
        
        //now define the top row this is just the labels and numbers do the progress bars after
        let topRowGrouper = UIStackView(arrangedSubviews: [col1, divider1,col2, divider2,col3])
        topRowGrouper.axis = .horizontal
        topRowGrouper.alignment = .center
        topRowGrouper.spacing = 12
        topRowGrouper.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            divider1.widthAnchor.constraint(equalToConstant: 1),
            divider2.widthAnchor.constraint(equalToConstant: 1)
        ])
        
        // now lets start doing the bar stuff
        
        // just init this bar set the fill as 0 then update it later return the nsLayoutConstraint so we can update it in the next step
        func makeBar(track: UIView, fill: UIView, height: CGFloat) -> (UIView, NSLayoutConstraint) {
            track.translatesAutoresizingMaskIntoConstraints = false
            fill.translatesAutoresizingMaskIntoConstraints = false

            track.addSubview(fill)

            let widthConstraint = fill.widthAnchor.constraint(equalToConstant: 0)

            NSLayoutConstraint.activate([
                track.heightAnchor.constraint(equalToConstant: height),

                fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
                fill.topAnchor.constraint(equalTo: track.topAnchor),
                fill.bottomAnchor.constraint(equalTo: track.bottomAnchor),
                widthConstraint
            ])

            return (track, widthConstraint)
        }
        
        let bar1Track = UIView()
        let bar1Fill  = UIView()

        let bar2Track = UIView()
        let bar2Fill  = UIView()
        
        let (bar1View, bar1WidthConstraint) = makeBar(track: bar1Track, fill: bar1Fill, height: 8)
        let (bar2View, bar2WidthConstraint) = makeBar(track: bar2Track, fill: bar2Fill, height: 8)

        let bars = UIStackView(arrangedSubviews: [bar1View, bar2View])
        parentView.layoutIfNeeded()
        print(bar1Track.bounds.width)
        UIView.animate(withDuration: 0.25) {
            bar1WidthConstraint.constant = bar1Track.bounds.width * 0.7
            bar2WidthConstraint.constant = bar2Track.bounds.width * 0.7
            cardView.layoutIfNeeded()
        }
        

        bars.axis = .vertical
        bars.spacing = 10
        bars.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(topRowGrouper)
        containerView.addSubview(bars)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: cardView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            topRowGrouper.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
            topRowGrouper.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            topRowGrouper.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            bars.topAnchor.constraint(equalTo: topRowGrouper.bottomAnchor, constant: 12),
            bars.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            bars.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            bars.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -14)
        ])
        
        //MARK: Time to style this bitch
        
        containerView.backgroundColor     = UIColor.systemGray6
        containerView.layer.cornerRadius  = 18
        containerView.layer.masksToBounds = true
        
        // style titles
        [caloriesTitle, proteinTitle, carbsTitle].forEach {
            $0.font = .systemFont(ofSize: 14, weight: .semibold)
            $0.textColor = .secondaryLabel
        }
        
        
        func valueSetter(current: String, goal: String) -> NSAttributedString {
            let big = UIFont.systemFont(ofSize: 26, weight: .bold)
            let small = UIFont.systemFont(ofSize: 16, weight: .semibold)

            let result = NSMutableAttributedString(
                string: current,
                attributes: [.font: big, .foregroundColor: UIColor.label]
            )
            result.append(NSAttributedString(
                string: goal,
                attributes: [.font: small, .foregroundColor: UIColor.secondaryLabel]
            ))
            return result
        }
        
       
        caloriesValue.attributedText = valueSetter(current: "\(calorieCurrent)", goal: "/\(calorieGoal)")
        proteinValue.attributedText  = valueSetter(current: "\(proteinCurrent)", goal: "/\(proteinGoal)")
        carbsValue.attributedText    = valueSetter(current: "\(carbsCurrent)", goal: "/\(carbsGoal)")

        caloriesTitle.text = "Calories"
        proteinTitle.text = "Protein"
        carbsTitle.text = "Carbs"
        
        proteinValue.textColor = .label
        carbsValue.textColor = .label
        
        [divider1, divider2].forEach {
            $0.backgroundColor = UIColor.systemGray3.withAlphaComponent(0.6)
        }
        
        [bar1Track, bar2Track].forEach {
            $0.backgroundColor = UIColor.systemGray4.withAlphaComponent(0.6)
            $0.layer.masksToBounds = true
        }
        
        bar1Fill.backgroundColor = .systemBlue
        bar2Fill.backgroundColor = UIColor.systemGray2
        
        func roundBar(track: UIView, fill: UIView) {
            track.layer.cornerRadius = track.bounds.height / 2
            fill.layer.cornerRadius = fill.bounds.height / 2
        }
        
        //call layourIfneeded to get all of the bounds and stufff before rounding the stuff
        cardView.layoutIfNeeded()
        roundBar(track: bar1Track, fill: bar1Fill)
        roundBar(track: bar2Track, fill: bar2Fill)
        
        
        
        
        
        
        
        return containerView
        
    }
    
    struct attributedText {
        let text: String
        let fontsize: CGFloat
        let colour: UIColor
        let fontWeight: UIFont.Weight

        init(
            text: String,
            fontsize: CGFloat = 20,
            colour: UIColor = .label,
            fontWeight: UIFont.Weight = .semibold
        ) {
            self.text = text
            self.fontsize = fontsize
            self.colour = colour
            self.fontWeight = fontWeight
        }
    }
    
    static func makeAttributedString(textArray:[attributedText]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        textArray.forEach {
            let font = UIFont.systemFont(ofSize: $0.fontsize, weight: $0.fontWeight)
                    result.append(NSAttributedString(
                        string: $0.text,
                        attributes: [.font: font, .foregroundColor: $0.colour]
                    ))
            
        }
        return result
    }
    
    //MARK: MacroSummarCard End ----------
    
    
    static func makeProgressBar(track: UIView, fill: UIView, height: CGFloat) -> UIView {
        track.translatesAutoresizingMaskIntoConstraints = false
        fill.translatesAutoresizingMaskIntoConstraints = false

        track.addSubview(fill)

        NSLayoutConstraint.activate([
            track.heightAnchor.constraint(equalToConstant: height),

            fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
            fill.topAnchor.constraint(equalTo: track.topAnchor),
            fill.bottomAnchor.constraint(equalTo: track.bottomAnchor),

            // start at 0 width; we’ll update in setProgress(...)
            fill.widthAnchor.constraint(equalToConstant: 0)
        ])

        return track
    }
    
    static func createCircularProgressView(
        withText text: String,
        duration: TimeInterval = 300,
        diameter: CGFloat = 150  // change this to make the circle bigger/smaller
    ) -> UIView {
        let containerView = UIView()
        containerView.layer.cornerRadius = 16
        containerView.layer.masksToBounds = true
        
        // Circle container
        let circleContainer = UIView()
        circleContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(circleContainer)
        
        // Labels go *inside* the circle
        let titleLabel = UILabel()
        titleLabel.text = text.uppercased()
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let timeLabel = UILabel()
        timeLabel.text = "0.0"
        timeLabel.textColor = .white
        timeLabel.font = .systemFont(ofSize: 32, weight: .bold)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        circleContainer.addSubview(titleLabel)
        circleContainer.addSubview(timeLabel)
        
        // Shape layers
        let trackLayer = CAShapeLayer()
        trackLayer.strokeColor = UIColor.systemGray6.cgColor
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineWidth = 8
        trackLayer.lineCap = .round
        circleContainer.layer.addSublayer(trackLayer)
        
        let progressLayer = CAShapeLayer()
        progressLayer.strokeColor = UIColor.systemBlue.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 8
        progressLayer.strokeEnd = 0
        progressLayer.lineCap = .round
        circleContainer.layer.addSublayer(progressLayer)
        
        // Constraints
        NSLayoutConstraint.activate([
            circleContainer.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            circleContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            circleContainer.widthAnchor.constraint(equalToConstant: diameter),
            circleContainer.heightAnchor.constraint(equalToConstant: diameter),
            circleContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            // Labels inside circle
            titleLabel.centerXAnchor.constraint(equalTo: circleContainer.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: circleContainer.topAnchor, constant: 65),
            
            timeLabel.centerXAnchor.constraint(equalTo: circleContainer.centerXAnchor),
            timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8)
        ])
        
        // Compute circle path *after* layout
        DispatchQueue.main.async {
            let b = circleContainer.bounds
            let radius = min(b.width, b.height) / 2 - progressLayer.lineWidth - 2
            let center = CGPoint(x: b.midX, y: b.midY)
            let path = UIBezierPath(
                arcCenter: center,
                radius: radius,
                startAngle: -.pi/2,
                endAngle: 3 * .pi/2,
                clockwise: true
            )
            trackLayer.path = path.cgPath
            progressLayer.path = path.cgPath
        }
        
        // Timer updates progress
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if SetrepManager.shared.toDoHasCompletedSetRep() {
                let latest = SetrepManager.shared.getLatestSetRep(setrepArray: SetrepManager.shared.Setreps)
                let restTime = latest.finishTime?.timeIntervalSinceNow ?? 0
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
                       foodtracker:Selector) {
        view.addSubview(toolbar)
        toolbar.layer.masksToBounds = true
        toolbar.backgroundColor = .systemBackground
        toolbar.isTranslucent = false
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        let settingsButton = createCustomButton(imageName: "gearshape", action: settingsSelector)
        let viewWorkoutButton = createCustomButton(imageName: "dumbbell", action: viewWorkoutSelector)
        let startWorkoutButton = createCustomButton(imageName: "play", action: startWorkoutSelector)
        let finishWorkoutButton = createCustomButton(imageName: "stop", action: finishWorkoutSelector)
        let foodtracker = createCustomButton(imageName: "fork.knife", action: foodtracker)
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        toolbar.items = [
            flexibleSpace, settingsButton,
            flexibleSpace, viewWorkoutButton,
            flexibleSpace, startWorkoutButton,
            flexibleSpace, finishWorkoutButton,
            flexibleSpace, foodtracker,
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
