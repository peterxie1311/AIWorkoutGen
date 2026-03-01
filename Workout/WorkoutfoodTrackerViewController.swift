import UIKit
import SwiftUI

class WorkoutfoodTrackerViewController: UIViewController {
    
    //MARK: Const Declaration
    
    //Properties -----------------
    let logDate:Date
    let totalCals:Double
    let totalProtein:Double
    let totalCarbs:Double
    let foodLines:[FoodLogLine]
    let foodHeadId:UUID
    let carbGoal:Double
    let proteinGoal:Double
    let calorieGoal:Double
    
    // View Objects
    let titleLabel = UILabel()
    
    //Setup Views
    private let stackScrollView = UIScrollView()
    private let stackView = UIStackView()
    private let card = MacroSummaryCardView()
    private let addFoodLogButton = workoutDesigns.createStyledButton(title: "Add Food", width: 50, height: 50)
    
    
    init(i_date:Date){
        self.logDate      = i_date
        let foodhead      = FoodLogManager.shared.fetchFoodHeadbyDate(i_date: i_date)
        self.totalCals    = foodhead?.calories      ?? 0.0
        self.totalProtein = foodhead?.protein       ?? 0.0
        self.totalCarbs   = foodhead?.carbs         ?? 0.0
        self.foodHeadId   = foodhead?.foodHeadID    ?? UUID()
        self.foodLines    = FoodLogManager.shared.fetchFoodLinesbyID(i_id: self.foodHeadId)
        self.carbGoal     = SettingsManager.shared.getSettingDouble(name: SettingsManager.carbGoal)
        self.proteinGoal  = SettingsManager.shared.getSettingDouble(name: SettingsManager.proteinGoal)
        self.calorieGoal  = SettingsManager.shared.getSettingDouble(name: SettingsManager.calorieGoal)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func addFoodLine(){
        goToAddFoodLine(i_date: logDate)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //first init all the UIViews
        view.backgroundColor = .systemBackground
        view.addSubview(stackScrollView)
        stackScrollView.translatesAutoresizingMaskIntoConstraints = false
        stackScrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackScrollView.isUserInteractionEnabled = true
        stackView.isUserInteractionEnabled = true
        
        //Setup labels
        titleLabel.text = "Food Log: " + HelperFunctions.parseDateToString(self.logDate)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        
        // Setup Buttons
        
        addFoodLogButton.addTarget(self, action: #selector(addFoodLine), for: .touchUpInside)
        
        card.configure(
                  calories: totalCals,
                  proteinCurrent: totalProtein, proteinGoal: proteinGoal,
                  carbsCurrent: totalCarbs, carbsGoal: carbGoal,
                  bar1Progress: totalProtein/proteinGoal,
                  bar2Progress: totalCarbs/totalCals
              )
        
        let views: [UIView] = [titleLabel,card,addFoodLogButton]
        
        for view in views {
            stackView.addArrangedSubview(view)
        }
        stackView.axis          = .vertical
        stackView.spacing       = 10.0
        
        
        
        NSLayoutConstraint.activate([
            stackScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
               stackView.topAnchor.constraint(equalTo: stackScrollView.contentLayoutGuide.topAnchor),
               stackView.leadingAnchor.constraint(equalTo: stackScrollView.contentLayoutGuide.leadingAnchor, constant: 20),
               stackView.trailingAnchor.constraint(equalTo: stackScrollView.contentLayoutGuide.trailingAnchor, constant: -20),
               stackView.bottomAnchor.constraint(equalTo: stackScrollView.contentLayoutGuide.bottomAnchor),

               stackView.widthAnchor.constraint(equalTo: stackScrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
        
        

    }
}
