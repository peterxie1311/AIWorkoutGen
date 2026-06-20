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
    
    

    
    static func updateLabelText(in view: UIView, newText: String) {
          // Look for the label in the container view by traversing the subviews
          if let label = view.subviews.compactMap({ $0 as? UILabel }).first {
              label.text = newText
          }
      }
    
    static func createStyledButton(
        title: String,
        titleFontSize:CGFloat = 16,
        imageSize:CGFloat = 16,
        systemImageName: String? = nil,
        backgroundColor: UIColor = .systemBlue,
        borderColor:UIColor      = .systemBlue,
        textColor:UIColor        = .white,
        cornerRadius: CGFloat = 20,
        width: CGFloat = 40 ,
        height: CGFloat = 40
    ) -> UIButton {
        let config = UIImage.SymbolConfiguration(pointSize: imageSize, weight: .medium, scale: .small)
        let button = UIButton(type: .system)
        if let systemImageName = systemImageName {
                let image = UIImage(systemName: systemImageName,withConfiguration: config)
                button.setImage(image, for: .normal)
                button.tintColor = textColor
                button.imageView?.contentMode = .scaleAspectFit
            button.semanticContentAttribute = .forceRightToLeft
            button.setTitle(title , for: .normal)
                
            } else {
                button.setTitle(title, for: .normal)
            }
        button.setTitleColor(textColor, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: titleFontSize, weight: .semibold)
        button.backgroundColor = backgroundColor
      
        
        // Styling for the button
        button.layer.cornerRadius = height/2
//        button.layer.borderWidth = 2
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 2, height: 2)
        button.layer.shadowRadius = 5
        button.layer.borderWidth  = 2
        button.layer.borderColor  = borderColor.cgColor
        
        // Auto Layout constraints
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: height),
            button.widthAnchor.constraint(equalToConstant: width),
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
