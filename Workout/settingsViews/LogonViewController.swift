import UIKit
import CoreData

/// Session-key entry for the app's existing sync identity.
final class LogonViewController: UIViewController, UITextFieldDelegate {
    var onLogon: (() -> Void)?
    private let sessionKeyField = UITextField()
    private let errorLabel = UILabel()
    private let continueButton = UIButton(type: .system)

    static func requiresLogon(_ sessionKey: String?) -> Bool {
        guard let sessionKey = sessionKey else { return true }
        return sessionKey == Constants.string_default ||
            sessionKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WorkoutTheme.background

        let scroll = UIScrollView()
        scroll.keyboardDismissMode = .interactive
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let icon = UIImageView(image: UIImage(systemName: "dumbbell.fill"))
        icon.tintColor = WorkoutTheme.accent
        icon.contentMode = .scaleAspectFit
        icon.heightAnchor.constraint(equalToConstant: 64).isActive = true
        icon.isAccessibilityElement = false

        let title = UILabel()
        title.text = "Your next chapter\nstarts here."
        title.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(
            for: .systemFont(ofSize: 34, weight: .bold))
        title.adjustsFontForContentSizeCategory = true
        title.numberOfLines = 0
        title.accessibilityTraits = .header

        let subtitle = UILabel()
        subtitle.text = "Log on with your session key to continue your training."
        subtitle.font = .preferredFont(forTextStyle: .body)
        subtitle.adjustsFontForContentSizeCategory = true
        subtitle.textColor = .secondaryLabel
        subtitle.numberOfLines = 0

        let fieldLabel = UILabel()
        fieldLabel.text = "Session key"
        fieldLabel.font = .preferredFont(forTextStyle: .headline)
        fieldLabel.adjustsFontForContentSizeCategory = true

        sessionKeyField.placeholder = "Enter your session key"
        sessionKeyField.accessibilityLabel = "Session key"
        sessionKeyField.accessibilityIdentifier = "logon.sessionKey"
        sessionKeyField.font = .preferredFont(forTextStyle: .body)
        sessionKeyField.adjustsFontForContentSizeCategory = true
        sessionKeyField.isSecureTextEntry = true
        sessionKeyField.autocapitalizationType = .none
        sessionKeyField.autocorrectionType = .no
        sessionKeyField.smartQuotesType = .no
        sessionKeyField.smartDashesType = .no
        sessionKeyField.spellCheckingType = .no
        sessionKeyField.returnKeyType = .go
        sessionKeyField.delegate = self
        sessionKeyField.backgroundColor = WorkoutTheme.background
        sessionKeyField.layer.cornerRadius = 12
        sessionKeyField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        sessionKeyField.leftViewMode = .always
        sessionKeyField.heightAnchor.constraint(greaterThanOrEqualToConstant: 54).isActive = true
        sessionKeyField.addTarget(self, action: #selector(clearError), for: .editingChanged)

        errorLabel.font = .preferredFont(forTextStyle: .footnote)
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        errorLabel.accessibilityIdentifier = "logon.error"

        var configuration = UIButton.Configuration.filled()
        configuration.title = "Log on"
        configuration.image = UIImage(systemName: "arrow.right")
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 10
        configuration.baseBackgroundColor = WorkoutTheme.accent
        configuration.baseForegroundColor = WorkoutTheme.onAccent
        configuration.background.cornerRadius = 14
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        continueButton.configuration = configuration
        continueButton.accessibilityIdentifier = "logon.continue"
        continueButton.addTarget(self, action: #selector(logOn), for: .touchUpInside)

        let form = UIStackView(arrangedSubviews: [fieldLabel, sessionKeyField, errorLabel, continueButton])
        form.axis = .vertical
        form.spacing = 14
        form.isLayoutMarginsRelativeArrangement = true
        form.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 22, leading: 22, bottom: 22, trailing: 22)
        WorkoutTheme.card(form)

        let stack = UIStackView(arrangedSubviews: [icon, title, subtitle, form])
        stack.axis = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 32),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -32),
            stack.centerXAnchor.constraint(equalTo: scroll.frameLayoutGuide.centerXAnchor),
            scroll.contentLayoutGuide.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
            stack.widthAnchor.constraint(lessThanOrEqualToConstant: 480),
            stack.widthAnchor.constraint(lessThanOrEqualTo: scroll.frameLayoutGuide.widthAnchor, constant: -40)
        ])
        let preferredWidth = stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40)
        preferredWidth.priority = .defaultHigh
        preferredWidth.isActive = true
    }

    @objc private func clearError() {
        errorLabel.isHidden = true
    }

    @objc private func logOn() {
        let key = sessionKeyField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let key = key, !Self.requiresLogon(key) else {
            showError("Enter your session key to continue.")
            sessionKeyField.becomeFirstResponder()
            return
        }
        guard let setting = SettingsManager.shared.getSetting(name: SettingsManager.sessionKey),
              let context = setting.managedObjectContext else {
            showError("Your settings could not be loaded. Please reopen the app and try again.")
            return
        }
        let previousValue = setting.value
        setting.value = key
        do {
            try context.save()
        } catch {
            setting.value = previousValue
            showError("Your session key could not be saved. Please try again.")
            return
        }
        continueButton.isEnabled = false
        view.endEditing(true)
        sessionKeyField.text = nil
        onLogon?()
    }

    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        logOn()
        return false
    }
}
