import UIKit

struct TextField {
    let labelName: String
    let keyboardType: UIKeyboardType
    let uiTextfield: UITextField
    let useLabelNameAsPlaceHolder: Bool
    let delegate: UITextFieldDelegate
}

struct DropdownField {
    let labelName: String
    let button: UIButton
    let options: [String]
    let selectedOption: String?
}

enum FormField {
    case textField(TextField)
    case dropdown(DropdownField)
}

class workoutDesigns {

    static func setupTextField(
        _ tf: UITextField,
        placeholder: String,
        keyboardType: UIKeyboardType,
        delegate: UITextFieldDelegate?
    ) {
        tf.borderStyle = .none
        tf.backgroundColor = WorkoutTheme.background
        tf.layer.cornerRadius = 12
        tf.font = .preferredFont(forTextStyle: .body)
        tf.adjustsFontForContentSizeCategory = true
        let inset = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        tf.leftView = inset
        tf.leftViewMode = .always
        tf.placeholder = placeholder
        tf.keyboardType = keyboardType
        tf.delegate = delegate
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.isUserInteractionEnabled = true

        tf.heightAnchor.constraint(equalToConstant: 50).isActive = true

        tf.clearButtonMode = .whileEditing
        tf.returnKeyType = .done
    }

    static func setupDropdown(_ field: DropdownField) {
        let button = field.button

        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.showsMenuAsPrimaryAction = true
        button.contentHorizontalAlignment = .fill

        let selectedOption =
            field.selectedOption ??
            field.options.first ??
            "Select"

        var configuration = UIButton.Configuration.gray()
        configuration.title = selectedOption
        configuration.cornerStyle = .medium
        configuration.image = UIImage(systemName: "chevron.down")
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 8

        button.configuration = configuration

        button.menu = createDropdownMenu(
            options: field.options,
            selectedOption: selectedOption,
            button: button
        )
    }

    private static func createDropdownMenu(
        options: [String],
        selectedOption: String,
        button: UIButton
    ) -> UIMenu {
        let actions = options.map { option in
            UIAction(
                title: option,
                state: option == selectedOption ? .on : .off
            ) { [weak button] _ in
                guard let button else {
                    return
                }

                var configuration = button.configuration
                configuration?.title = option
                button.configuration = configuration

                button.menu = createDropdownMenu(
                    options: options,
                    selectedOption: option,
                    button: button
                )
            }
        }

        return UIMenu(children: actions)
    }

    /*
     New method supporting both text fields and dropdowns.
     */
    static func createRoundedSquareView(
        fields: [FormField]
    ) -> UIView {
        let containerView = UIView()
        WorkoutTheme.card(containerView)
        containerView.layer.cornerRadius = 16
        containerView.layer.masksToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(
                equalTo: containerView.topAnchor,
                constant: 16
            ),
            stackView.leadingAnchor.constraint(
                equalTo: containerView.leadingAnchor,
                constant: 16
            ),
            stackView.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor,
                constant: -16
            ),
            stackView.bottomAnchor.constraint(
                equalTo: containerView.bottomAnchor,
                constant: -16
            )
        ])

        for field in fields {
            switch field {
            case let .textField(textField):
                setupTextField(
                    textField.uiTextfield,
                    placeholder: textField.useLabelNameAsPlaceHolder
                        ? textField.labelName
                        : textField.uiTextfield.placeholder ?? "",
                    keyboardType: textField.keyboardType,
                    delegate: textField.delegate
                )

                addFormControl(
                    labelName: textField.labelName,
                    control: textField.uiTextfield,
                    to: stackView
                )

            case let .dropdown(dropdown):
                setupDropdown(dropdown)

                addFormControl(
                    labelName: dropdown.labelName,
                    control: dropdown.button,
                    to: stackView
                )
            }
        }

        return containerView
    }

    /*
     Your original method is preserved so existing code does not break.
     */
    static func createRoundedSquareViewWithTextFields(
        textFields: [TextField]
    ) -> UIView {
        let fields = textFields.map {
            FormField.textField($0)
        }

        return createRoundedSquareView(fields: fields)
    }

    private static func addFormControl(
        labelName: String,
        control: UIView,
        to stackView: UIStackView
    ) {
        let label = UILabel()
        label.text = labelName
        label.font = UIFont.preferredFont(forTextStyle: .body)

        let fieldStack = UIStackView(
            arrangedSubviews: [
                label,
                control
            ]
        )

        fieldStack.axis = .vertical
        fieldStack.spacing = 4

        stackView.addArrangedSubview(fieldStack)
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

    static func makeAttributedString(
        textArray: [attributedText]
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()

        textArray.forEach {
            let font = UIFont.systemFont(
                ofSize: $0.fontsize,
                weight: $0.fontWeight
            )

            result.append(
                NSAttributedString(
                    string: $0.text,
                    attributes: [
                        .font: font,
                        .foregroundColor: $0.colour
                    ]
                )
            )
        }

        return result
    }

    // MARK: MacroSummarCard End ----------

    static func makeProgressBar(
        track: UIView,
        fill: UIView,
        height: CGFloat
    ) -> UIView {
        track.translatesAutoresizingMaskIntoConstraints = false
        fill.translatesAutoresizingMaskIntoConstraints = false

        track.addSubview(fill)

        NSLayoutConstraint.activate([
            track.heightAnchor.constraint(equalToConstant: height),

            fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
            fill.topAnchor.constraint(equalTo: track.topAnchor),
            fill.bottomAnchor.constraint(equalTo: track.bottomAnchor),

            fill.widthAnchor.constraint(equalToConstant: 0)
        ])

        return track
    }

    static func updateLabelText(
        in view: UIView,
        newText: String
    ) {
        if let label = view.subviews
            .compactMap({ $0 as? UILabel })
            .first {
            label.text = newText
        }
    }

    static func createStyledButton(
        title: String,
        titleFontSize: CGFloat = 16,
        imageSize: CGFloat = 16,
        systemImageName: String? = nil,
        backgroundColor: UIColor = WorkoutTheme.accent,
        borderColor: UIColor = WorkoutTheme.accent,
        textColor: UIColor = WorkoutTheme.onAccent,
        cornerRadius: CGFloat = 20,
        width: CGFloat = 40,
        height: CGFloat = 40
    ) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.image = systemImageName.flatMap { UIImage(systemName: $0) }
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: imageSize, weight: .semibold)
        configuration.imagePadding = 10
        configuration.baseBackgroundColor = backgroundColor
        configuration.baseForegroundColor = textColor
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        configuration.background.cornerRadius = cornerRadius
        configuration.background.strokeColor = borderColor
        configuration.background.strokeWidth = backgroundColor == .clear ? 1 : 0
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var attributes = incoming
            attributes.font = UIFont.systemFont(ofSize: titleFontSize, weight: .semibold)
            return attributes
        }
        button.configuration = configuration
        button.accessibilityLabel = title.isEmpty ? systemImageName : title
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: max(44, height)).isActive = true
        let minimumWidth = button.widthAnchor.constraint(greaterThanOrEqualToConstant: width)
        minimumWidth.priority = .defaultHigh
        minimumWidth.isActive = true

        return button
    }
}

