import UIKit

/// Labeled destinations with comfortable touch targets and explicit action routing.
final class WorkoutToolBar: UIView {
    private let destinations = UIStackView()

    struct ToolBarItem {
        let imageName: String
        weak var target: AnyObject?
        let selector: Selector
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = WorkoutTheme.background
        destinations.axis = .horizontal
        destinations.distribution = .fillEqually
        destinations.spacing = 8
        destinations.translatesAutoresizingMaskIntoConstraints = false
        addSubview(destinations)
        NSLayoutConstraint.activate([
            destinations.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            destinations.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            destinations.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            destinations.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(toolbarItems: [ToolBarItem]) {
        destinations.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for item in toolbarItems {
            let title: String
            switch item.imageName {
            case "gearshape": title = "Settings"
            case "dumbbell": title = "History"
            case "fork.knife": title = "Nutrition"
            default: title = item.imageName
            }
            var configuration = UIButton.Configuration.plain()
            configuration.title = title
            configuration.image = UIImage(systemName: item.imageName)
            configuration.imagePlacement = .top
            configuration.imagePadding = 5
            configuration.baseForegroundColor = WorkoutTheme.accent
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var attributes = incoming
                attributes.font = UIFont.preferredFont(forTextStyle: .caption1)
                return attributes
            }
            let button = UIButton(configuration: configuration)
            button.accessibilityLabel = title
            button.addTarget(item.target, action: item.selector, for: .touchUpInside)
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            destinations.addArrangedSubview(button)
        }
    }
}
