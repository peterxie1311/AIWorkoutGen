import UIKit
import SwiftUI
import Charts

struct PieChartData: Identifiable {
    let id = UUID()
    let category: String
    let value: Double
}

extension PieChartData: Equatable {
    static func == (lhs: PieChartData, rhs: PieChartData) -> Bool {
        return lhs.category == rhs.category && lhs.value == rhs.value
    }
}

class Piechartviewcontroller: UIViewController {

    var pieData: [PieChartData] = [
        PieChartData(category: "Category A", value: 40),
        PieChartData(category: "Category B", value: 60)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Create the pie chart view
        let chartView = Chart(pieData) { data in
            SectorMark(
                angle: .value("Value", data.value),
                innerRadius: .ratio(0.5),
                outerRadius: .ratio(1.0)
            )
            .foregroundStyle(by: .value("Category", data.category))
        }
        .frame(width: 300, height: 300)

        // Embed the chart in a UIHostingController
        let hostingController = UIHostingController(rootView: chartView)

        // Add the hosting controller as a child view controller
        addChild(hostingController)
        hostingController.view.frame = CGRect(x: 50, y: 100, width: 300, height: 300)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // Trigger animation on view appearance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.animateChartData()
        }
    }
    
    // Function to trigger animation
    private func animateChartData() {
        // Animation of the pie chart using UIView
        UIView.animate(withDuration: 2.0, delay: 0, options: [.curveEaseInOut], animations: {
            self.pieData = [
                PieChartData(category: "Category A", value: 30), // New data
                PieChartData(category: "Category B", value: 70)  // New data
            ]
            // Force reloading the view to apply the updated data
            self.view.setNeedsLayout()
        })
    }
}
