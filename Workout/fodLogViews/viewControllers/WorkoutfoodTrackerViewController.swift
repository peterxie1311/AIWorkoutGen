import UIKit
import SwiftUI

class WorkoutfoodTrackerViewController: UIViewController {
    
    //MARK: Const Declaration
    
    //Properties -----------------
    let logDate:Date
    let totalCals:Double
    let totalProtein:Double
    let totalCarbs:Double
   // let foodLines:[FoodLogLine]
    let foodHeadId:UUID
    let carbGoal:Double
    let proteinGoal:Double
    let calorieGoal:Double
    
    // View Objects
    let titleLabel     = UILabel()
    let breakFastLabel = UILabel()
    let lunchLabel     = UILabel()
    let dinnerLabel    = UILabel()
    
    //Setup Views
    private let stackScrollView = UIScrollView()
    private let stackView = UIStackView()
    private let card = MacroSummaryCardView()
    private let breakfastCard = FoodlogCardView()
    private let lunchCard = FoodlogCardView()
    private let dinnerCard = FoodlogCardView()
    
    private let addFoodLogButton = workoutDesigns.createStyledButton(title: "Add Food", width: 50, height: 50)
    private let refresh = workoutDesigns.createStyledButton(title: "Refresh", width: 50, height: 50)
    
    init(i_date:Date){
        self.logDate      = i_date
        let foodhead      = FoodLogManager.shared.fetchFoodHeadbyDate(i_date: i_date)
        self.totalCals    = foodhead?.calories      ?? 0.0
        self.totalProtein = foodhead?.protein       ?? 0.0
        self.totalCarbs   = foodhead?.carbs         ?? 0.0
        self.foodHeadId   = foodhead?.foodHeadID    ?? UUID()
       // self.foodLines    = FoodLogManager.shared.fetchFoodLinesbyID(i_id: self.foodHeadId)
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
    
    @objc private func sync(){
        Task {
            await FoodLogManager.shared.syncFoodLogEntries()
        }
    }
    
    @objc private func reloadData(){
        view.layoutIfNeeded()
        
        let foodhead      = FoodLogManager.shared.fetchFoodHeadbyDate(i_date: self.logDate)
        
        card.configure(
                  calories: foodhead?.calories ?? 0,
                  caloriesGoal: calorieGoal,
                  proteinCurrent: foodhead?.protein ?? 0,
                  proteinGoal: proteinGoal,
                  carbsCurrent: foodhead?.carbs ?? 0,
                  carbsGoal: carbGoal,
                  
              )
        let breakfastFoodLines = FoodLogManager.shared.fetchFoodLinesbyIDLessThanHour(i_id: self.foodHeadId, i_hourLessThan: 11, i_hourGreaterThan: 4)
       // let breakfastFoodLines = FoodLogManager.shared.fetchFoodLinesbyID(i_id: foodHeadId)
        breakfastCard.configure(foodLogLines: breakfastFoodLines, totalCalories: calorieGoal,totalProtein: proteinGoal)
        
        let lunchFoodLines = FoodLogManager.shared.fetchFoodLinesbyIDLessThanHour(i_id: self.foodHeadId, i_hourLessThan: 15, i_hourGreaterThan: 12)
        lunchCard.configure(foodLogLines: lunchFoodLines, totalCalories: self.calorieGoal, totalProtein: self.proteinGoal)
        
        let dinnerFoodLines = FoodLogManager.shared.fetchFoodLinesbyIDLessThanHour(i_id: self.foodHeadId, i_hourLessThan: 23, i_hourGreaterThan: 16)
        dinnerCard.configure(foodLogLines: dinnerFoodLines, totalCalories: self.calorieGoal, totalProtein: self.proteinGoal)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //first init all the UIViews
        view.backgroundColor = .systemBackground
        view.addSubview(stackScrollView)
        stackScrollView.translatesAutoresizingMaskIntoConstraints = false
        stackScrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackScrollView.translatesAutoresizingMaskIntoConstraints = false
        stackScrollView.isUserInteractionEnabled = true
        stackView.isUserInteractionEnabled = true
        
        //Setup labels
        titleLabel.text = "Food Log: " + HelperFunctions.parseDateToString(self.logDate)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        
        //
        let breakfastLabelConfig = workoutDesigns.attributedText(text:"Breakfast")
        
        let breakfastlabelConfigSecond = workoutDesigns.attributedText(text: " (12am-12pm)",
                                                                       fontsize:16,
                                                                       colour:UIColor.secondaryLabel)
        breakFastLabel.attributedText = workoutDesigns.makeAttributedString(textArray: [breakfastLabelConfig,breakfastlabelConfigSecond])
        
        let lunchLabelConfig = workoutDesigns.attributedText(text:"Lunch")
        let lunchLabelConfigSecond = workoutDesigns.attributedText(text: " (12pm-4pm)",
                                                                   fontsize: 16,
                                                                   colour: UIColor.secondaryLabel)
        lunchLabel.attributedText = workoutDesigns.makeAttributedString(textArray: [lunchLabelConfig,lunchLabelConfigSecond])
        
        let dinnerLabelConfig = workoutDesigns.attributedText(text:"Dinner")
        let dinnerLabelConfigSecond = workoutDesigns.attributedText(text:" (4pm - 12am)",
                                                                    fontsize: 16,
                                                                    colour:.secondaryLabel)
        
        dinnerLabel.attributedText = workoutDesigns.makeAttributedString(textArray: [dinnerLabelConfig,dinnerLabelConfigSecond])
        
        
        
        // Setup Buttons
        
        addFoodLogButton.addTarget(self, action: #selector(addFoodLine), for: .touchUpInside)
        refresh.addTarget(self, action: #selector(sync), for: .touchUpInside)
    
        let views: [UIView] = [titleLabel,card,breakFastLabel,breakfastCard,lunchLabel,lunchCard,dinnerLabel,dinnerCard,addFoodLogButton,refresh]
        
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
        
        reloadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name(Constants.reloadFoodLogTrigger), object: nil)

        
        

    }
}
