import UIKit
import CoreData

/// Session-key entry for the app's existing sync identity.
final class LogonViewController: UIViewController, UITextFieldDelegate {
    var onLogon: (() -> Void)?
    var sessionMessage: String?
    private let userNameField = UITextField()
    private let passwordField = UITextField()
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
        if let sessionMessage {
            subtitle.text = "\(sessionMessage) Sign in with your original account to sync the data saved on this device."
        } else {
            subtitle.text = "Sign in with your username and password. If this device has saved data, use the account it belongs to."
        }
        subtitle.font = .preferredFont(forTextStyle: .body)
        subtitle.adjustsFontForContentSizeCategory = true
        subtitle.textColor = .secondaryLabel
        subtitle.numberOfLines = 0

        let fieldLabel = UILabel()
        fieldLabel.text = "Login"
        fieldLabel.font = .preferredFont(forTextStyle: .headline)
        fieldLabel.adjustsFontForContentSizeCategory = true

        userNameField.placeholder = "User Name"
        userNameField.text = DBConnector.shared.localAccountUsername
        userNameField.accessibilityLabel = "User Name"
        userNameField.accessibilityIdentifier = "logon.userName"
        userNameField.font = .preferredFont(forTextStyle: .body)
        userNameField.adjustsFontForContentSizeCategory = true
        userNameField.isSecureTextEntry = true
        userNameField.autocapitalizationType = .none
        userNameField.autocorrectionType = .no
        userNameField.smartQuotesType = .no
        userNameField.smartDashesType = .no
        userNameField.spellCheckingType = .no
        userNameField.returnKeyType = .go
        userNameField.delegate = self
        userNameField.backgroundColor = WorkoutTheme.background
        userNameField.layer.cornerRadius = Constants.Design.Radius.field
        userNameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        userNameField.leftViewMode = .always
        userNameField.heightAnchor.constraint(greaterThanOrEqualToConstant: 54).isActive = true
        userNameField.addTarget(self, action: #selector(clearError), for: .editingChanged)
        
        passwordField.placeholder = "Password"
        passwordField.accessibilityLabel = "Password"
        passwordField.accessibilityIdentifier = "logon.password"
        passwordField.font = .preferredFont(forTextStyle: .body)
        passwordField.adjustsFontForContentSizeCategory = true
        passwordField.isSecureTextEntry = true
        passwordField.autocapitalizationType = .none
        passwordField.autocorrectionType = .no
        passwordField.smartQuotesType = .no
        passwordField.smartDashesType = .no
        passwordField.spellCheckingType = .no
        passwordField.returnKeyType = .go
        passwordField.delegate = self
        passwordField.backgroundColor = WorkoutTheme.background
        passwordField.layer.cornerRadius = Constants.Design.Radius.field
        passwordField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        passwordField.leftViewMode = .always
        passwordField.heightAnchor.constraint(greaterThanOrEqualToConstant: 54).isActive = true
        passwordField.addTarget(self, action: #selector(clearError), for: .editingChanged)

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
        configuration.background.cornerRadius = Constants.Design.Radius.button
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        continueButton.configuration = configuration
        continueButton.accessibilityIdentifier = "logon.continue"
        continueButton.addTarget(self, action: #selector(logOn), for: .touchUpInside)

        let form = UIStackView(arrangedSubviews: [fieldLabel, userNameField, passwordField,errorLabel, continueButton])
        form.axis = .vertical
        form.spacing = 14
        form.isLayoutMarginsRelativeArrangement = true
        form.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 22, leading: 22, bottom: 22, trailing: 22)
        WorkoutTheme.card(form)

        let stack = UIStackView(arrangedSubviews: [icon, title, subtitle, form])
        stack.axis = .vertical
        stack.spacing = Constants.Design.Spacing.section
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
        guard continueButton.isEnabled else { return }

        let username = userNameField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text ?? ""

        guard !username.isEmpty else {
            showError("Enter your username.")
            userNameField.becomeFirstResponder()
            return
        }

        guard !password.isEmpty else {
            showError("Enter your password.")
            passwordField.becomeFirstResponder()
            return
        }

        if DBConnector.shared.needsLegacyAccountConfirmation {
            let alert = UIAlertController(
                title: "Sync saved data?",
                message: "Continue only if this is the same account you previously used on this device.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Sign In and Sync", style: .default) { [weak self] _ in
                self?.signIn(username: username, password: password)
            })
            present(alert, animated: true)
            return
        }
        signIn(username: username, password: password)
    }

    private func signIn(username: String, password: String) {
        clearError()
        view.endEditing(true)

        continueButton.isEnabled = false
        continueButton.configuration?.showsActivityIndicator = true
        userNameField.isEnabled = false
        passwordField.isEnabled = false

        Task { @MainActor in
            defer {
                continueButton.isEnabled = true
                continueButton.configuration?.showsActivityIndicator = false
                userNameField.isEnabled = true
                passwordField.isEnabled = true
            }

            do {
                try await DBConnector.shared.login(
                    i_username: username,
                    i_password: password
                )

                passwordField.text = nil
                onLogon?()
            } catch is APIResponseError {
                // The shared API alert already shows the server message.
            } catch {
                showError(error.localizedDescription)
            }
        }
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
