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
    private var syncTask: Task<Void, Error>?
    private var syncGeneration = 0

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
    }

    /// Sync each row using its modification date; failed uploads stay newer locally.
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

            // Copy only rows newer than the local value, preserving their timestamp.
            for entry in remote where Self.syncableNames.contains(entry.settingName) {
                if let local = getSetting(name: entry.settingName) {
                    guard entry.moddate > (local.modDate ?? .distantPast) else { continue }
                    local.value = entry.value
                    local.modDate = entry.moddate
                } else {
                    let local = Setting(context: context)
                    local.settingName = entry.settingName
                    local.value = entry.value
                    local.modDate = entry.moddate
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
                return AccountSettingDTO(settingName: name, value: value, moddate: setting.modDate ?? .distantPast)
            }
            let upload = Self.settingsToUpload(local: local, remote: remote)
            guard !upload.isEmpty else { return }
            try await DBConnector.shared.upsertSettings(i_payload: upload, i_sessionid: session)
            try checkSyncSession(session, generation: generation)

            // Fetch again to settle server-side races or edits made during upload.
        } while true
    }

    static func settingsToUpload(local: [AccountSettingDTO],
                                 remote: [AccountSettingDTO]) -> [AccountSettingDTO] {
        var serverDates: [String: Date] = [:]
        for entry in remote { serverDates[entry.settingName] = entry.moddate }
        return local.filter { row in
            guard syncableNames.contains(row.settingName) else { return false }
            guard let serverDate = serverDates[row.settingName] else { return true }
            return row.moddate > serverDate
        }
    }

    private func queueSettingsSync() {
        guard currentSession != nil else { return }
        Task { @MainActor in
            do {
                try await syncSettings()
            } catch {
                // The local date remains newer, so the next sync retries naturally.
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
                let previousDate = setting.modDate
                setting.value = newValue
                // Match the millisecond precision used in the JSON timestamp.
                let nowMillis = floor(Date().timeIntervalSince1970 * 1000)
                let previousMillis = floor((previousDate ?? .distantPast).timeIntervalSince1970 * 1000)
                setting.modDate = Date(timeIntervalSince1970: max(nowMillis, previousMillis + 1) / 1000)
                guard saveSettings() else {
                    setting.value = previousValue
                    setting.modDate = previousDate
                    return
                }
                if Self.syncableNames.contains(name) {
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
            settings = try context.fetch(fetchRequest)
            // Old stores have no timestamp; their values are older than dated account settings.
            for setting in settings where setting.modDate == nil {
                setting.modDate = .distantPast
            }
            if context.hasChanges { try context.save() }
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
        newSetting.modDate = .distantPast
        
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


