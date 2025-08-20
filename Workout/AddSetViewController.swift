import UIKit

class AddSetViewController: UIViewController, UITextFieldDelegate  {
    override var prefersHomeIndicatorAutoHidden: Bool {
           return true
       }
    let WorkoutSession:WorkoutSession
    let setreps:[Setrep]

    private let AddSetLabel      = UILabel()
    private var addSetButton     = workoutDesigns.createStyledButton(title: "Add Set!",
                                                                     width: 100,
                                                                     height: 50)
    private let workoutnameField = UITextField()
    private let setqtyField      = UITextField()
    private let repqtyField      = UITextField()
    private let weightField      = UITextField()
   
    init(workout:WorkoutSession) {
        self.WorkoutSession = workout
        self.setreps        = (workout.setrep?.allObjects as? [Setrep]) ?? []
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        setupUI()
        setupData()
    }
    
    @objc private func addSet(){
        var tmpWorkoutName    = ""
        var tmpRepQty         = 0
        var tmpSetQty         = 1
        var tmpRepWeight      = 0
        var retCode           = true
        let tmpWorkoutSession = self.WorkoutSession
        var tmpSetRepArr      = self.setreps
        
        if let workoutNameText = workoutnameField.text, !workoutNameText.isEmpty {
            tmpWorkoutName = workoutNameText
        }
        else {
            HelperFunctions.showAlert(on: self,title: "Invalid Input", message: "Please enter a valid weight.")
            retCode = false
        }
        
        if let newSetQTYText = setqtyField.text,!newSetQTYText.isEmpty {
           guard let newSetQTY = Int(newSetQTYText),
                newSetQTY > 0 else {
               HelperFunctions.showAlert(on: self,title: "Invalid Input", message: "Please enter a valid Set QTY.")
               retCode = false
                    return
                }
            tmpSetQty = newSetQTY
        }
 
        if let newRetQTYText = repqtyField.text,!newRetQTYText.isEmpty {
           guard let newRepQTY = Int(newRetQTYText),
                 newRepQTY > 0 else {
               HelperFunctions.showAlert(on: self,title: "Invalid QTY", message: "Please enter a valid Ret QTY.")
               retCode = false
                    return
                }
            tmpRepQty = newRepQTY
        }
        
        if let newRepWeightText = weightField.text,!newRepWeightText.isEmpty {
           guard let newRepWeight = Int(newRepWeightText),
                 newRepWeight > 0 else {
               HelperFunctions.showAlert(on: self,title: "Invalid Weight", message: "Please enter a valid Ret QTY.")
               retCode = false
                    return
                }
            tmpRepWeight = newRepWeight
        }
        
        if retCode == true {
            if WorkoutSessionManager.shared.checkIsOpenWorkout(workout: WorkoutSession) {
                for _ in 1...tmpSetQty{
                    SetrepManager.shared.addSetrep(qty: Int(tmpRepQty), startTime: Date(), finishTime:Date(), workoutName: tmpWorkoutName, weight: Int64(tmpRepWeight))
                }
            }
            else {
                
        
                
                for _ in 1...tmpSetQty {
                    let tmpSetRep =  SetrepManager.shared.initSetRep(qty: Int(tmpRepQty), startTime: Date(), finishTime: Date(), workoutName: tmpWorkoutName, weight: Int64(tmpRepWeight))
                        tmpSetRepArr.append(tmpSetRep)
                    
                }
                
                tmpWorkoutSession.setrep = NSSet(array: tmpSetRepArr)
                WorkoutSessionManager.shared.updateWorkoutSession(prevWorkout:WorkoutSession,updatedSession:tmpWorkoutSession)
            }
            
        }
    }
    
    @objc func dismissKeyboard() {
        print("Swipe gesture detected")
        UIView.animate(withDuration: 0.1) {
               self.view.endEditing(true)
           }
    }
    
    private func setupUI() {

        AddSetLabel.font  = UIFont.systemFont(ofSize: 20)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            swipeDown.direction = .down
            view.addGestureRecognizer(swipeDown)
        
        //addSetButton.setTitle("Delete Workout", for: .normal)
        addSetButton.addTarget(self, action: #selector(addSet), for: .touchUpInside)
        
        
        workoutnameField.borderStyle  = .roundedRect
        workoutnameField.placeholder  = "Workout Name"
        workoutnameField.keyboardType = .alphabet
        workoutnameField.delegate     = self
        workoutnameField.translatesAutoresizingMaskIntoConstraints = false
        workoutnameField.isUserInteractionEnabled                  = true
        
        setqtyField.borderStyle  = .roundedRect
        setqtyField.placeholder  = "Set QTY"
        setqtyField.keyboardType = .numberPad
        setqtyField.delegate     = self
        setqtyField.translatesAutoresizingMaskIntoConstraints = false
        
        repqtyField.borderStyle  = .roundedRect
        repqtyField.placeholder  = "Rep QTY"
        repqtyField.keyboardType = .numberPad
        repqtyField.delegate     = self
        repqtyField.translatesAutoresizingMaskIntoConstraints = false
        
        weightField.borderStyle  = .roundedRect
        weightField.placeholder  = "Weight (kg)"
        weightField.keyboardType = .numberPad
        weightField.delegate     = self
        weightField.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [AddSetLabel,workoutnameField,setqtyField,repqtyField,weightField,addSetButton])
        stackView.axis    = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
        ])
    }
    
    private func setupData() {
        AddSetLabel.text = "Add a Workout Set!"
    }
    
}
