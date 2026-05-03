//
//  WorkoutToolBar.swift
//  Workout
//
//  Created by Peter Xie on 26/4/2026.
//

import UIKit

class WorkoutToolBar: UIView {
    private let toolbar = UIToolbar()

    override init(frame: CGRect){
        super.init(frame:frame)
        build()
//        style()
    }
    required init?(coder: NSCoder){
        fatalError("look into workoutsummaryCardView def required init?")
    }
    struct ToolBarItem{
        let imageName:String
        let target:Any?
        let selector:Selector
    }
    
    func configure(toolbarItems:[ToolBarItem]){
        var tmptoolbarItems:[UIBarButtonItem] = []
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems.forEach{
            let button = createCustomButton(imageName: $0.imageName, action: $0.selector,target: $0.self)
            tmptoolbarItems.append(flexibleSpace)
            tmptoolbarItems.append(button)
        }
        tmptoolbarItems.append(flexibleSpace)
        self.toolbar.items = tmptoolbarItems

    }

    
    private func build(){
        addSubview(toolbar)
        toolbar.backgroundColor = .systemGray6
        toolbar.layer.masksToBounds = true
        toolbar.backgroundColor = .systemBackground
        toolbar.isTranslucent = false
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: bottomAnchor,constant: -15),
            toolbar.heightAnchor.constraint(equalToConstant: 55)
        ])
        
    }
    private func createCustomButton(imageName: String, action: Selector,target:Any?) -> UIBarButtonItem {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: imageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 25)), for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)
        return UIBarButtonItem(customView: button)
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

