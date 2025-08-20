import SwiftUI

struct TreeView: View {
    let trees: [workoutTree]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 70) {
                
                ForEach(trees, id: \.workoutName) { tree in
                    singleTree(for: tree)
                }
            }
            .padding()
        }
        .frame(height: 200)
    }
    
    func singleTree(for tree: workoutTree) -> some View {
        VStack {
            ZStack {
                Rectangle()
                    .fill(Color.brown)
                    .frame(width: 30, height: 100)
                    .offset(y: 40)

                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.8))
                        .frame(width: 80, height: 80)
                        .offset(x: -30)

                    Circle()
                        .fill(Color.green.opacity(0.9))
                        .frame(width: 90, height: 90)
                        .offset(y: -20)

                    Circle()
                        .fill(Color.green.opacity(0.8))
                        .frame(width: 80, height: 80)
                        .offset(x: 30)
                }
            }

            Text(tree.workoutName)  // show the name under the tree
                .font(.caption)
                .padding(.top, 4)
            
            Text("\(tree.WorkoutWeight) kg")  // show the name under the tree
                .font(.caption)
                .padding(.top, 4)
            
            Text("\(tree.workoutreps) #Reps")  // show the name under the tree
                .font(.caption)
                .padding(.top, 4)
        }
        .frame(height: 180)
    }
}

struct TreeView_Previews: PreviewProvider {
    static var previews: some View {
        TreeView(trees: [
            workoutTree(workoutName: "Bench Press", WorkoutWeight: 80, workoutreps: 10),
            workoutTree(workoutName: "Squat", WorkoutWeight: 100, workoutreps: 8),
            workoutTree(workoutName: "Deadlift", WorkoutWeight: 120, workoutreps: 5)
        ])
            .previewLayout(.sizeThatFits)
    }
}

struct workoutTree {
    var workoutName:String;
    var WorkoutWeight:Int;
    var workoutreps:Int
}
