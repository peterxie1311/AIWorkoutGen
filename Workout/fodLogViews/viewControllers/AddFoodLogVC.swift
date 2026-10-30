import UIKit

class AddFoodLogViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    private let ingredientsLabel = UILabel()
    private let ingredientRows = UIStackView()
    private let totalsLabel = UILabel()
    private var editingIndex: Int?
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

        view.backgroundColor = WorkoutTheme.background

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

            if let index = editingIndex { foodIngredientsArray[index] = macro } else { foodIngredientsArray.append(macro) }
            editingIndex = nil
            AddFoodIngredientButton.setTitle("Add Ingredient", for: .normal)
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
            self.addIngredient()
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

    private func section(_ title: String, content: UIView) -> UIView {
        let heading = UILabel()
        heading.text = title
        heading.textColor = .label
        heading.font = .systemFont(ofSize: 22, weight: .bold)
        let stack = UIStackView(arrangedSubviews: [heading, content])
        stack.axis = .vertical
        stack.spacing = Constants.Design.Spacing.large
        let card = UIView()
        card.backgroundColor = WorkoutTheme.surface
        card.layer.cornerRadius = Constants.Design.Radius.card
        card.layer.cornerCurve = .continuous
        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18)
        ])
        return card
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
            refreshAdaptiveBorders(in: view)
        }
    }

    private func refreshAdaptiveBorders(in parent: UIView) {
        if parent is UITextField {
            parent.layer.borderColor = UIColor.separator.resolvedColor(with: traitCollection).cgColor
        }
        parent.subviews.forEach { refreshAdaptiveBorders(in: $0) }
    }

    private func styledField(_ field: UITextField, placeholder: String, keyboard: UIKeyboardType = .default) -> UIView {
        field.placeholder = placeholder
        field.keyboardType = keyboard
        field.textColor = .label
        field.font = .systemFont(ofSize: 16)
        field.backgroundColor = WorkoutTheme.background
        field.layer.cornerRadius = Constants.Design.Radius.field
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.separator.resolvedColor(with: traitCollection).cgColor
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let wrapper = UIView()
        wrapper.addSubview(field)
        field.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            field.topAnchor.constraint(equalTo: wrapper.topAnchor),
            field.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            field.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            field.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            field.heightAnchor.constraint(equalToConstant: 48)
        ])
        // Keep the text inset without custom UITextField subclasses.
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        field.leftViewMode = .always
        return wrapper
    }

    private func setupUI() {
        title = "Add Food"
        let scroll = UIScrollView()
        scroll.keyboardDismissMode = .interactive
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        let root = UIStackView()
        root.axis = .vertical
        root.spacing = 14
        root.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            root.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            root.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16),
            root.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16),
            root.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32)
        ])

        savedFoods.heightAnchor.constraint(equalToConstant: 174).isActive = true
        root.addArrangedSubview(savedFoods)

        totalsLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        totalsLabel.textColor = .label
        totalsLabel.textAlignment = .center
        totalsLabel.numberOfLines = 0
        root.addArrangedSubview(section("Meal Macros", content: totalsLabel))

        ingredientRows.axis = .vertical
        ingredientRows.spacing = Constants.Design.Spacing.small
        ingredientsLabel.textColor = .secondaryLabel
        ingredientsLabel.font = .systemFont(ofSize: 15)
        let ingredientsStack = UIStackView(arrangedSubviews: [ingredientsLabel, ingredientRows])
        ingredientsStack.axis = .vertical
        ingredientsStack.spacing = 10
        root.addArrangedSubview(section("Ingredients Added", content: ingredientsStack))

        let fields = UIStackView()
        fields.axis = .vertical
        fields.spacing = 10
        fields.addArrangedSubview(styledField(foodNameField, placeholder: "Food name"))
        fields.addArrangedSubview(styledField(foodGramsField, placeholder: "Serving size (g)", keyboard: .decimalPad))
        fields.addArrangedSubview(styledField(pictureName, placeholder: "Food icon"))
        let macroRow1 = UIStackView(arrangedSubviews: [
            styledField(proteinGramField, placeholder: "Protein (g)", keyboard: .decimalPad),
            styledField(carbGramField, placeholder: "Carbs (g)", keyboard: .decimalPad)
        ])
        macroRow1.axis = .horizontal
        macroRow1.spacing = 10
        macroRow1.distribution = .fillEqually
        let macroRow2 = UIStackView(arrangedSubviews: [
            styledField(fatGramsLabel, placeholder: "Fat (g)", keyboard: .decimalPad),
            styledField(calorieGramField, placeholder: "Calories", keyboard: .decimalPad)
        ])
        macroRow2.axis = .horizontal
        macroRow2.spacing = 10
        macroRow2.distribution = .fillEqually
        fields.addArrangedSubview(macroRow1)
        fields.addArrangedSubview(macroRow2)

        AddFoodIngredientButton.addTarget(self, action: #selector(addIngredient), for: .touchUpInside)
        queryChatGptButton.addTarget(self, action: #selector(queryChat), for: .touchUpInside)
        addFoodLineButton.addTarget(self, action: #selector(addFoodLine), for: .touchUpInside)
        addSavedFoodButton.addTarget(self, action: #selector(addSavedFoods), for: .touchUpInside)
        [AddFoodIngredientButton, queryChatGptButton, addFoodLineButton, addSavedFoodButton].forEach {
            $0.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
        let actionRow = UIStackView(arrangedSubviews: [AddFoodIngredientButton, queryChatGptButton])
        actionRow.axis = .horizontal
        actionRow.spacing = 10
        actionRow.distribution = .fillEqually
        fields.addArrangedSubview(actionRow)
        root.addArrangedSubview(section("Add Ingredient", content: fields))
        root.addArrangedSubview(addFoodLineButton)
        root.addArrangedSubview(addSavedFoodButton)
        assumptionsLabel.numberOfLines = 0
        assumptionsLabel.textColor = .secondaryLabel
        confidenceLabel.numberOfLines = 0
        confidenceLabel.textColor = .secondaryLabel
        root.addArrangedSubview(assumptionsLabel)
        root.addArrangedSubview(confidenceLabel)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func editIngredient(_ sender: UIButton) {
        let index = sender.tag
        guard foodIngredientsArray.indices.contains(index) else { return }
        let item = foodIngredientsArray[index]
        editingIndex = index
        foodNameField.text = item.foodname
        foodGramsField.text = String(format: "%.1f", item.foodgrams)
        proteinGramField.text = String(format: "%.1f", item.protein)
        carbGramField.text = String(format: "%.1f", item.carbs)
        fatGramsLabel.text = String(format: "%.1f", item.fats)
        calorieGramField.text = String(format: "%.0f", item.calories)
        pictureName.text = item.imageName
        AddFoodIngredientButton.setTitle("Update Ingredient", for: .normal)
    }

    @objc private func removeIngredient(_ sender: UIButton) {
        guard foodIngredientsArray.indices.contains(sender.tag) else { return }
        foodIngredientsArray.remove(at: sender.tag)
        editingIndex = nil
        AddFoodIngredientButton.setTitle("Add Ingredient", for: .normal)
        updateIngredientsLabel(assumptions: [], confidenceLevel: "")
    }

    private func updateIngredientsLabel(assumptions: [String], confidenceLevel: String) {
        ingredientRows.arrangedSubviews.forEach {
            ingredientRows.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        ingredientsLabel.text = foodIngredientsArray.isEmpty ? "No ingredients added yet" : nil
        ingredientsLabel.isHidden = !foodIngredientsArray.isEmpty
        for (index, item) in foodIngredientsArray.enumerated() {
            let image = UIImageView(image: UIImage(named: item.imageName) ?? UIImage(named: "default_food"))
            image.contentMode = .scaleAspectFit
            image.widthAnchor.constraint(equalToConstant: 36).isActive = true
            image.heightAnchor.constraint(equalToConstant: 42).isActive = true
            let name = UILabel()
            name.text = item.foodname
            name.textColor = .label
            name.font = .systemFont(ofSize: 15, weight: .medium)
            name.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            let amount = UILabel()
            amount.text = String(format: "%.0fg", item.foodgrams)
            amount.textColor = .secondaryLabel
            let edit = UIButton(type: .system)
            edit.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
            edit.tag = index
            edit.addTarget(self, action: #selector(editIngredient(_:)), for: .touchUpInside)
            let remove = UIButton(type: .system)
            remove.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
            remove.tintColor = .secondaryLabel
            remove.tag = index
            remove.addTarget(self, action: #selector(removeIngredient(_:)), for: .touchUpInside)
            let row = UIStackView(arrangedSubviews: [image, name, amount, edit, remove])
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 10
            row.backgroundColor = WorkoutTheme.background
            row.layer.cornerRadius = Constants.Design.Radius.field
            row.isLayoutMarginsRelativeArrangement = true
            row.layoutMargins = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
            ingredientRows.addArrangedSubview(row)
        }
        let protein = foodIngredientsArray.reduce(0) { $0 + $1.protein }
        let carbs = foodIngredientsArray.reduce(0) { $0 + $1.carbs }
        let fat = foodIngredientsArray.reduce(0) { $0 + $1.fats }
        let calories = foodIngredientsArray.reduce(0) { $0 + $1.calories }
        totalsLabel.text = String(format: "Protein %.1fg    Carbs %.1fg\nFat %.1fg    Calories %.0f", protein, carbs, fat, calories)
        assumptionsLabel.text = assumptions.isEmpty ? nil : "Assumptions: " + assumptions.joined(separator: ", ")
        confidenceLabel.text = confidenceLevel.isEmpty ? nil : "Confidence: " + confidenceLevel
    }
}
