//
//  AddFoodLogVC.swift
//  Workout
//
//  Created by Peter Xie on 25/2/2026.
//

import UIKit

class AddFoodLogViewController: UIViewController, UITextFieldDelegate  {
    override var prefersHomeIndicatorAutoHidden: Bool {
           return true
       }



    private let ingredientsLabel        = UILabel()
    private var addFoodLineButton       = workoutDesigns.createStyledButton(title: "Add FoodLog",
                                                                          width: 100,
                                                                          height: 50)
    
    private var AddFoodIngredientButton = workoutDesigns.createStyledButton(title: "Add Ingredient",
                                                                          width: 100,
                                                                          height: 50)
    
    private var queryChatGptButton      = workoutDesigns.createStyledButton(title: "Estimate Macros",
                                                                          width: 100,
                                                                          height: 50)
    private let proteinGramField = UITextField()
    private let carbGramField    = UITextField()
    private let calorieGramField = UITextField()
    private let foodNameField    = UITextField()
    private let foodGramsField   = UITextField()
    private let fatGramsLabel    = UITextField()
    private var foodIngredientsArray = [] as [MacroEstimate]
    
    
    let date:Date
   
    init(i_date:Date) {
        self.date = i_date
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        setupUI()
        updateIngredientsLabel()
    }
    
    @objc private func addIngredient() {
        // Method grab as much data as possible and query chat to fill in the missing field
         var retCode = true
         // have variables to fetch the text fields into and if there is an issue display it to the user
         var tmpProtein   = Constants.num_defaultDouble;
         var tmpCarbs     = Constants.num_defaultDouble;
         var tmpCalories  = Constants.num_defaultDouble;
         
         guard let tmpFoodName = foodNameField.text?
                 .trimmingCharacters(in: .whitespacesAndNewlines),
               !tmpFoodName.isEmpty else {
             HelperFunctions.showAlert(on: self,
                                       title: "Invalid Food Name",
                                       message: "Please enter a valid Food Name")
             retCode = false
             return
         }
         
         guard let tmpFoodGrams = foodGramsField.text,
               let tmpFoodGramsCheck = Double(tmpFoodGrams),
               tmpFoodGramsCheck > 0,
               retCode else {
             
             HelperFunctions.showAlert(
                 on: self,
                 title: "Invalid Food Grams",
                 message: "We got an invalid input for food grams, enter a number please!"
             )
             retCode = false
             return
         }
         
         tmpProtein  = Double(proteinGramField.text ?? "") ?? Constants.num_defaultDouble
         tmpCarbs    = Double(carbGramField.text ?? "") ?? Constants.num_defaultDouble
         tmpCalories = Double(calorieGramField.text ?? "") ?? Constants.num_defaultDouble
        
         if retCode == true {
            let macro = MacroEstimate(
                foodname: tmpFoodName,
                foodgrams: tmpFoodGramsCheck,
                protein: tmpProtein,
                carbs: tmpCarbs,
                fats: Constants.num_defaultDouble,
                calories: tmpCalories,
                fiber: Constants.num_defaultDouble
            )
            foodIngredientsArray.append(macro)
            updateIngredientsLabel()
        }
        
    }
    
    @objc private func queryChat() {
        if foodIngredientsArray.isEmpty {
            addIngredient()
        }
        if !foodIngredientsArray.isEmpty {
            Task {
                    do {
                        let macrosReturned = try await workoutAIservice.shared
                            .estimateMacros(i_ingredients: foodIngredientsArray, i_vc: self)
                        await MainActor.run {
                            var protein  = Constants.num_defaultDouble
                            var carbs    = Constants.num_defaultDouble
                            var calories = Constants.num_defaultDouble
                            var grams    = Constants.num_defaultDouble
                            var fat      = Constants.num_defaultDouble
                            for macro in macrosReturned {
                                protein  += macro.protein
                                carbs    += macro.carbs
                                calories += macro.calories
                                fat      += macro.fats
                            }
                            for ingredient in foodIngredientsArray {
                                grams += ingredient.foodgrams
                            }
                            
                            self.foodNameField.text    = Constants.string_default
                            self.foodGramsField.text   = String(format: "%.2f", grams)
                            self.proteinGramField.text = String(format: "%.2f", protein)
                            self.carbGramField.text    = String(format: "%.2f", carbs)
                            self.calorieGramField.text = String(format: "%.2f", calories)
                            self.fatGramsLabel.text    = String(format: "%.2f", fat)
                        }
                    } catch {
                        await MainActor.run {
                            HelperFunctions.showAlert(
                                on: self,
                                title: "Error",
                                message: error.localizedDescription
                            )
                        }
                    }
                }
        }
        
    }
    
    @objc private func addFoodLine(){
        
        guard
            let tmpFoodName = foodNameField.text?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            !tmpFoodName.isEmpty,

            let gramsText = foodGramsField.text,
            let tmpFoodGrams = Double(gramsText),
            tmpFoodGrams > 0,

            let proteinText = proteinGramField.text,
            let tmpProtein = Double(proteinText),
            tmpProtein >= 0,

            let carbsText = carbGramField.text,
            let tmpCarbs = Double(carbsText),
            tmpCarbs >= 0,

            let caloriesText = calorieGramField.text,
            let tmpCalories = Double(caloriesText),
            tmpCalories >= 0,
                
            let fatGramsText = fatGramsLabel.text,
            let tmpfatGrams = Double(fatGramsText),
            tmpfatGrams >= 0

        else {
            HelperFunctions.showAlert(
                on: self,
                title: "Invalid Input",
                message: """
                Please ensure:
                • Food name is not empty
                • Food grams > 0
                • Protein, Carbs, Calories are valid numbers
                """
            )
            return
        }
        
     
        
        FoodLogManager.shared.addFoodLogEntry(i_date: date, i_calories: tmpCalories, i_carbs: tmpCarbs, i_fat: tmpfatGrams, i_food: tmpFoodName, i_grams: tmpFoodGrams, i_protein: tmpProtein)
    }
    
