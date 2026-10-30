import UIKit
import AVKit

class RepViewController: KeyboardAwareViewController ,UITextFieldDelegate{
    override var prefersHomeIndicatorAutoHidden: Bool {
           return true
       }
    
    //MARK: Const Declaration
    
    // Properties ------------------------------------------
    var completed: Bool
    var duration_sec: Float
    var finishTime: Date
    var rep_qty: Int64
    var repid:UUID
    var startTime:Date
    var weight: Int64
    var WorkoutName:String
    var WeightBasis:String
    let startTimeButton:String  = "Start Timer"
    let finishTimeButton:String = "Finish Timer"
    let videoButtonLabel:String = "View Video"
    let statusPrefix:String     = "Status: "
    let timerprefix:String      = "Sec: "
    let weightprefix:String     = "Weight(kgs): "

  //  let changeRepWeightButtonlabel:String = "Change Rep Weight"
    var repButtonString:String
    let workoutURL:String
    var setRep:Setrep
    
    
    let phase_1 = "Start Reps"
    let phase_2 = "Finish Reps"
    let phase_3 = "Finished!"
    
    // Timer properties ---
    var timer: Timer?
    var elapsedTime: TimeInterval = 0
    
    // UI Components
    private let nameLabel         = UILabel()
    private let rep_qtyLabel      = UILabel()
    private let status            = UILabel()
    private let startTimeLabel    = UILabel()
    private let duration_secLabel = UILabel()
    private let weight_label      = UILabel()
    private let weight_basisLabel = UILabel()
    
    private let personalBestLabelWeight = UILabel()
    private let personalBestLabelReps   = UILabel()
   // private let videoButton = UIButton()
    private var RepButton             = workoutDesigns.createStyledButton(title: "",
                                                                          systemImageName: "dumbbell",
                                                                          width: 25,
                                                                          height: 50)
    private var deleteRepButton       = workoutDesigns.createStyledButton(title: "Delete",
                                                                          systemImageName: "trash",
                                                                          width: 25,
                                                                          height:50)
    private var changeRepWeightButton = workoutDesigns.createStyledButton(title: "Change",
                                                                          systemImageName: "pencil",
                                                                          width: 25,
                                                                          height: 50)
    // text input to change weight
    let changeRepWeight           = UITextField()
    let changeSetQTY              = UITextField()
    let changeWorkoutName         = UITextField()
    let scrollViewBase            = UIScrollView()
    
   
    
    // Initializer
    init(rep:Setrep) {
        self.completed = rep.completed
        self.duration_sec = rep.duration_sec
        self.finishTime = rep.finishTime ?? Date()
        self.rep_qty = rep.rep_qty
        self.repid = rep.repid ?? UUID()
        self.startTime = rep.startTime ?? Date()
        self.WorkoutName = rep.workoutName ?? "Unknown Workout"
        self.weight = rep.weight
        self.workoutURL = ""
      //  self.workoutURL = WorkoutManager.shared.getWorkout(workoutName: WorkoutName)?.video ?? ""
        self.setRep = rep
        self.WeightBasis = rep.weight_basis ?? ""
        self.repButtonString = self.phase_1
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        register(scrollView: scrollViewBase)
        setupUI()
//        addDoneButtonToKeyboard()
//        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: NSNotification.Name("workout"), object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: NSNotification.Name("SetRep"), object: nil)
    }
    
    @objc private func reload(){
        let updatedRep = SetrepManager.shared.getSetrep(uuid: self.repid) ?? self.setRep
        self.completed = updatedRep.completed
        self.duration_sec = updatedRep.duration_sec
        self.finishTime = updatedRep.finishTime ?? Date()
        self.rep_qty = updatedRep.rep_qty
        self.repid = updatedRep.repid ?? UUID()
        self.startTime = updatedRep.startTime ?? Date()
        self.WorkoutName = updatedRep.workoutName ?? "Unknown Workout"
        self.weight = updatedRep.weight
        self.setRep = updatedRep
        
        setupUI()
    }
    
    private func parseDateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func getPersonalBest (workout: String) -> Setrep? {
         var personalBest:Setrep? = nil
            for session in WorkoutSessionManager.shared.workoutSessions{
                for setrep in (session.setrep?.allObjects as? [Setrep]) ?? []{
                    if setrep.workoutName == workout && setrep.weight > personalBest?.weight ?? 0 {
                        personalBest = setrep
                    }
                }
        }
       return personalBest
    }
    
