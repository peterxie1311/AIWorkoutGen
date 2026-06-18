import UIKit

class AddSetViewController: KeyboardAwareViewController, UITextFieldDelegate {

    private let mainScrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private let addSetLabel = UILabel()

    private var addSetButton = workoutDesigns.createStyledButton(
        title: "Add Set!",
        width: 100,
        height: 50
    )

    private var generateWorkoutButton: UIButton = workoutDesigns.createStyledButton(
        title: "Generate Workout!",
        width: 100,
        height: 50
    )

    private let workoutSessionSelector = UITextField()
    private let workoutSessionRestTime = UITextField()

    private let workoutnameField = UITextField()
    private let setqtyField = UITextField()
    private let repqtyField = UITextField()
    private let weightField = UITextField()

    private let aiCustField = UITextField()
    private let aiCntField = UITextField()
    private let aiCntwrkField = UITextField()

    private let openWorkouts = WorkoutPlanTabsView()
    private let openWorkoutsArr = WorkoutSessionManager.shared.getOpenWorkouts()

    private lazy var handlerTab: (WorkoutSession) -> Void = { [weak self] workout in
        self?.setTextField(w: workout)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        setupUI()
        setupData()
    }

    @objc private func addSet() {
        let tmpWorkoutSessionName = workoutSessionSelector.text ?? ""
        let tmpWorkoutName = workoutnameField.text ?? ""
        let tmpRestTime = Float(workoutSessionRestTime.text ?? "") ?? 0

        let tmpSetQty = Int(setqtyField.text ?? "") ?? 0
        let tmpRepQty = Int(repqtyField.text ?? "") ?? 0
        let tmpWeight = Int64(weightField.text ?? "") ?? 0

        var setRepArr: [Setrep] = []

        for _ in 0..<tmpSetQty {
            let tmpSet = SetrepManager.shared.initSetRep(
                qty: tmpRepQty,
                startTime: Date(),
                finishTime: Date(),
                workoutName: tmpWorkoutName,
                weight: tmpWeight
            )

            setRepArr.append(tmpSet)
        }

        if let existingWorkout = openWorkoutsArr.first(where: {
            $0.workouttab == tmpWorkoutSessionName
        }) {
            let newWorkout = existingWorkout

            setRepArr.forEach {
                newWorkout.addToSetrep($0)
            }
            
            Task {
                
               await WorkoutSessionManager.shared.updateWorkoutSession(
                    prevWorkout: existingWorkout,
                    updatedSession: newWorkout
                )
            }
        } else {
            
            Task{
                
           await     WorkoutSessionManager.shared.addWorkoutSession(
                    durationHrs: 0,
                    endTime: Date(),
                    location: "",
                    startTime: Date(),
                    sets: setRepArr,
                    workoutTab: tmpWorkoutSessionName,
                    rest_duration: tmpRestTime,
                    moddate: Date()
                )
            }
            
        }
    }

    private func setTextField(w: WorkoutSession) {
        workoutSessionSelector.text = w.workouttab
    }

    @objc private func queryChat() {
        let cntSessions = Int(aiCntwrkField.text ?? "") ?? 0
        let cntWorkouts = Int(aiCntField.text ?? "") ?? 0
        let cust = aiCustField.text ?? ""

        WorkoutSessionManager.shared.createWorkoutPlan(
            i_workouts: cntWorkouts,
            i_sessions: cntSessions,
            i_customisations: cust
        )
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
    }

    private func setupUI() {
        register(scrollView: mainScrollView)

        addSetLabel.font = UIFont.systemFont(ofSize: 20)
        addSetLabel.textAlignment = .center

        addSetButton.addTarget(self, action: #selector(addSet), for: .touchUpInside)
        generateWorkoutButton.addTarget(self, action: #selector(queryChat), for: .touchUpInside)

        let workoutTextFields: [TextField] = [
            TextField(
                labelName: "Workout Name",
                keyboardType: .default,
                uiTextfield: workoutnameField,
                useLabelNameAsPlaceHolder: false,
                delegate: self
            ),
            TextField(
                labelName: "Set QTY",
                keyboardType: .numberPad,
                uiTextfield: setqtyField,
                useLabelNameAsPlaceHolder: false,
                delegate: self
            ),
            TextField(
                labelName: "Rep QTY",
                keyboardType: .numberPad,
                uiTextfield: repqtyField,
                useLabelNameAsPlaceHolder: false,
                delegate: self
            ),
            TextField(
                labelName: "Weight (kg)",
                keyboardType: .numberPad,
                uiTextfield: weightField,
                useLabelNameAsPlaceHolder: false,
                delegate: self
            )
        ]

        let aiTextField: [TextField] = [
            TextField(
                labelName: "# Workout goals and customisations",
                keyboardType: .default,
                uiTextfield: aiCustField,
                useLabelNameAsPlaceHolder: false,
                delegate: self
            ),
            TextField(
                labelName: "# Workout data for input",
                keyboardType: .numberPad,
                uiTextfield: aiCntField,
                useLabelNameAsPlaceHolder: false,
                delegate: self
            ),
            TextField(
                labelName: "# Workout Sessions",
                keyboardType: .numberPad,
                uiTextfield: aiCntwrkField,
                useLabelNameAsPlaceHolder: false,
                delegate: self
            )
        ]

        let workoutSessionText = workoutDesigns.createRoundedSquareViewWithTextFields(
            textFields: [
                TextField(
                    labelName: "Workout Session Name",
                    keyboardType: .default,
                    uiTextfield: workoutSessionSelector,
                    useLabelNameAsPlaceHolder: false,
                    delegate: self
                ),
                TextField(
                    labelName: "Workout Session Rest Duration",
                    keyboardType: .numberPad,
                    uiTextfield: workoutSessionRestTime,
                    useLabelNameAsPlaceHolder: false,
                    delegate: self
                )
            ]
        )

        let textFieldsView = workoutDesigns.createRoundedSquareViewWithTextFields(
            textFields: workoutTextFields
        )

        let textFieldsAIView = workoutDesigns.createRoundedSquareViewWithTextFields(
            textFields: aiTextField
        )

        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .fill
        stackView.distribution = .fill

        stackView.addArrangedSubview(addSetLabel)
        stackView.addArrangedSubview(workoutSessionText)
        stackView.addArrangedSubview(openWorkouts)
        stackView.addArrangedSubview(textFieldsView)
        stackView.addArrangedSubview(addSetButton)
        stackView.addArrangedSubview(textFieldsAIView)
        stackView.addArrangedSubview(generateWorkoutButton)

        view.addSubview(mainScrollView)
        mainScrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        mainScrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        openWorkouts.heightAnchor.constraint(equalToConstant: 350).isActive = true

        NSLayoutConstraint.activate([
            mainScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: mainScrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: mainScrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: mainScrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: mainScrollView.contentLayoutGuide.bottomAnchor),

            contentView.widthAnchor.constraint(equalTo: mainScrollView.frameLayoutGuide.widthAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])

        openWorkouts.configure(
            i_workoutSessions: openWorkoutsArr,
            i_onTabSelectedFunc: handlerTab
        )
    }

    private func setupData() {
        addSetLabel.text = "Add a Workout Set!"
    }
}
