import UIKit

class AddFoodLogViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    private let ingredientsLabel = UILabel()
    private let assumptionsLabel = UILabel()
    private let confidenceLabel = UILabel()

    private var addFoodLineButton = workoutDesigns.createStyledButton(
        title: "Add FoodLog",
        width: 100,
        height: 50
    )

    private var AddFoodIngredientButton = workoutDesigns.createStyledButton(
        title: "Add Ingredient",
        width: 100,
        height: 50
    )

    private var addSavedFoodButton = workoutDesigns.createStyledButton(
        title: "Add Saved Food",
        width: 100,
        height: 50
    )

    private var queryChatGptButton = workoutDesigns.createStyledButton(
        title: "Estimate Macros",
        width: 100,
        height: 50
    )

    private let proteinGramField = UITextField()
    private let carbGramField = UITextField()
    private let calorieGramField = UITextField()
    private let foodNameField = UITextField()
    private let foodGramsField = UITextField()
    private let fatGramsLabel = UITextField()
    private let pictureName = UITextField()

    private let picturePicker = UIPickerView()
    private let foodIcons = FoodIcon.allCases

    private var foodIngredientsArray = [] as [MacroEstimate]
    private var savedFoods = SavedFoodsView()

    var ImageName = ""

    let date: Date

    init(i_date: Date) {
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
        configurePicturePicker()
        configureSavedFoods()
        updateIngredientsLabel(assumptions: [], confidenceLevel: "")
    }

    private func configurePicturePicker() {
        picturePicker.delegate = self
        picturePicker.dataSource = self

        pictureName.inputView = picturePicker
        pictureName.tintColor = .clear

        pictureName.text = FoodIcon.chicken.rawValue
        ImageName = FoodIcon.chicken.rawValue

        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let flexibleSpace = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )

        let doneButton = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(donePickingPicture)
        )

        toolbar.items = [flexibleSpace, doneButton]
        pictureName.inputAccessoryView = toolbar
    }

    @objc private func donePickingPicture() {
        pictureName.resignFirstResponder()
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(
        _ pickerView: UIPickerView,
        numberOfRowsInComponent component: Int
    ) -> Int {
        return foodIcons.count
    }

    func pickerView(
        _ pickerView: UIPickerView,
        titleForRow row: Int,
        forComponent component: Int
    ) -> String? {
        return foodIcons[row].rawValue
    }

    func pickerView(
        _ pickerView: UIPickerView,
        didSelectRow row: Int,
        inComponent component: Int
    ) {
        let iconName = foodIcons[row].rawValue
        pictureName.text = iconName
        ImageName = iconName
    }

    @objc private func addIngredient() {
        var retCode = true
        var tmpProtein = Constants.num_defaultDouble
        var tmpCarbs = Constants.num_defaultDouble

        guard let tmpFoodName = foodNameField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !tmpFoodName.isEmpty else {
            HelperFunctions.showAlert(
                on: self,
                title: "Invalid Food Name",
                message: "Please enter a valid Food Name"
            )
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

        tmpProtein = Double(proteinGramField.text ?? "") ?? Constants.num_defaultDouble
        tmpCarbs = Double(carbGramField.text ?? "") ?? Constants.num_defaultDouble

        if retCode == true {
            let macro = MacroEstimate(
                foodname: tmpFoodName,
                foodgrams: tmpFoodGramsCheck,
                protein: tmpProtein,
                carbs: tmpCarbs,
                fats: Constants.num_defaultDouble,
                fiber: Constants.num_defaultDouble,
                assumptions: [],
                confidence: "",
                imageName: pictureName.text ?? ""
            )

            foodIngredientsArray.append(macro)
            updateIngredientsLabel(assumptions: [], confidenceLevel: "")
        }
    }

    private func fillFieldsFromSavedFood(_ food: SavedFoodModel) {
        foodNameField.text = food.name
        foodGramsField.text = String(format: "%.1f", food.grams)
        proteinGramField.text = String(format: "%.1f", food.protein)
        carbGramField.text = String(format: "%.1f", food.carbs)
        calorieGramField.text = String(format: "%.0f", food.calories)
        fatGramsLabel.text = String(format: "%.1f", food.fat)
        pictureName.text = food.image
        ImageName = food.image

        if let index = foodIcons.firstIndex(where: { $0.rawValue == food.image }) {
            picturePicker.selectRow(index, inComponent: 0, animated: false)
        }
    }

    private func configureSavedFoods() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

        let context = appDelegate.persistentContainer.viewContext

        SavedFoodsManager.shared.loadSavedFoods(context: context)

        let viewData = SavedFoodsManager.shared.savedFoods.map { food in
            SavedFoodViewData(
                savedFoodRef: food.savedFoodRef,
                image: food.uiImage,
                name: food.name,
                amountText: food.amountText
            )
        }

        savedFoods.configure(savedFoods: viewData)

        savedFoods.onFoodTapped = { [weak self] tappedFood in
            guard let self else { return }

            guard let food = SavedFoodsManager.shared.getSavedFood(
                savedFoodRef: tappedFood.savedFoodRef
            ) else { return }

            self.fillFieldsFromSavedFood(food)
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
                        var protein = Constants.num_defaultDouble
                        var carbs = Constants.num_defaultDouble
                        var calories = Constants.num_defaultDouble
                        var grams = Constants.num_defaultDouble
                        var fat = Constants.num_defaultDouble
                        var assumptions: [String] = []
                        var confidence = ""

                        for macro in macrosReturned {
                            protein += macro.protein
                            carbs += macro.carbs
                            calories += macro.calories
                            fat += macro.fats
                            assumptions += macro.assumptions
                            confidence += macro.confidence

                            if FoodIcon.allowedIconNames.contains(macro.imageName) {
                                self.ImageName = macro.imageName
                                self.pictureName.text = macro.imageName

                                if let index = self.foodIcons.firstIndex(where: { $0.rawValue == macro.imageName }) {
                                    self.picturePicker.selectRow(index, inComponent: 0, animated: false)
                                }
                            }
                        }

                        for ingredient in foodIngredientsArray {
                            grams += ingredient.foodgrams
                        }

                        self.foodNameField.text = Constants.string_default
                        self.foodGramsField.text = String(format: "%.2f", grams)
                        self.proteinGramField.text = String(format: "%.2f", protein)
                        self.carbGramField.text = String(format: "%.2f", carbs)
                        self.calorieGramField.text = String(format: "%.2f", calories)
                        self.fatGramsLabel.text = String(format: "%.2f", fat)

                        self.updateIngredientsLabel(
                            assumptions: assumptions,
                            confidenceLevel: confidence
                        )
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

    @objc private func addFoodLine() {
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

        Task {
            do {
                await FoodLogManager.shared.addFoodLogEntry(
                    i_date: date,
                    i_calories: tmpCalories,
                    i_carbs: tmpCarbs,
                    i_fat: tmpfatGrams,
                    i_food: tmpFoodName,
                    i_grams: tmpFoodGrams,
                    i_protein: tmpProtein
                )
            } catch {
                print("ERROR!")
            }
        }
    }

    @objc private func addSavedFoods() {
        guard
            let tmpFoodName = foodNameField.text?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            !tmpFoodName.isEmpty,

            let tmpPictureName = pictureName.text?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            !tmpPictureName.isEmpty,
            FoodIcon.allowedIconNames.contains(tmpPictureName),

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
                • Picture name is selected
                """
            )
            return
        }

        if SavedFoodsManager.shared.addSavedFood(
            name: tmpFoodName,
            image: tmpPictureName,
            grams: tmpFoodGrams,
            protein: tmpProtein,
            carbs: tmpCarbs,
            fat: tmpfatGrams
        ) != nil {
            configureSavedFoods()
        }
    }

    @objc func dismissKeyboard() {
        UIView.animate(withDuration: 0.1) {
            self.view.endEditing(true)
        }
    }

    private func setupUI() {
        let texfieldsArray: [TextField] = [
            TextField(
                labelName: "Food Name",
                keyboardType: .alphabet,
                uiTextfield: foodNameField,
                useLabelNameAsPlaceHolder: false,
                delegate: self
            ),

            TextField(
                labelName: "Amount Of Food (Grams)",
                keyboardType: .alphabet,
                uiTextfield: foodGramsField,
                useLabelNameAsPlaceHolder: false,
                delegate: self
            ),

            TextField(
                labelName: "Protein (Grams)",
                keyboardType: .alphabet,
                uiTextfield: proteinGramField,
                useLabelNameAsPlaceHolder: false,
                delegate: self
            ),

            TextField(
                labelName: "Carbs (Grams)",
                keyboardType: .alphabet,
                uiTextfield: carbGramField,
                useLabelNameAsPlaceHolder: false,
                delegate: self
            ),

            TextField(
                labelName: "Calories",
                keyboardType: .alphabet,
                uiTextfield: calorieGramField,
                useLabelNameAsPlaceHolder: false,
                delegate: self
            ),

            TextField(
                labelName: "Amount Of Fat (Grams)",
                keyboardType: .alphabet,
                uiTextfield: fatGramsLabel,
                useLabelNameAsPlaceHolder: false,
                delegate: self
            ),

            TextField(
                labelName: "Picture Name:",
                keyboardType: .alphabet,
                uiTextfield: pictureName,
                useLabelNameAsPlaceHolder: false,
                delegate: self
            )
        ]

        let textfields = workoutDesigns.createRoundedSquareViewWithTextFields(
            textFields: texfieldsArray
        )

        ingredientsLabel.font = UIFont.systemFont(ofSize: 20)
        ingredientsLabel.numberOfLines = 0
        ingredientsLabel.lineBreakMode = .byWordWrapping
        ingredientsLabel.translatesAutoresizingMaskIntoConstraints = false

        proteinGramField.keyboardType = .decimalPad
        carbGramField.keyboardType = .decimalPad
        calorieGramField.keyboardType = .numberPad
        foodGramsField.keyboardType = .decimalPad
        foodNameField.keyboardType = .default
        fatGramsLabel.keyboardType = .decimalPad

        pictureName.keyboardType = .default
        pictureName.placeholder = "Select icon"

        let swipeDown = UISwipeGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)

        addFoodLineButton.addTarget(
            self,
            action: #selector(addFoodLine),
            for: .touchUpInside
        )

        AddFoodIngredientButton.addTarget(
            self,
            action: #selector(addIngredient),
            for: .touchUpInside
        )

        queryChatGptButton.addTarget(
            self,
            action: #selector(queryChat),
            for: .touchUpInside
        )

        addSavedFoodButton.addTarget(
            self,
            action: #selector(addSavedFoods),
            for: .touchUpInside
        )

        addFoodLineButton.isUserInteractionEnabled = true
        addFoodLineButton.isEnabled = true
        addFoodLineButton.translatesAutoresizingMaskIntoConstraints = false
        queryChatGptButton.translatesAutoresizingMaskIntoConstraints = false
        AddFoodIngredientButton.translatesAutoresizingMaskIntoConstraints = false
        addSavedFoodButton.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView(arrangedSubviews: [
            savedFoods,
            ingredientsLabel,
            assumptionsLabel,
            confidenceLabel,
            textfields,
            AddFoodIngredientButton,
            addFoodLineButton,
            queryChatGptButton,
            addSavedFoodButton
        ])

        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .fill
        stackView.distribution = .fill

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),

            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }

    private func updateIngredientsLabel(
        assumptions: [String],
        confidenceLevel: String
    ) {
        guard !foodIngredientsArray.isEmpty else {
            ingredientsLabel.text = "No ingredients added"
            return
        }

        var text = "Ingredients Added:\n"

        for ingredient in foodIngredientsArray {
            text += "\(ingredient.foodname) - \(ingredient.foodgrams)g\n"
        }

        ingredientsLabel.text = text

        var assumptionsText = ""

        assumptions.forEach {
            assumptionsText += "\($0),"
        }

        assumptionsLabel.text = "Assumptions:\(assumptionsText)"
        confidenceLabel.text = "Confidence:\(confidenceLevel)"
    }
}
