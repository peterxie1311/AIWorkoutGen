import UIKit
import CoreData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var openingTask: Task<Void, Never>?

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
    private func clearAllCoreData() throws {
        SettingsManager.shared.resetSettingsSync()
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            throw NSError(
                domain: "SceneDelegate",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Could not access local storage."
                ]
            )
        }

        let context = appDelegate.persistentContainer.viewContext

        do {
            for entity in appDelegate.persistentContainer
                .managedObjectModel.entities {

                guard let name = entity.name else { continue }

                let request = NSFetchRequest<NSManagedObject>(
                    entityName: name
                )
                request.includesSubentities = false

                for object in try context.fetch(request) {
                    context.delete(object)
                }
            }

            try context.save()
        } catch {
            context.rollback()
            throw error
        }

        SettingsManager.shared.settings.removeAll()

        // Login needs these settings to exist.
        for entry in SettingsManager.shared.defaultSettings {
            SettingsManager.shared.addSetting(
                name: entry[0],
                value: entry[1]
            )
        }

        DBConnector.shared.loadSessionToken()
        workoutAIservice.shared.loadSessionApiKey()
    }

    private func showLogon() {
        openingTask?.cancel()
        openingTask = nil
        do {
            try clearAllCoreData()
        } catch {
            let controller = UIViewController()
            controller.view.backgroundColor = WorkoutTheme.background
            window?.rootViewController = controller

            let alert = UIAlertController(
                title: "Could not clear local data",
                message: error.localizedDescription,
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(
                title: "Retry",
                style: .default
            ) { [weak self] _ in
                self?.showLogon()
            })

            DispatchQueue.main.async {
                controller.present(alert, animated: true)
            }
            return
        }

        let logon = LogonViewController()
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
        window?.rootViewController = loading

        openingTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            var settingsSyncFailed = false
            do {
                try await SettingsManager.shared.syncSettings()
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
            self.openingTask = nil

            if settingsSyncFailed {
                let alert = UIAlertController(
                    title: "Settings could not sync",
                    message: "Your local settings are still available. Pending changes will retry when you reopen the app.",
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
                    self?.openWorkout()
                })
                navigation.present(alert, animated: true)
            }
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

