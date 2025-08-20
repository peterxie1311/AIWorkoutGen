import UIKit

class SettingsTableViewCell: UITableViewCell {
    
    let textField = UITextField()
    let switchControl = UISwitch()
    
    var isSwitch: Bool = false {
        didSet {
            textField.isHidden = isSwitch
            switchControl.isHidden = !isSwitch
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // Configure TextField
        textField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textField)
        
        // Configure Switch
//        switchControl.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(switchControl)
        
        // Constraints
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            textField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

//            switchControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            switchControl.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