    @objc func dismissKeyboard() {
        print("Swipe gesture detected")
        UIView.animate(withDuration: 0.1) {
               self.view.endEditing(true)
           }
    }
    
    private func setupUI() {
        
        //setup the text fields
        proteinGramField.borderStyle  = .roundedRect
        proteinGramField.placeholder  = "Protein (Grams)"
        proteinGramField.keyboardType = .alphabet
        proteinGramField.delegate     = self
        proteinGramField.translatesAutoresizingMaskIntoConstraints = false
        proteinGramField.isUserInteractionEnabled                  = true
        
        carbGramField.borderStyle  = .roundedRect
        carbGramField.placeholder  = "Carbs (Grams)"
        carbGramField.keyboardType = .alphabet
        carbGramField.delegate     = self
        carbGramField.translatesAutoresizingMaskIntoConstraints = false
        carbGramField.isUserInteractionEnabled                  = true
        
        calorieGramField.borderStyle  = .roundedRect
        calorieGramField.placeholder  = "Calories"
        calorieGramField.keyboardType = .alphabet
        calorieGramField.delegate     = self
        calorieGramField.translatesAutoresizingMaskIntoConstraints = false
        calorieGramField.isUserInteractionEnabled                  = true
        
        foodNameField.borderStyle  = .roundedRect
        foodNameField.placeholder  = "Food Name"
        foodNameField.keyboardType = .alphabet
        foodNameField.delegate     = self
        foodNameField.translatesAutoresizingMaskIntoConstraints = false
        foodNameField.isUserInteractionEnabled                  = true
        
        foodGramsField.borderStyle  = .roundedRect
        foodGramsField.placeholder  = "Amount Of Food (Grams)"
        foodGramsField.keyboardType = .alphabet
        foodGramsField.delegate     = self
        foodGramsField.translatesAutoresizingMaskIntoConstraints = false
        foodGramsField.isUserInteractionEnabled                  = true
        
        
        fatGramsLabel.borderStyle  = .roundedRect
        fatGramsLabel.placeholder  = "Amount Of Fat (Grams)"
        fatGramsLabel.keyboardType = .alphabet
        fatGramsLabel.delegate     = self
        fatGramsLabel.translatesAutoresizingMaskIntoConstraints = false
        fatGramsLabel.isUserInteractionEnabled                  = true
        
        //--------------------------
        

        ingredientsLabel.font  = UIFont.systemFont(ofSize: 20)
        ingredientsLabel.numberOfLines = 0
        ingredientsLabel.lineBreakMode = .byWordWrapping
        ingredientsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        proteinGramField.keyboardType = .decimalPad
        carbGramField.keyboardType = .decimalPad
        calorieGramField.keyboardType = .numberPad
        foodGramsField.keyboardType = .decimalPad
        foodNameField.keyboardType = .default
        fatGramsLabel.keyboardType = .decimalPad
        

        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            swipeDown.direction = .down
            view.addGestureRecognizer(swipeDown)
        
        addFoodLineButton .addTarget(self, action: #selector(addFoodLine), for: .touchUpInside)
        AddFoodIngredientButton . addTarget(self, action: #selector(addIngredient), for: .touchUpInside)
        queryChatGptButton.addTarget(self, action: #selector(queryChat), for: .touchUpInside)
        addFoodLineButton .isUserInteractionEnabled = true
        addFoodLineButton .isEnabled = true
        addFoodLineButton .translatesAutoresizingMaskIntoConstraints = false
        queryChatGptButton.translatesAutoresizingMaskIntoConstraints = false
        AddFoodIngredientButton .translatesAutoresizingMaskIntoConstraints = false
        
        
        
        let stackView = UIStackView(arrangedSubviews: [
            ingredientsLabel  ,
            foodNameField     ,
            foodGramsField    ,
            proteinGramField  ,
            carbGramField     ,
            calorieGramField  ,
            fatGramsLabel     ,
            AddFoodIngredientButton,
            addFoodLineButton ,
            queryChatGptButton,
            
        ])
        stackView.axis    = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .fill
        stackView.distribution = .fill
        
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive   // nice UX
        view.addSubview(scrollView)
        
        let contentView = UIView()
            contentView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(contentView)
            contentView.addSubview(stackView)
        
//        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
               // Scroll view fills the screen (safe area)
               scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
               scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
               scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
               scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

               // Content view pinned to scroll view content layout
               contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
               contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
               contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
               contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),

               // Content view matches scroll view width so it scrolls vertically only
               contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

               // Stack view pinned inside content view with padding
               stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
               stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
               stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
               stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
           ])
    }
    
    private func updateIngredientsLabel() {
        guard !foodIngredientsArray.isEmpty else {
            ingredientsLabel.text = "No ingredients added"
            return
        }

        var text = "Ingredients Added:\n"

        for ingredient in foodIngredientsArray {
            text += "\(ingredient.foodname) - \(ingredient.foodgrams)g\n"
        }

        ingredientsLabel.text = text
    }
    
}
