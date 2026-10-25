import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

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

    private func showLogon() {
        let logon = LogonViewController()
        logon.onLogon = { [weak self] in self?.openWorkout() }
        window?.rootViewController = logon
    }

    private func openWorkout() {
        DBConnector.shared.loadSessionToken()
        let navigation = UINavigationController(rootViewController: WorkoutAIViewController())
        WorkoutTheme.applyNavigation(to: navigation)
        window?.rootViewController = navigation
        Task {
            await WorkoutSessionManager.shared.syncWorkoutSessionEntries()
            await FoodLogManager.shared.syncFoodLogEntries()
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

    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}
