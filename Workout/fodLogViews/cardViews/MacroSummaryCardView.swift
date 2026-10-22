import UIKit

/// A daily energy overview with independently labelled nutrient goals.
final class MacroSummaryCardView: UIView {
    private let caloriesValue = UILabel()
    private let caloriesDetail = UILabel()
    private let energyProgress = UIProgressView(progressViewStyle: .bar)
    private let proteinValue = UILabel()
    private let carbsValue = UILabel()
    private let proteinProgress = UIProgressView(progressViewStyle: .bar)
    private let carbsProgress = UIProgressView(progressViewStyle: .bar)

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func build() {
        WorkoutTheme.card(self)
        let eyebrow = UILabel()
        eyebrow.text = "DAILY NUTRITION"
        eyebrow.font = .preferredFont(forTextStyle: .caption1)
        eyebrow.textColor = WorkoutTheme.accent
        eyebrow.adjustsFontForContentSizeCategory = true
        eyebrow.accessibilityTraits = .header

        caloriesValue.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(
            for: .monospacedDigitSystemFont(ofSize: 38, weight: .bold))
        caloriesValue.adjustsFontForContentSizeCategory = true
        caloriesValue.numberOfLines = 0
        caloriesDetail.font = .preferredFont(forTextStyle: .subheadline)
        caloriesDetail.adjustsFontForContentSizeCategory = true
        caloriesDetail.textColor = .secondaryLabel
        caloriesDetail.numberOfLines = 0

        let energy = UIStackView(arrangedSubviews: [caloriesValue, caloriesDetail])
        energy.axis = .vertical
        energy.spacing = 4
        energy.isAccessibilityElement = true
        energy.accessibilityLabel = "Calories"

        let macros = UIStackView(arrangedSubviews: [
            nutrient(title: "Protein", value: proteinValue, progress: proteinProgress, color: WorkoutTheme.accent),
            nutrient(title: "Carbs", value: carbsValue, progress: carbsProgress, color: .systemOrange)
        ])
        macros.axis = .vertical
        macros.spacing = 18

        let divider = UIView()
        divider.backgroundColor = .separator
        divider.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true

        let stack = UIStackView(arrangedSubviews: [eyebrow, energy, energyProgress, divider, macros])
        stack.axis = .vertical
        stack.spacing = 18
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 22),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -22)
        ])
        [energyProgress, proteinProgress, carbsProgress].forEach {
            $0.trackTintColor = .tertiarySystemFill
            $0.layer.cornerRadius = 3
            $0.clipsToBounds = true
            $0.heightAnchor.constraint(equalToConstant: 6).isActive = true
        }
        energyProgress.progressTintColor = WorkoutTheme.accent
    }

    private func nutrient(title: String, value: UILabel, progress: UIProgressView, color: UIColor) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        value.font = .preferredFont(forTextStyle: .headline)
        value.adjustsFontForContentSizeCategory = true
        value.textColor = .secondaryLabel
        value.numberOfLines = 0
        let heading = UIStackView(arrangedSubviews: [label, value])
        heading.axis = .vertical
        heading.spacing = 4
        progress.progressTintColor = color
        let stack = UIStackView(arrangedSubviews: [heading, progress])
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }

    func configure(calories: Double, caloriesGoal: Double,
                   proteinCurrent: Double, proteinGoal: Double,
                   carbsCurrent: Double, carbsGoal: Double) {
        let format = HelperFunctions.formatNumber
        caloriesValue.text = "\(format(calories)) kcal"
        if caloriesGoal > 0 {
            let difference = caloriesGoal - calories
            caloriesDetail.text = "\(format(abs(difference))) kcal \(difference >= 0 ? "remaining" : "over goal") · Goal \(format(caloriesGoal))"
        } else {
            caloriesDetail.text = "Set a calorie goal to track your day"
        }
        caloriesValue.superview?.accessibilityValue = "\(caloriesValue.text ?? ""), \(caloriesDetail.text ?? "")"
        proteinValue.text = "\(format(proteinCurrent)) / \(format(proteinGoal)) g"
        carbsValue.text = "\(format(carbsCurrent)) / \(format(carbsGoal)) g"
        let animated = window != nil && !UIAccessibility.isReduceMotionEnabled
        energyProgress.setProgress(ratio(calories, caloriesGoal), animated: animated)
        proteinProgress.setProgress(ratio(proteinCurrent, proteinGoal), animated: animated)
        carbsProgress.setProgress(ratio(carbsCurrent, carbsGoal), animated: animated)
        energyProgress.accessibilityLabel = "Calorie goal"
        proteinProgress.accessibilityLabel = "Protein goal"
        carbsProgress.accessibilityLabel = "Carbohydrate goal"
    }

    private func ratio(_ current: Double, _ goal: Double) -> Float {
        guard goal > 0, goal.isFinite, current.isFinite else { return 0 }
        return Float(min(1, max(0, current / goal)))
    }
}
