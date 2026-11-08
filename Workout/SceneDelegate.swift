import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var openingTask: Task<Void, Never>?
    private(set) var isOpeningWorkout = false

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        window.tintColor = WorkoutTheme.accent

        // Add missing settings without resetting existing user preferences.
        for entry in SettingsManager.shared.defaultSettings {
            if SettingsManager.shared.getSetting(name: entry[0]) == nil {
                SettingsManager.shared.addSetting(name: entry[0], value: entry[1])
            }
        }
        workoutAIservice.shared.loadSessionApiKey()
        routeToSession()
        window.makeKeyAndVisible()
    }

    private func routeToSession() {
        let sessionKey = SettingsManager.shared.getSetting(name: SettingsManager.sessionKey)?.value
        if LogonViewController.requiresLogon(sessionKey) {
            showLogon()
        } else {
            openWorkout()
        }
    }
    func showExpiredSessionLogon(message: String) {
        showLogon(message: message)
    }

    private func showLogon(message: String? = nil) {
        openingTask?.cancel()
        openingTask = nil
        isOpeningWorkout = false
        let logon = LogonViewController()
        logon.sessionMessage = message
        logon.onLogon = { [weak self] in
            self?.openWorkout()
        }
        window?.rootViewController = logon
    }

    private func openWorkout() {
        guard openingTask == nil else { return }
        DBConnector.shared.loadSessionToken()
        let session = SettingsManager.shared.getSetting(name: SettingsManager.sessionKey)?.value
        let loading = UIViewController()
        loading.view.backgroundColor = WorkoutTheme.background
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.accessibilityLabel = "Loading account settings"
        spinner.translatesAutoresizingMaskIntoConstraints = false
        loading.view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: loading.view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: loading.view.centerYAnchor)
        ])
        spinner.startAnimating()
        isOpeningWorkout = true
        window?.rootViewController = loading

        openingTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            var settingsSyncFailed = false
            do {
                try await SettingsManager.shared.syncSettings()
            } catch is APIResponseError {
                // The shared API alert already shows the server message.
            } catch {
                settingsSyncFailed = true
            }
            guard !Task.isCancelled,
                  self.window?.rootViewController === loading,
                  SettingsManager.shared.getSetting(name: SettingsManager.sessionKey)?.value == session else {
                return
            }
            workoutAIservice.shared.loadSessionApiKey()
            let navigation = UINavigationController(rootViewController: WorkoutAIViewController())
            WorkoutTheme.applyNavigation(to: navigation)
            self.window?.rootViewController = navigation
            self.isOpeningWorkout = false

            if settingsSyncFailed {
                let alert = UIAlertController(
                    title: "Settings could not sync",
                    message: "Your local settings are still available. Pending changes will retry when you reopen the app.",
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
                    self?.openingTask?.cancel()
                    self?.openingTask = nil
                    self?.openWorkout()
                })
                navigation.present(alert, animated: true)
            }
            APIMessageAlert.presentNext()
            await WorkoutSessionManager.shared.syncWorkoutSessionEntries()
            guard !Task.isCancelled else { return }
            await FoodLogManager.shared.syncFoodLogEntries()
            guard !Task.isCancelled else { return }
            self.openingTask = nil
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        let sessionKey = SettingsManager.shared.getSetting(name: SettingsManager.sessionKey)?.value
        if LogonViewController.requiresLogon(sessionKey) {
            if !(window?.rootViewController is LogonViewController) { showLogon() }
        } else if window?.rootViewController is LogonViewController {
            openWorkout()
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        APIMessageAlert.presentNext()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}

