import UIKit

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    override var prefersHomeIndicatorAutoHidden: Bool {
           return true
       }
    let tableView = UITableView()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = .white
        setupStackView()
        setupTableView()
        initializeSettings() // Call to initialize settings
    }
    
    func setupStackView(){
        
        let stackView = UIStackView(arrangedSubviews: [tableView])
        stackView.axis                                      = .vertical
        stackView.spacing                                   = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView )
        NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SettingsTableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
       // view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        
    }
    
    func initializeSettings() {
        // Check if any settings already exist
        let existingSettings = SettingsManager.shared.settings
        
        var seenNames = Set<String>()

        for setting in existingSettings {
            if seenNames.contains(setting.settingName ?? " ") {
                SettingsManager.shared.initSettings()
                break
            } else {
                seenNames.insert(setting.settingName ?? " ")
            }
        }
        
        if existingSettings.isEmpty {
            // No settings found, create default settings
            SettingsManager.shared.initSettings()
        }
    }
    
    // DataSource Methods
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // Assuming all settings are in one section
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SettingsManager.shared.settings.count // Return the number of settings
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath) as! SettingsTableViewCell
        let setting = SettingsManager.shared.settings[indexPath.row]
        
        // Configure cell based on setting type
      
            cell.isSwitch = false
            cell.textField.text = setting.value 
            cell.textField.placeholder = setting.settingName
            cell.textField.delegate = self // Set self as delegate to handle text changes
        
        
        return cell
    }
    
    @objc func switchValueChanged(_ sender: UISwitch) {
        // Update the corresponding setting
        let indexPath = IndexPath(row: 0, section: 0) // Change index based on your settings logic
        let setting = SettingsManager.shared.settings[indexPath.row]
        setting.value = sender.isOn ? "true" : "false"
    }
}

// Extend SettingsViewController to conform to UITextFieldDelegate
extension SettingsViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let cell = textField.superview?.superview as? SettingsTableViewCell,
           let indexPath = tableView.indexPath(for: cell) {
            let setting = SettingsManager.shared.settings[indexPath.row]
            setting.value = textField.text // Update the setting value
        }
    }
}
