import UIKit

class workoutDesigns {
    
   static func createRoundedSquareView(withText text: String) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemBlue
        containerView.layer.cornerRadius = 16 // Adjust for desired roundness
        containerView.layer.masksToBounds = true
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        }.cgColor
        
        // Add a label for the text
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(label)
        
        // Constraints for the label
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
       
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
        backgroundColor: UIColor = .systemBlue,
        cornerRadius: CGFloat = 20,
        width: CGFloat = 200,
        height: CGFloat = 50
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = backgroundColor
        
        // Styling for the button
        button.layer.cornerRadius = cornerRadius
        button.layer.borderWidth = 2
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 2, height: 2)
        button.layer.shadowRadius = 5
        
        // Set the border color dynamically based on the system appearance
        button.layer.borderColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        }.cgColor
        
        // Auto Layout constraints
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: height),
            button.widthAnchor.constraint(equalToConstant: width)
        ])
        
        return button
    }

}
