import CoreData
import UIKit

@MainActor
class SettingsManager {
    // Singleton instance
    static let shared = SettingsManager()
    
    //Settings constants
    static let name:String = "Name"
    static let enableNotifications:String = "Enable Notifications"
    static let gptAPIKey:String = "GPT API Key"
    static let excludeWorkout:String = "Exclude Workout"
    static let calorieGoal:String = "Calorie Goal"
    static let proteinGoal:String = "Protein Goal"
    static let carbGoal:String = "Carb Goal"
    static let sessionKey:String = "Session Key"
    
    
    // Stored settings as an array of Setting objects
    var settings: [Setting] = [] // Change to [Setting] to hold Core Data objects

    static let syncableNames: Set<String> = [
        name, enableNotifications, gptAPIKey, excludeWorkout,
        calorieGoal, proteinGoal, carbGoal
    ]
    private let pendingNamesKey = "SettingsManager.pendingAccountSettings"
    private var syncTask: Task<Void, Error>?
    private var syncGeneration = 0

    private var pendingNames: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: pendingNamesKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: pendingNamesKey) }
    }

    private var currentSession: String? {
        guard let value = getSetting(name: Self.sessionKey)?.value,
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return value
    }

    /// Call when clearing account data, before another user can log on.
    func resetSettingsSync() {
        syncGeneration += 1
        syncTask?.cancel()
        syncTask = nil
        pendingNames = []
    }

    /// Single owner of pull/merge/upload, including retries of locally saved edits.
    func syncSettings() async throws {
        if let task = syncTask {
            try await task.value
            return
        }
        guard let session = currentSession else { throw SettingsSyncError.missingSession }
        let generation = syncGeneration
        let task = Task { @MainActor in
            try await self.performSettingsSync(session: session, generation: generation)
        }
        syncTask = task
        defer {
            if syncGeneration == generation { syncTask = nil }
        }
        try await task.value
    }

    private func checkSyncSession(_ session: String, generation: Int) throws {
        try Task.checkCancellation()
        guard generation == syncGeneration, currentSession == session else {
            throw SettingsSyncError.sessionChanged
        }
    }

    private func performSettingsSync(session: String, generation: Int) async throws {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            throw SettingsSyncError.localStorage
        }
        let context = appDelegate.persistentContainer.viewContext
        repeat {
            try checkSyncSession(session, generation: generation)
            let remote = try await DBConnector.shared.fetchSettings(i_sessionid: session)
            try checkSyncSession(session, generation: generation)
            loadSettings()

            // Server values win unless this device has an unsent edit.
            for entry in remote where Self.syncableNames.contains(entry.settingName) {
                guard !pendingNames.contains(entry.settingName) else { continue }
                if let local = getSetting(name: entry.settingName) {
                    local.value = entry.value
                } else {
                    let local = Setting(context: context)
                    local.settingName = entry.settingName
                    local.value = entry.value
                    settings.append(local)
                }
            }
            do {
                try context.save()
            } catch {
                context.rollback()
                loadSettings()
                throw SettingsSyncError.localStorage
            }
            workoutAIservice.shared.loadSessionApiKey()
            NotificationCenter.default.post(name: NSNotification.Name("settings"), object: nil)

            let local = settings.compactMap { setting -> AccountSettingDTO? in
                guard let name = setting.settingName, let value = setting.value else { return nil }
                return AccountSettingDTO(settingName: name, value: value)
            }
            let upload = Self.settingsToUpload(local: local, remote: remote, pending: pendingNames)
            guard !upload.isEmpty else { return }
            try await DBConnector.shared.upsertSettings(i_payload: upload, i_sessionid: session)
            try checkSyncSession(session, generation: generation)

            // An edit made while uploading must remain queued.
            var pending = pendingNames
            for entry in upload {
                if getSetting(name: entry.settingName)?.value == entry.value {
                    pending.remove(entry.settingName)
                }
            }
            pendingNames = pending
        } while !pendingNames.isEmpty
    }

    /// Shared merge policy: never upload a session key or overwrite a saved
    /// account value with this device's defaults.
    static func settingsToUpload(local: [AccountSettingDTO], remote: [AccountSettingDTO],
                                 pending: Set<String>) -> [AccountSettingDTO] {
        let remoteNames = Set(remote.map { $0.settingName })
        return local.filter {
            syncableNames.contains($0.settingName) &&
                (pending.contains($0.settingName) || !remoteNames.contains($0.settingName))
        }
    }

    private func queueSettingsSync() {
        guard currentSession != nil else { return }
        Task { @MainActor in
            do {
                try await syncSettings()
            } catch {
                // Pending names remain persisted for the next sync attempt.
                NotificationCenter.default.post(
                    name: NSNotification.Name("settingsSyncFailed"), object: nil)
            }
        }
    }
    
    let defaultSettings: [[String]] = [
        [name,Constants.string_default],
        [enableNotifications,Constants.string_numDefault],
        [gptAPIKey,Constants.string_default],
        [excludeWorkout,Constants.string_default],
        [calorieGoal,Constants.string_numDefault],
        [proteinGoal,Constants.string_numDefault],
        [carbGoal,Constants.string_numDefault],
        [sessionKey,Constants.string_default]
    ]

    private init() {
        // Load settings from Core Data
        loadSettings()
    }
    
    func getSetting(name:String) -> Setting? {
        for setting in settings {
            if setting.settingName == name {
                return setting
            }
        }
        return nil
    }
    
    func getSettingDouble(name:String) -> Double {
        for setting in settings {
            if setting.settingName == name {
                return Double(setting.value ?? Constants.string_default) ?? Constants.num_defaultDouble
            }
        }
        return Constants.num_defaultDouble
    }
    
    func updateSetting(name: String, newValue: String) {
        for setting in settings {
            if setting.settingName == name {
                guard setting.value != newValue else { return }
                let previousValue = setting.value
                setting.value = newValue
                guard saveSettings() else {
                    setting.value = previousValue
                    return
                }
                if Self.syncableNames.contains(name) {
                    var pending = pendingNames
                    pending.insert(name)
                    pendingNames = pending
                    workoutAIservice.shared.loadSessionApiKey()
                    queueSettingsSync()
                }
                break // Exit loop after updating
            }
        }
    }
    func clearSettings() {
        resetSettingsSync()
        // Get the AppDelegate's managed object context
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        // Create a fetch request for the Setting
        let fetchRequest: NSFetchRequest<Setting> = Setting.fetchRequest()

        do {
            // Fetch all settings
            let settingsToDelete = try context.fetch(fetchRequest)
            
            // Delete each setting
            for setting in settingsToDelete {
                context.delete(setting)
            }
            
            // Save the context to persist the deletion
            try context.save()
            settings.removeAll() // Optionally update the in-memory settings array
            print("All settings have been cleared.")
        } catch {
            print("Failed to clear settings: \(error)")
        }
    }
    func initSettings(){
        clearSettings()
        for defaultSetting in defaultSettings {
            addSetting(name: defaultSetting[0], value: defaultSetting[1])
        }
    }
    
    func checkSettingsAndInitIfNecessary(){
        loadSettings()
        for defaultSetting in defaultSettings{
            if (getSetting(name: defaultSetting[0]) === nil){
                addSetting(name: defaultSetting[0], value: defaultSetting[1])
            }
        }
        // We also need to check for duplicates
        // make a set and if it appears twice then init
        var seenNames = Set<String>()
        for setting in settings {
            if seenNames.contains(setting.settingName ?? " ") {
                initSettings()
                break
            } else {
                seenNames.insert(setting.settingName ?? " ")
            }
        }
    }
    

    
    // Load settings from Core Data
    func loadSettings() {
        // Get the AppDelegate's managed object context
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        // Create a fetch request for the Setting
        let fetchRequest: NSFetchRequest<Setting> = Setting.fetchRequest()

        do {
            // Execute the fetch request
            settings = try context.fetch(fetchRequest) // Fetch and assign directly to settings
        } catch {
            print("Failed to load settings: \(error)")
        }
    }
    
    // Save settings to Core Data
    @discardableResult
    func saveSettings() -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        let context = appDelegate.persistentContainer.viewContext
        
        // Save the context
        do {
            try context.save()
            NotificationCenter.default.post(name: NSNotification.Name("settings"), object: nil)
            print("Settings saved successfully!")
            return true
        } catch {
            print("Failed to save settings: \(error)")
            return false
        }
    }
    
    
    func addSetting(name: String, value: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        // Create a new instance of Setting
        let newSetting = Setting(context: context)
        newSetting.settingName = name
        newSetting.value = value
        
        // Save the context
        do {
            try context.save()
            // Do not log setting values: they can contain credentials.
            loadSettings() // Optionally reload settings after adding
        } catch {
            print("Failed to add new setting: \(error)")
        }
    }
}

