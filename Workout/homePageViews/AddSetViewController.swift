import UIKit

class AddSetViewController: UIViewController, UITextFieldDelegate {

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private let AddSetLabel = UILabel()

    private var addSetButton = workoutDesigns.createStyledButton(
        title: "Add Set!",
        width: 100,
        height: 50
    )

    private let workoutnameField = UITextField()
    private let setqtyField = UITextField()
    private let repqtyField = UITextField()
    private let weightField = UITextField()

//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        setupUI()
        setupData()
    }

    @objc private func addSet() {
        // add your add set logic here
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    private func setupUI() {
        AddSetLabel.font = UIFont.systemFont(ofSize: 20)
        AddSetLabel.textAlignment = .center

        addSetButton.addTarget(self, action: #selector(addSet), for: .touchUpInside)

        let swipeDown = UISwipeGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)

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

        let textFieldsView = workoutDesigns.createRoundedSquareViewWithTextFields(
            textFields: workoutTextFields
        )

        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .fill
        stackView.distribution = .fill

        stackView.addArrangedSubview(AddSetLabel)
        stackView.addArrangedSubview(textFieldsView)
        stackView.addArrangedSubview(addSetButton)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    private func setupData() {
        AddSetLabel.text = "Add a Workout Set!"
    }
}
