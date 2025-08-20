import UIKit
import AVKit

class RepViewController: UIViewController ,UITextFieldDelegate{
    override var prefersHomeIndicatorAutoHidden: Bool {
           return true
       }
    
    // Properties
    var completed: Bool
    var duration_sec: Float
    var finishTime: Date
    var rep_qty: Int64
    var repid:UUID
    var startTime:Date
    var weight: Int64
    var WorkoutName:String
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
        self.repButtonString = self.phase_1
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        addDoneButtonToKeyboard()
//        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: NSNotification.Name("workout"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: NSNotification.Name("SetRep"), object: nil)
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
    
    private func setupUI() {
        view.backgroundColor   = .systemBackground
        nameLabel.text         = WorkoutName
        rep_qtyLabel.text      = "Rep Qty: " + String(rep_qty)
        startTimeLabel.text    = "Start Date: " + parseDateToString(startTime)
        duration_secLabel.text = timerprefix + "0"
        weight_label.text      = weightprefix + String(weight)
        status.text            = statusPrefix + String(completed)
        
        
        if let personalBest:Setrep = getPersonalBest(workout: WorkoutName){
            personalBestLabelReps.text = "Personal Best (Reps): " + String(personalBest.rep_qty)
            personalBestLabelWeight.text = "Personal Best (Wgt): " + String(personalBest.weight)
            
        }
        
        
        // Setup UI Components
        nameLabel.font = UIFont.boldSystemFont(ofSize: 24)
        rep_qtyLabel.font = UIFont.systemFont(ofSize: 18)
        startTimeLabel.font = UIFont.systemFont(ofSize: 18)
        duration_secLabel.font = UIFont.systemFont(ofSize: 18)
        weight_label.font = UIFont.systemFont(ofSize: 18)
        
        RepButton.setTitle(repButtonString, for: .normal)
        RepButton.addTarget(self, action: #selector(startworkout), for: .touchUpInside)
        
        changeRepWeightButton.addTarget(self, action:#selector(executechangerepweight), for: .touchUpInside)
        deleteRepButton.addTarget(self, action: #selector(deleteRep), for: .touchUpInside)
        
        RepButton.isUserInteractionEnabled       = true
        deleteRepButton.isUserInteractionEnabled = true
        changeRepWeight.isUserInteractionEnabled = true
        
        changeWorkoutName.borderStyle = .roundedRect
        changeWorkoutName.placeholder = "Change Workout Name"
        changeWorkoutName.keyboardType = .alphabet
        changeWorkoutName.delegate = self
        changeWorkoutName.translatesAutoresizingMaskIntoConstraints = false
        changeWorkoutName.isUserInteractionEnabled = true
        
        changeRepWeight.borderStyle = .roundedRect
        changeRepWeight.placeholder = "Change rep weight"
        changeRepWeight.keyboardType = .numberPad
        changeRepWeight.delegate = self
        changeRepWeight.translatesAutoresizingMaskIntoConstraints = false
        
        changeSetQTY.isUserInteractionEnabled = true
        changeSetQTY.borderStyle = .roundedRect
        changeSetQTY.placeholder = "Change Set QTY"
        changeSetQTY.keyboardType = .numberPad
        changeSetQTY.delegate = self
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            swipeDown.direction = .down
            view.addGestureRecognizer(swipeDown)
        

        // Add Subviews and Set Constraints
        let stackView = UIStackView(arrangedSubviews: [nameLabel, rep_qtyLabel,status, weight_label,startTimeLabel, duration_secLabel,personalBestLabelWeight,personalBestLabelReps,RepButton,deleteRepButton,changeWorkoutName,changeRepWeight,changeSetQTY,changeRepWeightButton])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
       
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
    }
    
    
    private func addDoneButtonToKeyboard() {
            // Create the toolbar
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
            let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            
            // Add the "Done" button and spacer to the toolbar
            toolbar.items = [spacer, doneButton]
            
            // Assign the toolbar to the keyboard's accessory view
            changeRepWeight.inputAccessoryView = toolbar
            changeSetQTY.inputAccessoryView = toolbar
            changeWorkoutName.inputAccessoryView = toolbar
        }
    @objc func dismissKeyboard() {
        print("Swipe gesture detected")
        UIView.animate(withDuration: 0.1) {
               self.view.endEditing(true)
           }
    }
    

    @objc private func executechangerepweight() {
        

        var newweight = weight
        var newsetqty = rep_qty
        var newWorkoutName = WorkoutName

        if let newWeightText = changeRepWeight.text, !newWeightText.isEmpty {
            guard let validWeight = Int64(newWeightText), validWeight > 0 else {
                showAlert(title: "Invalid Input", message: "Please enter a valid weight.")
                return
            }
            newweight = validWeight
        }
        if let newSetQTYText = changeSetQTY.text,!newSetQTYText.isEmpty {
           guard let newSetQTY = Int64(newSetQTYText),
                newSetQTY > 0 else {
                    showAlert(title: "Invalid Input", message: "Please enter a valid Set QTY.")
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

        // Optionally update the UI or show feedback
        changeRepWeight.text = ""
        changeSetQTY.text    = ""
        showAlert(title: "Success", message: "Updated successfully!")
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
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
}