    private func detailLabel(_ text: String, prominent: Bool = false) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: prominent ? 24 : 15, weight: prominent ? .bold : .medium)
        label.textColor = prominent ? .label : .secondaryLabel
        label.numberOfLines = 0
        return label
    }

    private func panel(_ children: [UIView]) -> UIView {
        let stack = UIStackView(arrangedSubviews: children)
        stack.axis = .vertical
        stack.spacing = Constants.Design.Spacing.medium
        let container = UIView()
        WorkoutTheme.card(container)
        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -18),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -18)
        ])
        return container
    }

    private func setupUI() {
        view.backgroundColor = WorkoutTheme.background
        scrollViewBase.subviews.forEach { $0.removeFromSuperview() }
        if scrollViewBase.superview == nil { view.addSubview(scrollViewBase) }
        scrollViewBase.translatesAutoresizingMaskIntoConstraints = false
        scrollViewBase.keyboardDismissMode = .interactive
        NSLayoutConstraint.activate([
            scrollViewBase.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollViewBase.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollViewBase.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollViewBase.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        nameLabel.text = WorkoutName
        nameLabel.font = .systemFont(ofSize: 32, weight: .bold)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 0
        let subtitle = detailLabel(WeightBasis.isEmpty ? "Exercise details" : WeightBasis.capitalized)
        let icon = ExerciseIcon.resolved(setRep.iconName, exerciseName: WorkoutName)
        let illustration = UIImageView(image: UIImage(named: icon.rawValue))
        illustration.contentMode = .scaleAspectFit
        illustration.clipsToBounds = true
        illustration.layer.cornerRadius = Constants.Design.Radius.compactCard
        illustration.backgroundColor = WorkoutTheme.surface
        illustration.widthAnchor.constraint(equalToConstant: 104).isActive = true
        illustration.heightAnchor.constraint(equalToConstant: 136).isActive = true
        illustration.accessibilityLabel = "\(WorkoutName) muscle illustration"
        let headingLabels = UIStackView(arrangedSubviews: [nameLabel, subtitle])
        headingLabels.axis = .vertical
        headingLabels.spacing = 6
        let heading = UIStackView(arrangedSubviews: [illustration, headingLabels])
        heading.axis = .horizontal
        heading.alignment = .center
        heading.spacing = 16

        weight_label.text = "\(weight) kg"
        rep_qtyLabel.text = "\(rep_qty) reps"
        status.text = completed ? "Completed" : (repButtonString == phase_2 ? "In progress" : "Not started")
        let metrics = UIStackView(arrangedSubviews: [
            metric(title: "WEIGHT", value: weight_label),
            metric(title: "REPS", value: rep_qtyLabel),
            metric(title: "STATUS", value: status)
        ])
        metrics.axis = .horizontal
        metrics.spacing = 8
        metrics.distribution = .fillEqually

        let best = getPersonalBest(workout: WorkoutName)
        personalBestLabelWeight.text = best.map { "\($0.weight) kg" } ?? "—"
        personalBestLabelReps.text = best.map { "\($0.rep_qty) reps" } ?? "—"
        let records = UIStackView(arrangedSubviews: [
            metric(title: "BEST WEIGHT", value: personalBestLabelWeight),
            metric(title: "BEST REPS", value: personalBestLabelReps)
        ])
        records.axis = .horizontal
        records.distribution = .fillEqually
        records.spacing = 12

        startTimeLabel.text = "Added  •  " + parseDateToString(startTime)
        duration_secLabel.text = "Duration  •  " + String(format: "%.0f sec", duration_sec)
        weight_basisLabel.text = "Equipment  •  " + (WeightBasis.isEmpty ? "Not specified" : WeightBasis)
        let info = panel([weight_basisLabel, startTimeLabel, duration_secLabel])
        [weight_basisLabel, startTimeLabel, duration_secLabel].forEach {
            $0.textColor = .secondaryLabel
            $0.font = .systemFont(ofSize: 14)
        }

        RepButton.setTitle(completed ? phase_3 : repButtonString, for: .normal)
        RepButton.isEnabled = !completed
        RepButton.addTarget(self, action: #selector(startworkout), for: .touchUpInside)
        deleteRepButton.addTarget(self, action: #selector(confirmDeleteRep), for: .touchUpInside)
        deleteRepButton.configuration?.baseBackgroundColor = .systemRed.withAlphaComponent(0.12)
        deleteRepButton.configuration?.baseForegroundColor = .systemRed
        changeRepWeightButton.setTitle("Save Changes", for: .normal)
        changeRepWeightButton.addTarget(self, action: #selector(executechangerepweight), for: .touchUpInside)

        let editTitle = detailLabel("Edit Details", prominent: true)
        changeWorkoutName.text = WorkoutName
        changeRepWeight.text = String(weight)
        changeSetQTY.text = String(rep_qty)
        let editFields: [(UITextField, String, UIKeyboardType)] = [
            (changeWorkoutName, "Exercise name", .default),
            (changeRepWeight, "Weight (kg)", .numberPad),
            (changeSetQTY, "Reps", .numberPad)
        ]
        let editStack = UIStackView()
        editStack.axis = .vertical
        editStack.spacing = 12
        for (field, placeholder, keyboard) in editFields {
            field.placeholder = placeholder
            field.keyboardType = keyboard
            field.delegate = self
            field.borderStyle = .none
            field.backgroundColor = WorkoutTheme.background
            field.textColor = .label
            field.layer.cornerRadius = Constants.Design.Radius.field
            field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
            field.leftViewMode = .always
            field.heightAnchor.constraint(equalToConstant: Constants.Design.Size.inputHeight).isActive = true
            editStack.addArrangedSubview(detailLabel(placeholder))
            editStack.addArrangedSubview(field)
        }
        editStack.addArrangedSubview(changeRepWeightButton)
        let root = UIStackView(arrangedSubviews: [
            heading, panel([metrics]), panel([detailLabel("Personal Best", prominent: true), records]),
            info, RepButton, panel([editTitle, editStack]), deleteRepButton
        ])
        root.axis = .vertical
        root.spacing = Constants.Design.Spacing.large
        root.translatesAutoresizingMaskIntoConstraints = false
        scrollViewBase.addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: scrollViewBase.contentLayoutGuide.topAnchor, constant: 24),
            root.bottomAnchor.constraint(equalTo: scrollViewBase.contentLayoutGuide.bottomAnchor, constant: -32),
            root.leadingAnchor.constraint(equalTo: scrollViewBase.contentLayoutGuide.leadingAnchor, constant: 20),
            root.trailingAnchor.constraint(equalTo: scrollViewBase.contentLayoutGuide.trailingAnchor, constant: -20),
            root.widthAnchor.constraint(equalTo: scrollViewBase.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }

    private func metric(title: String, value: UILabel) -> UIView {
        value.font = .systemFont(ofSize: 20, weight: .bold)
        value.textColor = .label
        value.textAlignment = .center
        value.numberOfLines = 2
        let caption = detailLabel(title)
        caption.font = .systemFont(ofSize: 11, weight: .semibold)
        caption.textAlignment = .center
        let stack = UIStackView(arrangedSubviews: [caption, value])
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }

    @objc private func confirmDeleteRep() {
        let alert = UIAlertController(title: "Delete Set?", message: "This action cannot be undone.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in self?.deleteRep() })
        present(alert, animated: true)
    }

    @objc private func executechangerepweight() {
        var newweight = weight
        var newsetqty = rep_qty
        var newWorkoutName = WorkoutName

        if let newWeightText = changeRepWeight.text, !newWeightText.isEmpty {
            guard let validWeight = Int64(newWeightText), validWeight > 0 else {
                HelperFunctions.showAlert(on: self, title: "Invalid Input", message: "Please enter a valid weight.")
                return
            }
            newweight = validWeight
        }
        if let newSetQTYText = changeSetQTY.text,!newSetQTYText.isEmpty {
           guard let newSetQTY = Int64(newSetQTYText),
                newSetQTY > 0 else {
               HelperFunctions.showAlert(on: self, title: "Invalid Input", message: "Please enter a valid Set QTY.")
                    return
                }
            newsetqty = newSetQTY
        }
        if let newSetWorkoutNameText = changeWorkoutName.text,!newSetWorkoutNameText.isEmpty {
                 newWorkoutName = newSetWorkoutNameText
        }

        // Update the setRep with new values
        let updatedSetrep         = self.setRep
        updatedSetrep.weight      = newweight
        updatedSetrep.rep_qty     = newsetqty // Assign validated Set QTY
        updatedSetrep.workoutName = newWorkoutName

        SetrepManager.shared.updateSetrep(repid: repid, updatedSetrep: updatedSetrep)
        reload()

        // Optionally update the UI or show feedback
        changeRepWeight.text = ""
        changeSetQTY.text    = ""
    }

    @objc private func deleteRep() {
        SetrepManager.shared.removeSetrep(repid: self.repid)
        SetrepManager.shared.loadSetreps()
        navigationController?.popViewController(animated: true)
    }
    @objc private func startworkout(){
        if repButtonString == phase_1 {
            startTime = Date()
            duration_secLabel.text = timerprefix + "0"
            timer?.invalidate()
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
            
            
            // need to update the starttime of the rep
            
            
            self.repButtonString = phase_2
            RepButton.setTitle(repButtonString, for: .normal)
            
        }
        else if repButtonString == phase_2{
            finishTime = Date()
            completed = true
            
            let differenceInSeconds = finishTime.timeIntervalSince(startTime)
            let absoluteDifferenceInSeconds = abs(differenceInSeconds)
            setRep.completed = completed
            setRep.duration_sec = Float(absoluteDifferenceInSeconds)
            setRep.finishTime = finishTime
            setRep.rep_qty = rep_qty
            setRep.repid = repid
            setRep.startTime = startTime
            setRep.weight = weight
            setRep.workoutName = WorkoutName
            SetrepManager.shared.updateSetrep(repid: repid, updatedSetrep: setRep)
            timer?.invalidate()
            timer = nil
            repButtonString = phase_3
            RepButton.setTitle(repButtonString, for: .normal)
            setupUI()
        }

    }
    
    @objc func updateTimer() {
        let timeDifference = Int(Date().timeIntervalSince(startTime))
        duration_secLabel.text = timerprefix + String(timeDifference)
   
    }
    
    
    //MARK: setActiveTestfield
    // this is an inhouse apple function that gets called to set the activeField which gets defined in keyboardAwareVC so that we can move the scroll view up when the keyboard gets activateda
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        activeField = nil
    }
}
