//
//  WorkoutAiViewPreview.swift
//  Workout
//
//  Created by Peter Xie on 28/4/2026.
//

import SwiftUI


struct WorkoutSummaryPreview: PreviewProvider {
    static var previews: some View {
        UIViewControllerPreview {
            WorkoutAIViewController()
        }
    }
}

struct UIViewControllerPreview: UIViewControllerRepresentable {
    let builder: () -> UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        builder()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
