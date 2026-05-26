//
//  saveFoodsView.swift
//  Workout
//
//  Created by Peter Xie on 17/5/2026.
//


import UIKit

struct SavedFoodViewData {
    let savedFoodRef: UUID
    let image: UIImage
    let name: String
    let amountText: String
}

final class SavedFoodsView: UIView {

    // MARK: - UI

    private let titleLabel = UILabel()
    private let viewAllButton = UIButton(type: .system)

    private let scrollView = UIScrollView()
    private let foodsStack = UIStackView()

    private var savedFoods: [SavedFoodViewData] = []

    var onFoodTapped: ((SavedFoodViewData) -> Void)?
    var onViewAllTapped: (() -> Void)?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
        style()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
        style()
    }

    // MARK: - Public API

    func configure(savedFoods: [SavedFoodViewData]) {
        self.savedFoods = savedFoods

        foodsStack.arrangedSubviews.forEach {
            foodsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for food in savedFoods {
            let card = SavedFoodCardView()
            card.configure(food: food)

            card.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                card.widthAnchor.constraint(equalToConstant: 104),
                card.heightAnchor.constraint(equalToConstant: 104)
            ])

            let tap = UITapGestureRecognizer(target: self, action: #selector(foodCardTapped(_:)))
            card.addGestureRecognizer(tap)
            card.isUserInteractionEnabled = true
            card.foodRef = food.savedFoodRef

            foodsStack.addArrangedSubview(card)
        }
    }

    // MARK: - Build

    private func build() {
        addSubview(titleLabel)
        addSubview(viewAllButton)
        addSubview(scrollView)

        scrollView.addSubview(foodsStack)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        viewAllButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        foodsStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),

            viewAllButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            viewAllButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),

            foodsStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            foodsStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            foodsStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            foodsStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            foodsStack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        viewAllButton.addTarget(self, action: #selector(viewAllTapped), for: .touchUpInside)
    }

    private func style() {
        backgroundColor = UIColor.systemGray6

        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        clipsToBounds = true

        titleLabel.text = "Saved Foods"
        titleLabel.textColor = .label
        titleLabel.font = .systemFont(ofSize: 19, weight: .bold)

        viewAllButton.setTitle("View All", for: .normal)
        viewAllButton.setTitleColor(.systemBlue, for: .normal)
        viewAllButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)

        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.alwaysBounceVertical = false

        foodsStack.axis = .horizontal
        foodsStack.spacing = 12
        foodsStack.alignment = .fill
        foodsStack.distribution = .fill
    }

    // MARK: - Actions

    @objc private func viewAllTapped() {
        onViewAllTapped?()
    }

    @objc private func foodCardTapped(_ sender: UITapGestureRecognizer) {
        guard
            let card = sender.view as? SavedFoodCardView,
            let food = savedFoods.first(where: { $0.savedFoodRef == card.foodRef })
        else { return }

        onFoodTapped?(food)
    }
}

final class SavedFoodCardView: UIView {

    var foodRef: UUID?

    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private let amountLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
        style()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
        style()
    }

    func configure(food: SavedFoodViewData) {
        foodRef = food.savedFoodRef
        imageView.image = food.image
        nameLabel.text = food.name
        amountLabel.text = food.amountText
    }

    private func build() {
        addSubview(imageView)
        addSubview(nameLabel)
        addSubview(amountLabel)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 52),
            imageView.heightAnchor.constraint(equalToConstant: 38),

            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),

            amountLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            amountLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            amountLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            amountLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8)
        ])
    }

    private func style() {
        backgroundColor = UIColor.white.withAlphaComponent(0.045)

        layer.cornerRadius = 10
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = false

        nameLabel.textColor = .label
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 1
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.75

        amountLabel.textColor = .secondaryLabel.withAlphaComponent(0.9)
        amountLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        amountLabel.textAlignment = .center
        amountLabel.numberOfLines = 1
    }
}