extension UIViewController {

    func setupToolbar(
        toolbar: UIToolbar,
        settingsSelector: Selector,
        viewWorkoutSelector: Selector,
        startWorkoutSelector: Selector,
        finishWorkoutSelector: Selector,
        foodtracker: Selector
    ) {
        view.addSubview(toolbar)

        toolbar.layer.masksToBounds = true
        toolbar.backgroundColor = .systemBackground
        toolbar.isTranslucent = false
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        let settingsButton = createCustomButton(
            imageName: "gearshape",
            action: settingsSelector
        )

        let viewWorkoutButton = createCustomButton(
            imageName: "dumbbell",
            action: viewWorkoutSelector
        )

        let startWorkoutButton = createCustomButton(
            imageName: "play",
            action: startWorkoutSelector
        )

        let finishWorkoutButton = createCustomButton(
            imageName: "stop",
            action: finishWorkoutSelector
        )

        let foodtrackerButton = createCustomButton(
            imageName: "fork.knife",
            action: foodtracker
        )

        let flexibleSpace = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )

        toolbar.items = [
            flexibleSpace,
            settingsButton,
            flexibleSpace,
            viewWorkoutButton,
            flexibleSpace,
            startWorkoutButton,
            flexibleSpace,
            finishWorkoutButton,
            flexibleSpace,
            foodtrackerButton,
            flexibleSpace
        ]

        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            toolbar.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            toolbar.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -15
            ),
            toolbar.heightAnchor.constraint(
                equalToConstant: 55
            )
        ])
    }

    private func createCustomButton(
        imageName: String,
        action: Selector
    ) -> UIBarButtonItem {
        let button = UIButton(type: .system)

        let configuration = UIImage.SymbolConfiguration(
            pointSize: 25
        )

        button.setImage(
            UIImage(
                systemName: imageName,
                withConfiguration: configuration
            ),
            for: .normal
        )

        button.addTarget(
            self,
            action: action,
            for: .touchUpInside
        )

        return UIBarButtonItem(customView: button)
    }
}


/// Shared semantic colors preserve contrast in both system appearances.
enum WorkoutTheme {
    static let accent = UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.32, green: 0.86, blue: 0.77, alpha: 1)
        : UIColor(red: 0.02, green: 0.43, blue: 0.38, alpha: 1) }
    static let onAccent = UIColor { $0.userInterfaceStyle == .dark ? .black : .white }
    static let background = UIColor.systemGroupedBackground
    static let surface = UIColor.secondarySystemGroupedBackground

    static func card(_ view: UIView) {
        view.backgroundColor = surface
        view.layer.cornerRadius = 22
        view.layer.cornerCurve = .continuous
    }

    static func section(_ title: String, subtitle: String) -> UIView {
        let heading = UILabel()
        heading.text = title
        heading.font = .preferredFont(forTextStyle: .title2)
        heading.adjustsFontForContentSizeCategory = true
        heading.numberOfLines = 0
        heading.accessibilityTraits = .header
        let detail = UILabel()
        detail.text = subtitle
        detail.font = .preferredFont(forTextStyle: .subheadline)
        detail.adjustsFontForContentSizeCategory = true
        detail.textColor = .secondaryLabel
        detail.numberOfLines = 0
        let stack = UIStackView(arrangedSubviews: [heading, detail])
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }

    static func applyNavigation(to navigation: UINavigationController) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = background
        appearance.shadowColor = .clear
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        navigation.navigationBar.standardAppearance = appearance
        navigation.navigationBar.scrollEdgeAppearance = appearance
        navigation.navigationBar.compactAppearance = appearance
        navigation.navigationBar.prefersLargeTitles = true
        navigation.navigationBar.tintColor = accent
        navigation.view.backgroundColor = background
    }
}
