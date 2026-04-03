//
//  MacroSummaryCardView.swift
//  Workout
//
//  Created by Peter Xie on 26/1/2026.
//


import UIKit

final class MacroSummaryCardView: UIView {

    // MARK: - UI

    private let container = UIView()

    private let caloriesTitle = UILabel()
    private let caloriesValue = UILabel()

    private let proteinTitle = UILabel()
    private let proteinValue = UILabel()

    private let carbsTitle = UILabel()
    private let carbsValue = UILabel()

    private let divider1 = UIView()
    private let divider2 = UIView()

    // “Bars” (use plain UIViews so we can control height + rounded corners easily)
    private let bar1Track = UIView()
    private let bar1Fill  = UIView()

    private let bar2Track = UIView()
    private let bar2Fill  = UIView()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
        style()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public API

    func configure(
        calories: Double, caloriesGoal:Double,
        proteinCurrent: Double, proteinGoal: Double,
        carbsCurrent: Double, carbsGoal: Double
//        bar1Progress: CGFloat,   // 0...1
//        bar2Progress: CGFloat    // 0...1
    ) {
        caloriesValue.attributedText = makeSplitValue(main: "\(calories)", sub: "/\(caloriesGoal)")


        proteinValue.attributedText = makeSplitValue(main: "\(proteinCurrent)",
                                                      sub: "/\(proteinGoal)"
                                                     )
        
        carbsValue.attributedText   = makeSplitValue(main: "\(carbsCurrent)", sub: "/\(carbsGoal)")
        
        let bar1Progress = CGFloat(min(1, max(0, Float(proteinCurrent) / Float(proteinGoal))))
        let bar2Progress = CGFloat(min(1, max(0, Float(calories) / Float(caloriesGoal))))
    
        setProgress(bar1Progress, fill: bar1Fill, in: bar1Track)
        setProgress(bar2Progress, fill: bar2Fill, in: bar2Track)
    }

    // MARK: - Build

    private func build() {
        addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false

        // Top row: 3 columns with dividers
        let col1 = makeColumn(title: caloriesTitle, value: caloriesValue, align: .left)
        let col2 = makeColumn(title: proteinTitle,  value: proteinValue,  align: .center)
        let col3 = makeColumn(title: carbsTitle,    value: carbsValue,    align: .right)

        divider1.translatesAutoresizingMaskIntoConstraints = false
        divider2.translatesAutoresizingMaskIntoConstraints = false

        let topRow = UIStackView(arrangedSubviews: [col1, divider1, col2, divider2, col3])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.distribution = .fill
        topRow.spacing = 12
        topRow.translatesAutoresizingMaskIntoConstraints = false

        // Make dividers fixed width
        NSLayoutConstraint.activate([
            divider1.widthAnchor.constraint(equalToConstant: 1),
            divider2.widthAnchor.constraint(equalToConstant: 1)
        ])

        // Bars stack
        let bars = UIStackView(arrangedSubviews: [makeBar(track: bar1Track, fill: bar1Fill, height: 8),
                                                  makeBar(track: bar2Track, fill: bar2Fill, height: 6)])
        bars.axis = .vertical
        bars.spacing = 10
        bars.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(topRow)
        container.addSubview(bars)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),

            topRow.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            topRow.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            topRow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            bars.topAnchor.constraint(equalTo: topRow.bottomAnchor, constant: 12),
            bars.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            bars.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            bars.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14)
        ])
    }

    private func style() {
        // Card look
        container.backgroundColor = UIColor.systemGray6
        container.layer.cornerRadius = 18
        container.layer.masksToBounds = true

        // Titles
        [caloriesTitle, proteinTitle, carbsTitle].forEach {
            $0.font = .systemFont(ofSize: 14, weight: .semibold)
            $0.textColor = .secondaryLabel
        }
        caloriesTitle.text = "Calories"
        proteinTitle.text = "Protein"
        carbsTitle.text = "Carbs"

        caloriesValue.textColor = .label
        proteinValue.textColor = .label
        carbsValue.textColor = .label

        // Dividers
        [divider1, divider2].forEach {
            $0.backgroundColor = UIColor.systemGray3.withAlphaComponent(0.6)
        }

        // Bar tracks
        [bar1Track, bar2Track].forEach {
            $0.backgroundColor = UIColor.systemGray4.withAlphaComponent(0.6)
            $0.layer.masksToBounds = true
        }

        // Bar fills
        // (Leave default blue for bar1; keep bar2 a lighter gray/secondary tint)
        bar1Fill.backgroundColor = .systemBlue
        bar2Fill.backgroundColor = .systemGreen

        // Rounded corners will be set after layout when we know heights
        layoutIfNeeded()
        roundBar(track: bar1Track, fill: bar1Fill)
        roundBar(track: bar2Track, fill: bar2Fill)
    }

    // MARK: - Helpers

    private func makeColumn(title: UILabel, value: UILabel, align: NSTextAlignment) -> UIStackView {
        title.textAlignment = align

        value.textAlignment = align
        // default font for split value; calories uses its own bigger font
        value.font = .systemFont(ofSize: 26, weight: .bold)

        let v = UIStackView(arrangedSubviews: [title, value])
        v.axis = .vertical
        v.spacing = 4
        v.alignment = align == .left ? .leading : (align == .right ? .trailing : .center)
        return v
    }

    private func makeBar(track: UIView, fill: UIView, height: CGFloat) -> UIView {
        track.translatesAutoresizingMaskIntoConstraints = false
        fill.translatesAutoresizingMaskIntoConstraints = false

        track.addSubview(fill)

        NSLayoutConstraint.activate([
            track.heightAnchor.constraint(equalToConstant: height),

            fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
            fill.topAnchor.constraint(equalTo: track.topAnchor),
            fill.bottomAnchor.constraint(equalTo: track.bottomAnchor),

            // start at 0 width; we’ll update in setProgress(...)
            fill.widthAnchor.constraint(equalToConstant: 0)
        ])

        return track
    }

    private func setProgress(_ progress: CGFloat, fill: UIView, in track: UIView) {
        let clamped = max(0, min(1, progress))
        let width = track.bounds.width * clamped

        // Update the width constraint we created in makeBar(...)
        if let widthConstraint = fill.constraints.first(where: { $0.firstAttribute == .width }) {
            widthConstraint.constant = width
        }
        // Animate if you want:
        UIView.animate(withDuration: 1) {
            self.layoutIfNeeded()
        }
        roundBar(track: track, fill: fill)
    }

    private func roundBar(track: UIView, fill: UIView) {
        track.layer.cornerRadius = track.bounds.height / 2
        fill.layer.cornerRadius = fill.bounds.height / 2
    }

    private func makeSplitValue(main: String,
                                sub: String,
                                mainColour:UIColor = UIColor.label,
                                secondaryColour:UIColor = UIColor.secondaryLabel) -> NSAttributedString {
        let big = UIFont.systemFont(ofSize: 20, weight: .bold)
        let small = UIFont.systemFont(ofSize: 16, weight: .semibold)

        let result = NSMutableAttributedString(
            string: main,
            attributes: [.font: big, .foregroundColor: mainColour]
        )
        result.append(NSAttributedString(
            string: sub,
            attributes: [.font: small, .foregroundColor: secondaryColour]
        ))
        return result
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Keep corners correct on rotation / constraint changes
        container.layer.cornerRadius = 18
        roundBar(track: bar1Track, fill: bar1Fill)
        roundBar(track: bar2Track, fill: bar2Fill)
    }
}
