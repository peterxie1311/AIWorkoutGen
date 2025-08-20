import CoreData
import UIKit

class SettingsManager {
    // Singleton instance
    static let shared = SettingsManager()
    
    // Stored settings as an array of Setting objects
    var settings: [Setting] = [] // Change to [Setting] to hold Core Data objects

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
        print("No Setting found !")
        return nil
    }
    
    func updateSetting(name: String, newValue: String) {
        for setting in settings {
            if setting.settingName == name {
                setting.value = newValue
                saveSettings() // Save after updating
                break // Exit loop after updating
            }
        }
    }
    func clearSettings() {
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
    func initSettings (){
        clearSettings()
        addSetting(name: "Name", value: "")
        addSetting(name: "Enable Notifications", value: "true")
        addSetting(name: "GPT API Key", value: "")
        addSetting(name: "Exclude Workout", value: "")
        
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
    func saveSettings() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        // Save the context
        do {
            try context.save()
            NotificationCenter.default.post(name: NSNotification.Name("settings"), object: nil)
            print("Settings saved successfully!")
        } catch {
            print("Failed to save settings: \(error)")
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
            print("New setting added: \(name) = \(value)")
            loadSettings() // Optionally reload settings after adding
        } catch {
            print("Failed to add new setting: \(error)")
        }
    }
}
